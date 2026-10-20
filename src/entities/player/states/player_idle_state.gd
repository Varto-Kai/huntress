class_name PlayerIdleState
extends State
## Estado de repouso da Caçadora (RF-002, RF-003, RF-005, EC-001, EC-002).
## Aplica desaceleração por atrito até velocidad zero e transita para MoveState ou DodgeState (Backstep).

@export var movement_component: MovementComponent
@export var input_component: PlayerInputComponent
@export var dodge_state: PlayerDodgeState


func physics_update(delta: float) -> void:
	if input_component != null and dodge_state != null:
		if input_component.has_buffered_dodge() and dodge_state.can_dodge():
			input_component.consume_dodge_request()
			transition_requested.emit(self, &"DodgeState")
			return

	if input_component != null and input_component.move_direction.length_squared() > 0.0001:
		transition_requested.emit(self, &"MoveState")
		return

	if movement_component != null:
		movement_component.apply_friction(delta)
