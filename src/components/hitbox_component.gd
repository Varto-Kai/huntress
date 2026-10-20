class_name HitboxComponent
extends Area2D
## Componente Area2D que aplica AttackData aos HurtboxComponent atingidos durante a janela ativa,
## garantindo exatamente 1 acerto único por alvo por ativação de golpe (SPEC-002: RF-002, EC-001, EC-002, SC-001).

signal hit_landed(hurtbox: HurtboxComponent, resolution: Dictionary)

@export var collision_shape: CollisionShape2D
@export var slash_visual: Polygon2D

var _active_attack_data: AttackData = null
var _is_active: bool = false
var _hit_hurtboxes: Array[HurtboxComponent] = []


func _ready() -> void:
	monitoring = true
	monitorable = false
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	deactivate()


func _physics_process(_delta: float) -> void:
	if _is_active:
		_scan_overlapping_hurtboxes()


func is_active() -> bool:
	return _is_active


## Configura o tamanho e posição do colisor e do polígono Greybox conforme o AttackStepData (RF-009, RF-010).
func configure_geometry(size: Vector2, forward_offset: float, color: Color) -> void:
	if collision_shape != null and collision_shape.shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
		rect_shape.size = size
		collision_shape.position = Vector2(forward_offset, 0.0)

	if slash_visual != null:
		var half_x: float = size.x * 0.5
		var half_y: float = size.y * 0.5
		slash_visual.polygon = PackedVector2Array([
			Vector2(forward_offset - half_x, -half_y),
			Vector2(forward_offset + half_x, -half_y * 0.75),
			Vector2(forward_offset + half_x + 4.0, 0.0),
			Vector2(forward_offset + half_x, half_y * 0.75),
			Vector2(forward_offset - half_x, half_y),
		])
		slash_visual.color = color


## Ativa a hitbox para um golpe único, limpando a lista de alvos já atingidos (EC-001).
func activate(attack_data: AttackData) -> void:
	_active_attack_data = attack_data
	_hit_hurtboxes.clear()
	_is_active = true
	if slash_visual != null:
		slash_visual.visible = true
	_scan_overlapping_hurtboxes()


## Desativa imediatamente a hitbox e esconde o visual Greybox (EC-003, EC-004, DT-04).
func deactivate() -> void:
	_is_active = false
	_active_attack_data = null
	_hit_hurtboxes.clear()
	if slash_visual != null:
		slash_visual.visible = false


## Processa a tentativa de atingir um HurtboxComponent específico (usado em física e em testes).
func try_hit_hurtbox(hurtbox: HurtboxComponent) -> bool:
	if not _is_active or hurtbox == null or _active_attack_data == null:
		return false
	if _hit_hurtboxes.has(hurtbox):
		return false
	if hurtbox.team == _active_attack_data.team:
		return false

	# Registra o alvo na lista de exclusão deste golpe para impedir multi-hit por frame (SC-001)
	_hit_hurtboxes.append(hurtbox)
	var resolution: Dictionary = hurtbox.receive_attack(_active_attack_data)
	if bool(resolution.get("applied", false)):
		hit_landed.emit(hurtbox, resolution)
		return true
	return false


func _scan_overlapping_hurtboxes() -> void:
	if not is_inside_tree():
		return
	for area: Area2D in get_overlapping_areas():
		if area is HurtboxComponent:
			try_hit_hurtbox(area as HurtboxComponent)


func _on_area_entered(area: Area2D) -> void:
	if _is_active and area is HurtboxComponent:
		try_hit_hurtbox(area as HurtboxComponent)
