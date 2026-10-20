class_name PlayerGreyboxVisual
extends Node2D
## Representação visual Greybox da Caçadora utilizando formas geométricas puras (Polygon2D)
## e cores semânticas para locomoção, esquiva, fases de ataque, reação a dano e blink de i-frames (SPEC-001 & SPEC-002).

@export_group("Semantic Greybox Colors")
@export var idle_color: Color = Color("#2ECC71")
@export var move_color: Color = Color("#58D68D")
@export var dodge_iframes_color: Color = Color("#00D2FF")
@export var dodge_recovery_color: Color = Color("#F39C12")
@export var attack_windup_color: Color = Color("#F1C40F")
@export var attack_active_color: Color = Color("#E74C3C")
@export var attack_recovery_color: Color = Color("#E67E22")
@export var hurt_color: Color = Color("#FF0055")
@export var facing_indicator_color: Color = Color("#FFFFFF")

@export_group("Polygon References")
@export var body_polygon: Polygon2D
@export var facing_indicator: Polygon2D

var _current_state_name: StringName = &"IdleState"
var _attack_phase_name: StringName = &"WINDUP"
var _is_dodge_invulnerable: bool = false
var _is_post_hit_invulnerable: bool = false
var _blink_accumulator: float = 0.0


func _ready() -> void:
	_ensure_polygons()
	_refresh_body_color()


func _process(delta: float) -> void:
	if body_polygon == null:
		return
	if _is_post_hit_invulnerable and not String(_current_state_name).to_lower().contains("hurt"):
		_blink_accumulator += delta * 24.0
		body_polygon.modulate.a = 0.40 if int(_blink_accumulator) % 2 == 0 else 1.0
	else:
		body_polygon.modulate.a = 1.0


func bind_components(
	state_machine: StateMachine,
	movement_component: MovementComponent,
	dodge_state: PlayerDodgeState,
	attack_state: PlayerAttackState = null,
	health_component: HealthComponent = null
) -> void:
	_ensure_polygons()

	if state_machine != null:
		if not state_machine.state_changed.is_connected(_on_state_changed):
			state_machine.state_changed.connect(_on_state_changed)
		_current_state_name = state_machine.get_current_state_name()

	if movement_component != null:
		if not movement_component.facing_direction_changed.is_connected(_on_facing_direction_changed):
			movement_component.facing_direction_changed.connect(_on_facing_direction_changed)
		_on_facing_direction_changed(movement_component.facing_direction)

	if dodge_state != null:
		if not dodge_state.invulnerability_started.is_connected(_on_dodge_invulnerability_started):
			dodge_state.invulnerability_started.connect(_on_dodge_invulnerability_started)
		if not dodge_state.invulnerability_ended.is_connected(_on_dodge_invulnerability_ended):
			dodge_state.invulnerability_ended.connect(_on_dodge_invulnerability_ended)

	if attack_state != null:
		if not attack_state.attack_phase_changed.is_connected(_on_attack_phase_changed):
			attack_state.attack_phase_changed.connect(_on_attack_phase_changed)

	if health_component != null:
		if not health_component.invulnerability_changed.is_connected(_on_post_hit_invulnerability_changed):
			health_component.invulnerability_changed.connect(_on_post_hit_invulnerability_changed)

	_refresh_body_color()


func _ensure_polygons() -> void:
	if body_polygon == null:
		body_polygon = get_node_or_null("BodyPolygon") as Polygon2D
	if facing_indicator == null:
		facing_indicator = get_node_or_null("FacingIndicator") as Polygon2D
	if facing_indicator != null:
		facing_indicator.color = facing_indicator_color


func _on_state_changed(_previous_state_name: StringName, new_state_name: StringName) -> void:
	_current_state_name = new_state_name
	_refresh_body_color()


func _on_dodge_invulnerability_started() -> void:
	_is_dodge_invulnerable = true
	_refresh_body_color()


func _on_dodge_invulnerability_ended() -> void:
	_is_dodge_invulnerable = false
	_refresh_body_color()


func _on_attack_phase_changed(phase_name: StringName) -> void:
	_attack_phase_name = phase_name
	_refresh_body_color()


func _on_post_hit_invulnerability_changed(is_invulnerable: bool) -> void:
	_is_post_hit_invulnerable = is_invulnerable
	_blink_accumulator = 0.0
	_refresh_body_color()


func _on_facing_direction_changed(new_direction: Vector2) -> void:
	if facing_indicator != null and new_direction.length_squared() > 0.0001:
		facing_indicator.rotation = new_direction.angle()


func _refresh_body_color() -> void:
	if body_polygon == null:
		return

	var state_lower: String = String(_current_state_name).to_lower()
	if state_lower.contains("hurt"):
		body_polygon.color = hurt_color
	elif state_lower.contains("attack"):
		match _attack_phase_name:
			&"WINDUP":
				body_polygon.color = attack_windup_color
			&"ACTIVE":
				body_polygon.color = attack_active_color
			&"RECOVERY":
				body_polygon.color = attack_recovery_color
			_:
				body_polygon.color = attack_active_color
	elif state_lower.contains("dodge"):
		body_polygon.color = dodge_iframes_color if _is_dodge_invulnerable else dodge_recovery_color
	elif state_lower.contains("move"):
		body_polygon.color = move_color
	else:
		body_polygon.color = idle_color
