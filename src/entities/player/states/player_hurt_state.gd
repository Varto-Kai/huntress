class_name PlayerHurtState
extends State
## Estado de reação a dano da Caçadora (SPEC-002: RF-005, RF-008, EC-003).
## Interrompe ataques em andamento, aplica knockback desacelerado por atrito durante hurt_duration
## e retorna para MoveState ou IdleState.

@export var movement_component: MovementComponent
@export var input_component: PlayerInputComponent
@export var config: PlayerMovementConfig

var _hurt_timer: float = 0.0
var _pending_knockback: Vector2 = Vector2.ZERO


func setup_knockback(knockback_vector: Vector2) -> void:
	_pending_knockback = knockback_vector


func enter() -> void:
	var duration: float = 0.22
	if config != null:
		config.sanitize()
		duration = config.hurt_duration
	_hurt_timer = duration

	if movement_component != null:
		if _pending_knockback.length_squared() > 0.0001:
			movement_component.apply_direct_velocity(_pending_knockback.normalized(), _pending_knockback.length())
		else:
			movement_component.apply_direct_velocity(-movement_component.facing_direction, 160.0)


func physics_update(delta: float) -> void:
	_hurt_timer = maxf(0.0, _hurt_timer - delta)
	if movement_component != null:
		movement_component.apply_friction(delta)

	if _hurt_timer <= 0.0:
		if input_component != null and input_component.move_direction.length_squared() > 0.0001:
			transition_requested.emit(self, &"MoveState")
		else:
			transition_requested.emit(self, &"IdleState")


func exit() -> void:
	_pending_knockback = Vector2.ZERO
