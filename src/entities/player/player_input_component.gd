class_name PlayerInputComponent
extends Node
## Componente dedicado à captura do InputMap da Caçadora, normalização direcional,
## anulação de eixos opostos (EC-001), limpeza por perda de foco (EC-005),
## Input Buffer de esquiva/ataque (EC-003, RF-006) e atalhos de Estilo/Óleo (SPEC-001 & SPEC-002).

signal style_switch_requested()
signal oil_switch_requested()

@export var config: PlayerMovementConfig

var move_direction: Vector2 = Vector2.ZERO
var _dodge_buffer_timer: float = 0.0
var _attack_buffer_timer: float = 0.0
var _window_focused: bool = true


func _physics_process(delta: float) -> void:
	if _dodge_buffer_timer > 0.0:
		_dodge_buffer_timer = maxf(0.0, _dodge_buffer_timer - delta)
	if _attack_buffer_timer > 0.0:
		_attack_buffer_timer = maxf(0.0, _attack_buffer_timer - delta)

	if not _window_focused:
		move_direction = Vector2.ZERO
		return

	var left_pressed: bool = Input.is_action_pressed(&"move_left")
	var right_pressed: bool = Input.is_action_pressed(&"move_right")
	var up_pressed: bool = Input.is_action_pressed(&"move_up")
	var down_pressed: bool = Input.is_action_pressed(&"move_down")

	move_direction = compute_normalized_direction(left_pressed, right_pressed, up_pressed, down_pressed)

	if Input.is_action_just_pressed(&"dodge"):
		register_dodge_press()
	if InputMap.has_action(&"attack") and Input.is_action_just_pressed(&"attack"):
		register_attack_press()
	if InputMap.has_action(&"switch_style") and Input.is_action_just_pressed(&"switch_style"):
		style_switch_requested.emit()
	if InputMap.has_action(&"switch_oil") and Input.is_action_just_pressed(&"switch_oil"):
		oil_switch_requested.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		on_window_focus_lost()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_window_focused = true


static func compute_normalized_direction(
	left: bool,
	right: bool,
	up: bool,
	down: bool
) -> Vector2:
	var x_axis: float = 0.0
	if right and not left:
		x_axis = 1.0
	elif left and not right:
		x_axis = -1.0

	var y_axis: float = 0.0
	if down and not up:
		y_axis = 1.0
	elif up and not down:
		y_axis = -1.0

	var raw_vector: Vector2 = Vector2(x_axis, y_axis)
	if raw_vector.length_squared() > 1.0:
		return raw_vector.normalized()
	return raw_vector


func register_dodge_press() -> void:
	var buffer_duration: float = 0.12
	if config != null:
		buffer_duration = config.dodge_input_buffer_time
	_dodge_buffer_timer = maxf(buffer_duration, 0.017)


func has_buffered_dodge() -> bool:
	return _dodge_buffer_timer > 0.0


func consume_dodge_request() -> bool:
	if _dodge_buffer_timer > 0.0:
		_dodge_buffer_timer = 0.0
		return true
	return false


func get_dodge_buffer_time_remaining() -> float:
	return _dodge_buffer_timer


func register_attack_press() -> void:
	var buffer_duration: float = 0.18
	if config != null:
		buffer_duration = config.combo_input_buffer_time
	_attack_buffer_timer = maxf(buffer_duration, 0.017)


func has_buffered_attack() -> bool:
	return _attack_buffer_timer > 0.0


func consume_attack_request() -> bool:
	if _attack_buffer_timer > 0.0:
		_attack_buffer_timer = 0.0
		return true
	return false


func get_attack_buffer_time_remaining() -> float:
	return _attack_buffer_timer


func on_window_focus_lost() -> void:
	_window_focused = false
	move_direction = Vector2.ZERO
	_dodge_buffer_timer = 0.0
	_attack_buffer_timer = 0.0
