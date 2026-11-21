class_name PlayerAttackState
extends State
## Estado de ataque corpo-a-corpo da Caçadora com suporte a combos por Estilo (3 cortes / 2 impactos),
## sub-fases (WINDUP -> ACTIVE -> RECOVERY), orientação por facing_direction e Dodge Cancel (SPEC-002: RF-005 a RF-007, EC-003, EC-004).

enum Phase {
	WINDUP = 0,
	ACTIVE = 1,
	RECOVERY = 2,
}

signal attack_step_started(step_index: int, total_steps: int, phase_name: StringName)
signal attack_phase_changed(phase_name: StringName)
signal attack_finished()

@export var movement_component: MovementComponent
@export var input_component: PlayerInputComponent
@export var combat_style_component: CombatStyleComponent
@export var hitbox_component: HitboxComponent
@export var weapon_pivot: Node2D

var current_phase: Phase = Phase.WINDUP
var current_step_index: int = 0
var _phase_timer: float = 0.0
var _current_step_data: AttackStepData = null
var _combo_queued: bool = false
var _hitstop_timer: float = 0.0
var _hitstop_triggered_this_swing: bool = false


func _ready() -> void:
	if hitbox_component != null and not hitbox_component.hit_landed.is_connected(_on_hitbox_hit_landed):
		hitbox_component.hit_landed.connect(_on_hitbox_hit_landed)


func can_be_interrupted_by(to_state: State) -> bool:
	if to_state == null:
		return true
	var target_name: String = String(to_state.name).to_lower()
	if target_name == "dodgestate":
		return current_phase == Phase.WINDUP or current_phase == Phase.RECOVERY
	return true


func enter() -> void:
	super.enter()
	if hitbox_component != null and not hitbox_component.hit_landed.is_connected(_on_hitbox_hit_landed):
		hitbox_component.hit_landed.connect(_on_hitbox_hit_landed)
	_start_combo_step(0)


func exit() -> void:
	super.exit()
	_hitstop_timer = 0.0
	_combo_queued = false
	if hitbox_component != null:
		hitbox_component.deactivate()
	attack_finished.emit()


func get_phase_name() -> StringName:
	match current_phase:
		Phase.WINDUP:
			return &"WINDUP"
		Phase.ACTIVE:
			return &"ACTIVE"
		Phase.RECOVERY:
			return &"RECOVERY"
	return &"WINDUP"


func physics_update(delta: float) -> void:
	if _hitstop_timer > 0.0:
		_hitstop_timer = maxf(0.0, _hitstop_timer - delta)
		return

	# Registra intenção de encadear próximo golpe se apertar ataque durante ACTIVE ou RECOVERY (RF-006)
	if input_component != null and input_component.has_buffered_attack():
		if current_phase == Phase.ACTIVE or current_phase == Phase.RECOVERY:
			if _can_advance_combo():
				input_component.consume_attack_request()
				_combo_queued = true

	# RF-007 & EC-004: Dodge Cancel permitido em WINDUP e RECOVERY, bloqueado em ACTIVE
	if current_phase == Phase.WINDUP or current_phase == Phase.RECOVERY:
		if _try_dodge_cancel():
			return

	_phase_timer = maxf(0.0, _phase_timer - delta)
	_apply_phase_movement(delta)

	if _phase_timer <= 0.0:
		_advance_phase()


func _start_combo_step(step_idx: int) -> void:
	current_step_index = step_idx
	_combo_queued = false
	_hitstop_triggered_this_swing = false

	# Permite redirecionar o golpe se houver entrada direcional no início do passo (RF-006)
	if input_component != null and movement_component != null:
		if input_component.move_direction.length_squared() > 0.0001:
			movement_component.set_facing_direction(input_component.move_direction)
		_align_weapon_pivot(movement_component.facing_direction)

	var style: CombatStyleData = _get_active_style()
	_current_step_data = style.get_step(current_step_index)

	if hitbox_component != null:
		hitbox_component.deactivate()
		hitbox_component.configure_geometry(
			_current_step_data.hitbox_size,
			_current_step_data.hitbox_forward_offset,
			style.slash_color
		)

	current_phase = Phase.WINDUP
	_phase_timer = _current_step_data.windup_duration
	attack_step_started.emit(current_step_index + 1, style.get_step_count(), &"WINDUP")
	attack_phase_changed.emit(&"WINDUP")


func _advance_phase() -> void:
	if current_phase == Phase.WINDUP:
		current_phase = Phase.ACTIVE
		_phase_timer = _current_step_data.active_duration
		_activate_step_hitbox()
		attack_phase_changed.emit(&"ACTIVE")
	elif current_phase == Phase.ACTIVE:
		if hitbox_component != null:
			hitbox_component.deactivate()
		current_phase = Phase.RECOVERY
		_phase_timer = _current_step_data.recovery_duration
		attack_phase_changed.emit(&"RECOVERY")
		# Se o jogador apertou Dodge durante a fase ACTIVE, dispara no 1º frame de RECOVERY (RF-007)
		if _try_dodge_cancel():
			return
	elif current_phase == Phase.RECOVERY:
		if _combo_queued and _can_advance_combo():
			_start_combo_step(current_step_index + 1)
			return
		if input_component != null and input_component.move_direction.length_squared() > 0.0001:
			transition_requested.emit(self, &"MoveState")
		else:
			transition_requested.emit(self, &"IdleState")


func _activate_step_hitbox() -> void:
	if hitbox_component == null:
		return
	var dir: Vector2 = Vector2.DOWN
	if movement_component != null:
		dir = movement_component.facing_direction
	_align_weapon_pivot(dir)

	var atk_data: AttackData = null
	if combat_style_component != null:
		atk_data = combat_style_component.build_attack_data(current_step_index, dir, CombatTypes.Team.PLAYER)
	else:
		atk_data = AttackData.new()
		atk_data.direction = dir
	hitbox_component.activate(atk_data)


func _apply_phase_movement(delta: float) -> void:
	if movement_component == null or _current_step_data == null:
		return
	if current_phase == Phase.ACTIVE:
		movement_component.apply_direct_velocity(
			movement_component.facing_direction,
			_current_step_data.attack_step_speed
		)
	else:
		movement_component.apply_friction(delta)


func _try_dodge_cancel() -> bool:
	if input_component != null and input_component.has_buffered_dodge():
		transition_requested.emit(self, &"DodgeState")
		return not is_active
	return false


func _can_advance_combo() -> bool:
	var style: CombatStyleData = _get_active_style()
	return (current_step_index + 1) < style.get_step_count()


func _get_active_style() -> CombatStyleData:
	if combat_style_component != null:
		return combat_style_component.get_active_style()
	var fallback: CombatStyleData = CombatStyleData.new()
	return fallback


func _align_weapon_pivot(direction: Vector2) -> void:
	if weapon_pivot != null and direction.length_squared() > 0.0001:
		weapon_pivot.rotation = direction.angle()


func _on_hitbox_hit_landed(_hurtbox: HurtboxComponent, resolution: Dictionary) -> void:
	# EC-002: Hitstop acionado no máximo 1 vez por golpe mesmo se acertar múltiplos alvos
	if not _hitstop_triggered_this_swing:
		_hitstop_triggered_this_swing = true
		_hitstop_timer = float(resolution.get("hitstop_duration", 0.0))
