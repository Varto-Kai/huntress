class_name PlayerInteractionComponent
extends Area2D
## Componente Area2D acoplado à Caçadora para detecção de pistas em alcance,
## seleção determinística da pista não inspecionada mais próxima (EC-001),
## canalização curta cancelável (Q2 / RF-002) e validação de estado (EC-003 / EC-004).

signal focused_clue_changed(clue: InteractableClue)
signal inspection_started(clue: InteractableClue, duration: float)
signal inspection_progress_changed(clue: InteractableClue, ratio: float)
signal inspection_cancelled(clue: InteractableClue)
signal clue_inspection_completed(clue_data: ClueData)

@export_range(16.0, 120.0, 2.0, "suffix:px") var interaction_radius: float = 44.0

var state_machine: StateMachine
var input_component: PlayerInputComponent
var focused_clue: InteractableClue = null
var _overlapping_clues: Array[InteractableClue] = []
var _inspecting_clue: InteractableClue = null
var _inspect_elapsed: float = 0.0
var _inspect_target_duration: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 8
	monitoring = true
	monitorable = false

	var shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node != null and shape_node.shape is CircleShape2D:
		(shape_node.shape as CircleShape2D).radius = interaction_radius

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not area_exited.is_connected(_on_area_exited):
		area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	_refresh_focused_clue()

	if _inspecting_clue != null:
		if not _can_remain_inspecting():
			cancel_active_inspection()
			return

		_inspect_elapsed += delta
		var ratio: float = 1.0
		if _inspect_target_duration > 0.0:
			ratio = clampf(_inspect_elapsed / _inspect_target_duration, 0.0, 1.0)
		_inspecting_clue.set_inspection_progress(ratio)
		inspection_progress_changed.emit(_inspecting_clue, ratio)

		if _inspect_elapsed >= _inspect_target_duration:
			_finish_inspection()


func try_start_interaction() -> bool:
	if not is_in_allowed_interaction_state():
		return false
	_refresh_focused_clue()
	if focused_clue == null:
		return false

	_inspecting_clue = focused_clue
	_inspect_elapsed = 0.0
	_inspect_target_duration = maxf(0.0, focused_clue.inspect_duration)
	inspection_started.emit(_inspecting_clue, _inspect_target_duration)

	if _inspect_target_duration <= 0.0001:
		_finish_inspection()
	else:
		_inspecting_clue.set_inspection_progress(0.01)
	return true


func cancel_active_inspection() -> void:
	if _inspecting_clue == null:
		return
	var prev: InteractableClue = _inspecting_clue
	_inspecting_clue = null
	_inspect_elapsed = 0.0
	_inspect_target_duration = 0.0
	if is_instance_valid(prev):
		prev.set_inspection_progress(0.0)
	inspection_cancelled.emit(prev)


func is_inspecting() -> bool:
	return _inspecting_clue != null


func is_in_allowed_interaction_state() -> bool:
	if input_component != null and input_component.gameplay_inputs_blocked:
		return false
	if state_machine == null or state_machine.current_state == null:
		return true
	var state_name: StringName = state_machine.current_state.name
	return state_name == &"IdleState" or state_name == &"MoveState"


## Função pura e determinística para seleção da melhor pista em alcance (EC-001).
static func select_best_clue(origin: Vector2, candidates: Array[InteractableClue]) -> InteractableClue:
	var best_uninspected: InteractableClue = null
	var best_uninspected_dist_sq: float = INF
	var best_any: InteractableClue = null
	var best_any_dist_sq: float = INF

	for clue: InteractableClue in candidates:
		if clue == null or not is_instance_valid(clue):
			continue
		var dist_sq: float = origin.distance_squared_to(clue.global_position)
		if not clue.is_inspected:
			if dist_sq < best_uninspected_dist_sq:
				best_uninspected_dist_sq = dist_sq
				best_uninspected = clue
		if dist_sq < best_any_dist_sq:
			best_any_dist_sq = dist_sq
			best_any = clue

	if best_uninspected != null:
		return best_uninspected
	return best_any


func register_candidate_for_test(clue: InteractableClue) -> void:
	_on_area_entered(clue)


func unregister_candidate_for_test(clue: InteractableClue) -> void:
	_on_area_exited(clue)


func _can_remain_inspecting() -> bool:
	if _inspecting_clue == null or not is_instance_valid(_inspecting_clue):
		return false
	if _inspecting_clue != focused_clue:
		return false
	if not is_in_allowed_interaction_state():
		return false
	if input_component != null and input_component.move_direction.length_squared() > 0.01:
		return false
	return true


func _finish_inspection() -> void:
	if _inspecting_clue == null:
		return
	var target: InteractableClue = _inspecting_clue
	_inspecting_clue = null
	_inspect_elapsed = 0.0
	_inspect_target_duration = 0.0
	var data: ClueData = target.complete_inspection()
	_refresh_focused_clue()
	if data != null:
		clue_inspection_completed.emit(data)


func _refresh_focused_clue() -> void:
	var best: InteractableClue = select_best_clue(global_position, _overlapping_clues)
	if best == focused_clue:
		return
	if focused_clue != null and is_instance_valid(focused_clue):
		focused_clue.set_focused(false)
	focused_clue = best
	if focused_clue != null and is_instance_valid(focused_clue):
		focused_clue.set_focused(true)
	focused_clue_changed.emit(focused_clue)


func _on_area_entered(area: Area2D) -> void:
	var clue: InteractableClue = area as InteractableClue
	if clue != null and not _overlapping_clues.has(clue):
		_overlapping_clues.append(clue)
		_refresh_focused_clue()


func _on_area_exited(area: Area2D) -> void:
	var clue: InteractableClue = area as InteractableClue
	if clue != null and _overlapping_clues.has(clue):
		_overlapping_clues.erase(clue)
		if _inspecting_clue == clue:
			cancel_active_inspection()
		_refresh_focused_clue()
