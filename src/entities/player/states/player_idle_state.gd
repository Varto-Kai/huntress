class_name PlayerIdleState
extends State
## Estado de repouso da Caçadora (RF-002, RF-003, RF-005, EC-001, EC-002).
## Aplica desaceleração por atrito até velocidade zero e transita para MoveState, DodgeState ou AttackState.

@export var movement_component: MovementComponent
@export var input_component: PlayerInputComponent


func physics_update(delta: float) -> void:
	if input_component != null and input_component.has_buffered_dodge():
		transition_requested.emit(self, &"DodgeState")
		if not is_active:
			return

	if input_component != null and input_component.has_buffered_attack():
		input_component.consume_attack_request()
		transition_requested.emit(self, &"AttackState")
		return

	if input_component != null and input_component.move_direction.length_squared() > 0.0001:
		transition_requested.emit(self, &"MoveState")
		return

	if movement_component != null:
		movement_component.apply_friction(delta)
