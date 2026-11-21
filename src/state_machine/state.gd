class_name State
extends Node
## Classe base abstrata para todos os estados da StateMachine (RF-003).
## Segue estritamente a regra Call Down, Signal Up da Constituição.

@warning_ignore("unused_signal")
signal transition_requested(from_state: State, to_state_name: StringName)

## Flag de ciclo de vida indicando se este estado é o estado ativo na StateMachine.
var is_active: bool = false


## Executado quando o estado se torna o estado ativo.
func enter() -> void:
	is_active = true


## Executado imediatamente antes de sair deste estado para outro.
func exit() -> void:
	is_active = false


## Executado a cada frame visual (_process) pela StateMachine.
func update(_delta: float) -> void:
	pass


## Executado a cada tick físico (_physics_process) pela StateMachine.
func physics_update(_delta: float) -> void:
	pass


## Retorna se este estado aceita transição de entrada a partir de _from_state.
func can_enter(_from_state: State) -> bool:
	return true


## Retorna se este estado permite ser interrompido por _to_state.
func can_be_interrupted_by(_to_state: State) -> bool:
	return true

