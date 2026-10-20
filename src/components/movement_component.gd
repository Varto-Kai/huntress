@tool
class_name MovementComponent
extends Node
## Componente modular responsável por calcular aceleração, atrito, proporção Top-Down (y_axis_speed_ratio),
## orientação persistente (facing_direction) e executar move_and_slide() em CharacterBody2D (RF-001, RF-002, RF-004, EC-004, EC-006).

signal facing_direction_changed(new_direction: Vector2)
signal velocity_updated(current_velocity: Vector2)

@export var body: CharacterBody2D
@export var config: PlayerMovementConfig

var current_velocity: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	setup(body, config)


## Inicializa o componente com a entidade física e a configuração de Game Feel.
func setup(target_body: CharacterBody2D, movement_config: PlayerMovementConfig) -> void:
	body = target_body
	config = movement_config
	if config != null:
		config.sanitize()
		set_facing_direction(config.get_sanitized_default_facing())
	else:
		set_facing_direction(Vector2.DOWN)

	if body != null:
		body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


## Calcula a velocidade alvo escalada por max_speed e y_axis_speed_ratio (RF-001, EC-006, SC-001).
func compute_target_velocity(direction: Vector2, base_speed: float) -> Vector2:
	if direction.length_squared() <= 0.0001 or config == null:
		return Vector2.ZERO
	var normalized_dir: Vector2 = direction.normalized()
	var scaled_dir: Vector2 = Vector2(normalized_dir.x, normalized_dir.y * config.y_axis_speed_ratio)
	return scaled_dir * base_speed


## Acelera progressivamente em direção ao vetor de entrada normalizado (RF-002).
func accelerate_in_direction(direction: Vector2, delta: float) -> Vector2:
	if config == null:
		return current_velocity
	var target_vel: Vector2 = compute_target_velocity(direction, config.max_speed)
	current_velocity = current_velocity.move_toward(target_vel, config.acceleration * delta)
	if direction.length_squared() > 0.0001:
		set_facing_direction(direction)
	_apply_to_body()
	return current_velocity


## Desacelera aplicando o atrito parametrizado até atingir Vector2.ZERO (RF-002).
func apply_friction(delta: float) -> Vector2:
	if config == null:
		return current_velocity
	current_velocity = current_velocity.move_toward(Vector2.ZERO, config.friction * delta)
	_apply_to_body()
	return current_velocity


## Define uma velocidade direta na direção travada (usado pelo estado Dodge / Backstep) (RF-005).
func apply_direct_velocity(locked_direction: Vector2, speed: float) -> Vector2:
	var target_vel: Vector2 = compute_target_velocity(locked_direction, speed)
	current_velocity = target_vel
	_apply_to_body()
	return current_velocity


## Atualiza a orientação válida (nunca permite Vector2.ZERO) e emite sinal se houver mudança (RF-004).
func set_facing_direction(new_direction: Vector2) -> void:
	if new_direction.length_squared() <= 0.0001:
		return
	var normalized: Vector2 = new_direction.normalized()
	if not facing_direction.is_equal_approx(normalized):
		facing_direction = normalized
		facing_direction_changed.emit(facing_direction)


func is_stopped() -> bool:
	return current_velocity.length_squared() <= 0.01


func _apply_to_body() -> void:
	if body != null:
		body.velocity = current_velocity
		body.move_and_slide()
		current_velocity = body.velocity
	velocity_updated.emit(current_velocity)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if body == null:
		warnings.append("MovementComponent requer um 'body' (CharacterBody2D) atribuído.")
	if config == null:
		warnings.append("MovementComponent requer um 'config' (PlayerMovementConfig) atribuído.")
	return warnings
