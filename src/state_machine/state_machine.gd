@tool
class_name StateMachine
extends Node
## Máquina de Estados Finita baseada em Nodes (RF-003, SC-002).
## Gerencia transições determinísticas via sinal sem acoplamento com estados concretos.

signal state_changed(previous_state_name: StringName, new_state_name: StringName)

@export var initial_state: State

var current_state: State = null
var _states: Dictionary = {}


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	initialize()


## Registra todos os nós filhos do tipo State e entra no estado inicial configurado.
func initialize() -> void:
	_states.clear()
	for child: Node in get_children():
		if child is State:
			var state_node: State = child as State
			var key: StringName = StringName(state_node.name.to_lower())
			_states[key] = state_node
			if not state_node.transition_requested.is_connected(_on_state_transition_requested):
				state_node.transition_requested.connect(_on_state_transition_requested)

	if initial_state != null:
		current_state = initial_state
		current_state.is_active = true
		current_state.enter()
		state_changed.emit(&"", StringName(current_state.name))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or current_state == null:
		return
	current_state.update(delta)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or current_state == null:
		return
	current_state.physics_update(delta)


## Realiza a transição imediata para o estado alvo pelo nome (case-insensitive).
func transition_to(target_state_name: StringName) -> bool:
	var key: StringName = StringName(String(target_state_name).to_lower())
	if not _states.has(key):
		push_warning("StateMachine: Estado alvo '%s' não encontrado." % String(target_state_name))
		return false

	var next_state: State = _states[key] as State
	if next_state == null or next_state == current_state:
		return false

	if current_state != null and not current_state.can_be_interrupted_by(next_state):
		return false

	if not next_state.can_enter(current_state):
		return false

	var previous_name: StringName = &""
	if current_state != null:
		previous_name = StringName(current_state.name)
		current_state.is_active = false
		current_state.exit()

	current_state = next_state
	current_state.is_active = true
	current_state.enter()
	state_changed.emit(previous_name, StringName(current_state.name))
	return true


## Alias para transition_to.
func change_state(next_state_name: StringName) -> bool:
	return transition_to(next_state_name)


## Retorna a instância de State associada ao nome ou null se não encontrada.
func get_state(state_name: StringName) -> State:
	var key: StringName = StringName(String(state_name).to_lower())
	return _states.get(key, null)


func get_current_state_name() -> StringName:
	if current_state == null:
		return &""
	return StringName(current_state.name)


func _on_state_transition_requested(from_state: State, to_state_name: StringName) -> void:
	if from_state != current_state:
		return
	transition_to(to_state_name)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if initial_state == null:
		warnings.append("StateMachine requer um 'initial_state' atribuído no Inspector.")
	var has_state_child: bool = false
	for child: Node in get_children():
		if child is State:
			has_state_child = true
			break
	if not has_state_child:
		warnings.append("StateMachine requer pelo menos um nó filho herdando de 'State'.")
	return warnings
