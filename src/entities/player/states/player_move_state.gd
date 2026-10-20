class_name PlayerMoveState
extends State
## Estado de locomoção direcional ativa da Caçadora (RF-001, RF-002, RF-003, RF-004, RF-005).
## Acelera na direção do input, atualiza facing_direction e transita para IdleState ou DodgeState.

@export var movement_component: MovementComponent
@export var input_component: PlayerInputComponent
@export var dodge_state: PlayerDodgeState


func physics_update(delta: float) -> void:
	if input_component != null and dodge_state != null:
		if input_component.has_buffered_dodge() and dodge_state.can_dodge():
			input_component.consume_dodge_request()
			transition_requested.emit(self, &"DodgeState")
			return

	if input_component == null or movement_component == null:
		return

	var direction: Vector2 = input_component.move_direction
	if direction.length_squared() > 0.0001:
		movement_component.accelerate_in_direction(direction, delta)
	else:
		movement_component.apply_friction(delta)
		if movement_component.is_stopped():
			transition_requested.emit(self, &"IdleState")
