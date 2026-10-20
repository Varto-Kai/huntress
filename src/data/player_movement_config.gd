class_name PlayerMovementConfig
extends Resource
## Custom Resource que armazena e valida todos os parâmetros @export de Game Feel
## para a locomoção, orientação, esquiva e resposta de combate da Caçadora (SPEC-001 & SPEC-002).

@export_group("Locomotion (CrossCode Feel)")
@export_range(50.0, 600.0, 5.0, "suffix:px/s") var max_speed: float = 200.0
@export_range(0.5, 1.5, 0.05) var y_axis_speed_ratio: float = 1.0
@export_range(200.0, 5000.0, 50.0, "suffix:px/s²") var acceleration: float = 1800.0
@export_range(200.0, 5000.0, 50.0, "suffix:px/s²") var friction: float = 1600.0
@export var default_facing_direction: Vector2 = Vector2.DOWN

@export_group("Dodge & Backstep")
@export_range(100.0, 1200.0, 10.0, "suffix:px/s") var dodge_speed: float = 460.0
@export_range(0.25, 1.5, 0.05) var backstep_speed_multiplier: float = 0.75
@export_range(0.0, 1.0, 0.05) var dodge_end_speed_factor: float = 0.35
@export_range(0.05, 1.0, 0.01, "suffix:s") var dodge_duration: float = 0.24
@export_range(0.0, 1.0, 0.01, "suffix:s") var invulnerability_duration: float = 0.16
@export_range(0.0, 3.0, 0.05, "suffix:s") var dodge_cooldown: float = 0.35
@export_range(0.0, 0.4, 0.01, "suffix:s") var dodge_input_buffer_time: float = 0.12

@export_group("Combat & Hurt Timing (SPEC-002)")
@export_range(0.05, 0.5, 0.01, "suffix:s") var combo_input_buffer_time: float = 0.18
@export_range(0.05, 1.0, 0.01, "suffix:s") var hurt_duration: float = 0.22


func get_sanitized_default_facing() -> Vector2:
	if default_facing_direction.length_squared() <= 0.0001:
		return Vector2.DOWN
	return default_facing_direction.normalized()


func get_sanitized_invulnerability_duration() -> float:
	var valid_dodge_duration: float = maxf(dodge_duration, 0.05)
	return clampf(invulnerability_duration, 0.0, valid_dodge_duration)


func sanitize() -> void:
	max_speed = maxf(max_speed, 1.0)
	y_axis_speed_ratio = clampf(y_axis_speed_ratio, 0.5, 1.5)
	acceleration = maxf(acceleration, 1.0)
	friction = maxf(friction, 1.0)
	default_facing_direction = get_sanitized_default_facing()
	dodge_speed = maxf(dodge_speed, 1.0)
	backstep_speed_multiplier = clampf(backstep_speed_multiplier, 0.25, 1.5)
	dodge_end_speed_factor = clampf(dodge_end_speed_factor, 0.0, 1.0)
	dodge_duration = maxf(dodge_duration, 0.05)
	invulnerability_duration = get_sanitized_invulnerability_duration()
	dodge_cooldown = maxf(dodge_cooldown, 0.0)
	dodge_input_buffer_time = clampf(dodge_input_buffer_time, 0.0, 0.4)
	combo_input_buffer_time = clampf(combo_input_buffer_time, 0.05, 0.5)
	hurt_duration = clampf(hurt_duration, 0.05, 1.0)
