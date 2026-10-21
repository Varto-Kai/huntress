class_name PlayerInteractionComponent
extends Area2D
## Componente Area2D acoplado à Caçadora para detecção de pistas (InteractableClue),
## reagentes (InteractableReagent) e fogueiras (InteractableCampfire) em alcance (SPEC-003 & SPEC-004).

signal focused_clue_changed(clue: InteractableClue)
signal inspection_started(clue: InteractableClue, duration: float)
signal inspection_progress_changed(clue: InteractableClue, ratio: float)
signal inspection_cancelled(clue: InteractableClue)
signal clue_inspection_completed(clue_data: ClueData)
signal reagent_collected_from_world(reagent_data: ReagentData, amount: int)
signal campfire_interacted(campfire: InteractableCampfire)

@export_range(16.0, 120.0, 2.0, "suffix:px") var interaction_radius: float = 44.0

var state_machine: StateMachine
var input_component: PlayerInputComponent
var focused_clue: InteractableClue = null
var focused_reagent: InteractableReagent = null
var focused_campfire: InteractableCampfire = null
var _overlapping_clues: Array[InteractableClue] = []
var _overlapping_reagents: Array[InteractableReagent] = []
var _overlapping_campfires: Array[InteractableCampfire] = []
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
	_refresh_focused_targets()

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
	_refresh_focused_targets()

	if focused_reagent != null and not focused_reagent.is_collected:
		var res: Dictionary = focused_reagent.collect_reagent()
		_refresh_focused_targets()
		if bool(res.get("collected", false)):
			var r_data: ReagentData = res.get("reagent", null) as ReagentData
			var amt: int = int(res.get("amount", 1))
			reagent_collected_from_world.emit(r_data, amt)
			return true

	if focused_campfire != null and (focused_clue == null or focused_clue.is_inspected):
		focused_campfire.activate_campfire()
		campfire_interacted.emit(focused_campfire)
		return true

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


static func select_best_clue(origin: Vector2, candidates: Array[InteractableClue]) -> InteractableClue:
	var best_uninspected: InteractableClue = null
	var best_uninspected_dist_sq: float = INF
	var best_any: InteractableClue = null
	var best_any_dist_sq: float = INF

	for clue: InteractableClue in candidates:
		if clue == null or not is_instance_valid(clue):
			continue
		var dist_sq: float = origin.distance_squared_to(clue.global_position)
		if not clue.is_inspected and dist_sq < best_uninspected_dist_sq:
			best_uninspected_dist_sq = dist_sq
			best_uninspected = clue
		if dist_sq < best_any_dist_sq:
			best_any_dist_sq = dist_sq
			best_any = clue

	return best_uninspected if best_uninspected != null else best_any


func register_candidate_for_test(area: Area2D) -> void:
	_on_area_entered(area)


func unregister_candidate_for_test(area: Area2D) -> void:
	_on_area_exited(area)


func _can_remain_inspecting() -> bool:
	if _inspecting_clue == null or not is_instance_valid(_inspecting_clue):
		return false
	if _inspecting_clue != focused_clue or not is_in_allowed_interaction_state():
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
	_refresh_focused_targets()
	if data != null:
		clue_inspection_completed.emit(data)


func _refresh_focused_targets() -> void:
	var best_clue: InteractableClue = select_best_clue(global_position, _overlapping_clues)
	if best_clue != focused_clue:
		if focused_clue != null and is_instance_valid(focused_clue):
			focused_clue.set_focused(false)
		focused_clue = best_clue
		if focused_clue != null and is_instance_valid(focused_clue):
			focused_clue.set_focused(true)
		focused_clue_changed.emit(focused_clue)

	var best_reagent: InteractableReagent = null
	var best_r_dist: float = INF
	for r: InteractableReagent in _overlapping_reagents:
		if r != null and is_instance_valid(r) and not r.is_collected:
			var d: float = global_position.distance_squared_to(r.global_position)
			if d < best_r_dist:
				best_r_dist = d
				best_reagent = r
	if best_reagent != focused_reagent:
		if focused_reagent != null and is_instance_valid(focused_reagent):
			focused_reagent.set_focused(false)
		focused_reagent = best_reagent
		if focused_reagent != null and is_instance_valid(focused_reagent):
			focused_reagent.set_focused(true)

	var best_fire: InteractableCampfire = null
	var best_f_dist: float = INF
	for c: InteractableCampfire in _overlapping_campfires:
		if c != null and is_instance_valid(c):
			var d: float = global_position.distance_squared_to(c.global_position)
			if d < best_f_dist:
				best_f_dist = d
				best_fire = c
	if best_fire != focused_campfire:
		if focused_campfire != null and is_instance_valid(focused_campfire):
			focused_campfire.set_focused(false)
		focused_campfire = best_fire
		if focused_campfire != null and is_instance_valid(focused_campfire):
			focused_campfire.set_focused(true)


func _on_area_entered(area: Area2D) -> void:
	if area is InteractableClue and not _overlapping_clues.has(area as InteractableClue):
		_overlapping_clues.append(area as InteractableClue)
	elif area is InteractableReagent and not _overlapping_reagents.has(area as InteractableReagent):
		_overlapping_reagents.append(area as InteractableReagent)
	elif area is InteractableCampfire and not _overlapping_campfires.has(area as InteractableCampfire):
		_overlapping_campfires.append(area as InteractableCampfire)
	_refresh_focused_targets()


func _on_area_exited(area: Area2D) -> void:
	if area is InteractableClue and _overlapping_clues.has(area as InteractableClue):
		_overlapping_clues.erase(area as InteractableClue)
		if _inspecting_clue == area:
			cancel_active_inspection()
	elif area is InteractableReagent and _overlapping_reagents.has(area as InteractableReagent):
		_overlapping_reagents.erase(area as InteractableReagent)
	elif area is InteractableCampfire and _overlapping_campfires.has(area as InteractableCampfire):
		_overlapping_campfires.erase(area as InteractableCampfire)
	_refresh_focused_targets()
