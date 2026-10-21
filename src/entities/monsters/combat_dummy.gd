class_name CombatDummy
extends CharacterBody2D
## Alvo tático Greybox reutilizável para validação de combate, Fraquezas/Resistências,
## quebra de postura (Stagger / Break), knockback (SPEC-002) e sincronização de
## telemetria investigativa via Grimório (SPEC-003: Q4 / RF-005).

signal dummy_hit_logged(dummy_name: String, resolution: Dictionary)

@export var monster_id: StringName = &""
@export var dummy_title: String = "Dummy Tático"
@export var hide_telemetry_until_researched: bool = false
@export var defense_profile: DefenseProfileData
@export var movement_config: PlayerMovementConfig
@export var base_color: Color = Color("#8E44AD")
@export var staggered_color: Color = Color("#00FFFF")
@export var hit_flash_color: Color = Color("#FFFFFF")

@onready var body_polygon: Polygon2D = $DummyVisual as Polygon2D
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent as HurtboxComponent
@onready var health_component: HealthComponent = $HealthComponent as HealthComponent
@onready var stagger_component: StaggerComponent = $StaggerComponent as StaggerComponent
@onready var movement_component: MovementComponent = $MovementComponent as MovementComponent
@onready var hp_bar_fill: ColorRect = $OverheadUI/HpBarBg/HpBarFill as ColorRect
@onready var stagger_bar_fill: ColorRect = $OverheadUI/StaggerBarBg/StaggerBarFill as ColorRect
@onready var status_label: Label = $OverheadUI/StatusLabel as Label

var _flash_timer: float = 0.0
var _respawn_timer: float = 0.0
var _spawn_position: Vector2 = Vector2.ZERO
var _telemetry_summary: String = ""


func _ready() -> void:
	_spawn_position = global_position
	if movement_config == null:
		movement_config = load("res://src/data/default_player_movement.tres") as PlayerMovementConfig
	if movement_config != null:
		movement_config = movement_config.duplicate() as PlayerMovementConfig
		movement_config.friction = 1400.0
	movement_component.setup(self, movement_config)

	if defense_profile != null:
		defense_profile = defense_profile.duplicate() as DefenseProfileData
		defense_profile.sanitize()

	stagger_component.defense_profile = defense_profile
	hurtbox_component.team = CombatTypes.Team.ENEMY
	hurtbox_component.health_component = health_component
	hurtbox_component.stagger_component = stagger_component
	hurtbox_component.defense_profile = defense_profile

	health_component.health_changed.connect(_on_health_changed)
	health_component.health_depleted.connect(_on_health_depleted)
	stagger_component.stagger_changed.connect(_on_stagger_changed)
	stagger_component.stagger_started.connect(_on_stagger_started)
	stagger_component.stagger_ended.connect(_on_stagger_ended)
	hurtbox_component.hit_received.connect(_on_hit_received)

	if hide_telemetry_until_researched:
		_telemetry_summary = "Fraqueza: ??? | Óleo: ???"
	_update_visual_color()
	_on_health_changed(health_component.current_health, health_component.max_health)
	_on_stagger_changed(stagger_component.current_stagger, stagger_component.get_max_stagger())
	_refresh_overhead_label()


func _physics_process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer = maxf(0.0, _flash_timer - delta)
		if _flash_timer <= 0.0:
			_update_visual_color()

	if _respawn_timer > 0.0:
		_respawn_timer = maxf(0.0, _respawn_timer - delta)
		if _respawn_timer <= 0.0:
			global_position = _spawn_position
			health_component.reset_health()
			stagger_component.reset_stagger()
			_refresh_overhead_label()
			_update_visual_color()

	movement_component.apply_friction(delta)


## Atualiza a telemetria acima do alvo com base no estado atual do Grimório (SPEC-003: Q4 / Q5).
func apply_grimoire_state(state: Dictionary) -> void:
	var style_sec: Dictionary = state.get("style_section", {}) as Dictionary
	var oil_sec: Dictionary = state.get("oil_section", {}) as Dictionary
	var style_txt: String = _short_style_label(style_sec)
	var oil_txt: String = _short_oil_label(oil_sec)
	_telemetry_summary = "%s + %s" % [style_txt, oil_txt]
	_refresh_overhead_label()


func _short_style_label(sec: Dictionary) -> String:
	if not bool(sec.get("unlocked", false)):
		return "Estilo: ???"
	var st: int = int(sec.get("style_weakness", 0))
	return "Corte Rápido" if st == CombatTypes.StyleType.FAST_STEEL else "Impacto Pesado"


func _short_oil_label(sec: Dictionary) -> String:
	if not bool(sec.get("unlocked", false)):
		return "Óleo: ???"
	var el: int = int(sec.get("element_weakness", 0))
	if el == CombatTypes.ElementOil.IGNIS_OIL:
		return "Ignis (Fogo)"
	if el == CombatTypes.ElementOil.VITRIOL_ACID:
		return "Vitríolo (Ácido)"
	return "Sem Óleo"


func _refresh_overhead_label() -> void:
	if status_label == null:
		return
	if _telemetry_summary.is_empty():
		status_label.text = dummy_title
	else:
		status_label.text = "%s\n[%s]" % [dummy_title, _telemetry_summary]


func _on_hit_received(_attack_data: AttackData, resolution: Dictionary) -> void:
	var kb: Vector2 = resolution.get("knockback_vector", Vector2.ZERO) as Vector2
	if kb.length_squared() > 0.0001:
		movement_component.apply_direct_velocity(kb.normalized(), kb.length() * 0.55)

	_flash_timer = 0.08
	if body_polygon != null:
		body_polygon.color = hit_flash_color

	var dmg: float = float(resolution.get("final_damage", 0.0))
	var matchup: CombatTypes.MatchupResult = int(resolution.get("matchup", 1)) as CombatTypes.MatchupResult
	var tag: String = "NEUTRO"
	if matchup == CombatTypes.MatchupResult.WEAKNESS:
		tag = "FRAQUEZA!"
	elif matchup == CombatTypes.MatchupResult.RESISTED:
		tag = "RESISTIDO"

	if status_label != null:
		var break_str: String = " [BREAK!]" if stagger_component.is_staggered() else ""
		status_label.text = "%s\n-%.1f HP (%s)%s" % [dummy_title, dmg, tag, break_str]

	dummy_hit_logged.emit(dummy_title, resolution)


func _on_health_changed(current: float, maximum: float) -> void:
	if hp_bar_fill != null and maximum > 0.0:
		hp_bar_fill.size.x = 48.0 * clampf(current / maximum, 0.0, 1.0)


func _on_stagger_changed(current: float, maximum: float) -> void:
	if stagger_bar_fill != null and maximum > 0.0:
		stagger_bar_fill.size.x = 48.0 * clampf(current / maximum, 0.0, 1.0)


func _on_stagger_started(_duration: float) -> void:
	_update_visual_color()


func _on_stagger_ended() -> void:
	_refresh_overhead_label()
	_update_visual_color()


func _on_health_depleted() -> void:
	_respawn_timer = 1.2
	if status_label != null:
		status_label.text = "%s\n[DERROTADO - Resetando...]" % dummy_title


func _update_visual_color() -> void:
	if body_polygon == null:
		return
	if stagger_component != null and stagger_component.is_staggered():
		body_polygon.color = staggered_color
	else:
		body_polygon.color = base_color
