class_name PlayerDodgeState
extends State
## Estado de esquiva tática (Dash direcional e Backstep em repouso) da Caçadora (RF-005, RF-006, RF-007, EC-002, EC-003, EC-004).
## Trava a direção no enter(), ativa i-frames desde o frame 1 até invulnerability_duration,
## desacelera no terço final (recovery vulnerável) e inicia o cooldown ao sair.

signal dodge_started(direction: Vector2, is_backstep: bool)
signal dodge_ended()
signal invulnerability_started()
signal invulnerability_ended()
signal dodge_cooldown_updated(time_remaining: float)

@export var movement_component: MovementComponent
@export var input_component: PlayerInputComponent
@export var config: PlayerMovementConfig
@export var health_component: HealthComponent

var _locked_direction: Vector2 = Vector2.DOWN
var _initial_dodge_speed: float = 460.0
var _elapsed_time: float = 0.0
var _dodge_duration: float = 0.24
var _invulnerability_duration: float = 0.16
var _cooldown_timer: float = 0.0
var _is_invulnerable: bool = false
var _is_backstep: bool = false


func _physics_process(delta: float) -> void:
	# O cooldown decresce mesmo quando o estado ativo na StateMachine é Idle ou Move
	if not is_active and _cooldown_timer > 0.0:
		_cooldown_timer = maxf(0.0, _cooldown_timer - delta)
		dodge_cooldown_updated.emit(_cooldown_timer)


func can_dodge() -> bool:
	return not is_active and _cooldown_timer <= 0.0


func can_enter(from_state: State) -> bool:
	if not can_dodge():
		return false
	if from_state != null and not from_state.can_be_interrupted_by(self):
		return false
	return true


func is_invulnerable() -> bool:
	return _is_invulnerable


func is_backstep() -> bool:
	return _is_backstep


func get_cooldown_remaining() -> float:
	return _cooldown_timer


func enter() -> void:
	super.enter()
	_elapsed_time = 0.0

	if input_component != null:
		input_component.consume_dodge_request()

	if config != null:
		config.sanitize()
		_dodge_duration = config.dodge_duration
		_invulnerability_duration = config.get_sanitized_invulnerability_duration()
	else:
		_dodge_duration = 0.24
		_invulnerability_duration = 0.16

	var input_dir: Vector2 = Vector2.ZERO
	if input_component != null:
		input_dir = input_component.move_direction

	var current_facing: Vector2 = Vector2.DOWN
	if movement_component != null:
		current_facing = movement_component.facing_direction

	var base_dodge_speed: float = 460.0
	var backstep_mult: float = 0.75
	if config != null:
		base_dodge_speed = config.dodge_speed
		backstep_mult = config.backstep_speed_multiplier

	# RF-005 & EC-002: Se houver input direcional, faz Dash na direção do input e atualiza facing_direction;
	# se acionada a partir do repouso sem input direcional, executa Backstep em -facing_direction mantendo o olhar.
	if input_dir.length_squared() > 0.0001:
		_is_backstep = false
		_locked_direction = input_dir.normalized()
		_initial_dodge_speed = base_dodge_speed
		if movement_component != null:
			movement_component.set_facing_direction(_locked_direction)
	else:
		_is_backstep = true
		_locked_direction = (-current_facing).normalized()
		_initial_dodge_speed = base_dodge_speed * backstep_mult

	# RF-006: i-frames iniciam imediatamente no frame 1
	if _invulnerability_duration > 0.0:
		_is_invulnerable = true
		invulnerability_started.emit()
		if health_component != null:
			health_component.grant_invulnerability(&"dodge", _invulnerability_duration)
	else:
		_is_invulnerable = false

	if movement_component != null:
		movement_component.apply_direct_velocity(_locked_direction, _initial_dodge_speed)

	dodge_started.emit(_locked_direction, _is_backstep)


func physics_update(delta: float) -> void:
	_elapsed_time += delta

	# Verifica término da janela de i-frames antes do fim do movimento (RF-006)
	if _is_invulnerable and _elapsed_time >= _invulnerability_duration:
		_is_invulnerable = false
		invulnerability_ended.emit()
		if health_component != null:
			health_component.revoke_invulnerability(&"dodge")

	var current_speed: float = _compute_current_dodge_speed()
	if movement_component != null:
		movement_component.apply_direct_velocity(_locked_direction, current_speed)

	if _elapsed_time >= _dodge_duration:
		if input_component != null and input_component.move_direction.length_squared() > 0.0001:
			transition_requested.emit(self, &"MoveState")
		else:
			transition_requested.emit(self, &"IdleState")


func exit() -> void:
	super.exit()
	if _is_invulnerable:
		_is_invulnerable = false
		invulnerability_ended.emit()
		if health_component != null:
			health_component.revoke_invulnerability(&"dodge")

	if config != null:
		_cooldown_timer = config.dodge_cooldown
	else:
		_cooldown_timer = 0.35

	dodge_cooldown_updated.emit(_cooldown_timer)
	dodge_ended.emit()


## Mantém velocidade máxima durante a fase inicial e desacelera suavemente no terço final (DT-05).
func _compute_current_dodge_speed() -> float:
	var end_factor: float = 0.35
	if config != null:
		end_factor = config.dodge_end_speed_factor

	var recovery_start_time: float = _invulnerability_duration
	if recovery_start_time <= 0.0 or recovery_start_time >= _dodge_duration:
		recovery_start_time = _dodge_duration * (2.0 / 3.0)

	if _elapsed_time <= recovery_start_time:
		return _initial_dodge_speed

	var recovery_duration: float = maxf(_dodge_duration - recovery_start_time, 0.0001)
	var t: float = clampf((_elapsed_time - recovery_start_time) / recovery_duration, 0.0, 1.0)
	return lerpf(_initial_dodge_speed, _initial_dodge_speed * end_factor, t)
