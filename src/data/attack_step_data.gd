class_name AttackStepData
extends Resource
## Configura um golpe individual dentro da cadeia de combo de um Estilo de Luta (SPEC-002: RF-006, RF-009).

@export var step_name: StringName = &"Slash1"
@export_range(0.01, 1.0, 0.01, "suffix:s") var windup_duration: float = 0.06
@export_range(0.02, 0.5, 0.01, "suffix:s") var active_duration: float = 0.08
@export_range(0.02, 1.0, 0.01, "suffix:s") var recovery_duration: float = 0.12
@export_range(0.1, 4.0, 0.05) var damage_multiplier: float = 1.0
@export_range(0.1, 4.0, 0.05) var stagger_multiplier: float = 1.0
@export_range(0.1, 4.0, 0.05) var knockback_multiplier: float = 1.0
@export_range(0.0, 400.0, 5.0, "suffix:px/s") var attack_step_speed: float = 95.0
@export var hitbox_size: Vector2 = Vector2(26.0, 28.0)
@export var hitbox_forward_offset: float = 20.0


func sanitize() -> void:
	windup_duration = maxf(windup_duration, 0.01)
	active_duration = maxf(active_duration, 0.02)
	recovery_duration = maxf(recovery_duration, 0.02)
	damage_multiplier = maxf(damage_multiplier, 0.1)
	stagger_multiplier = maxf(stagger_multiplier, 0.1)
	knockback_multiplier = maxf(knockback_multiplier, 0.0)
	attack_step_speed = maxf(attack_step_speed, 0.0)
	hitbox_size = Vector2(maxf(hitbox_size.x, 4.0), maxf(hitbox_size.y, 4.0))
	hitbox_forward_offset = maxf(hitbox_forward_offset, 0.0)
