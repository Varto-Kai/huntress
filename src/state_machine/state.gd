class_name State
extends Node
## Classe base abstrata para todos os estados da StateMachine (RF-003).
## Segue estritamente a regra Call Down, Signal Up da Constituição.

@warning_ignore("unused_signal")
signal transition_requested(from_state: State, to_state_name: StringName)


## Executado quando o estado se torna o estado ativo.
func enter() -> void:
	pass


## Executado imediatamente antes de sair deste estado para outro.
func exit() -> void:
	pass


## Executado a cada frame visual (_process) pela StateMachine.
func update(_delta: float) -> void:
	pass


## Executado a cada tick físico (_physics_process) pela StateMachine.
func physics_update(_delta: float) -> void:
	pass
