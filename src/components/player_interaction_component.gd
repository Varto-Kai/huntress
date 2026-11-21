class_name PlayerInteractionComponent
extends Area2D
## Componente Area2D acoplado à Caçadora para detecção e interação polimórfica com o mundo (Issue #25 & SPEC-003/004).
## Gerencia Interactable unificado (Clue, Reagent, Campfire, NPC, Item) com composite scoring por prioridade e distância.

# Sinais polimórficos primários
signal focused_interactable_changed(target: Interactable)
signal interaction_started_target(target: Interactable, duration: float)
signal interaction_progress(target: Interactable, ratio: float)
signal interaction_cancelled_target(target: Interactable)
signal interaction_completed(target: Interactable, result: Variant)

# Sinais legados de domínio para retrocompatibilidade
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
var movement_component: MovementComponent

var focused_interactable: Interactable = null
var focused_clue: InteractableClue = null
var focused_reagent: InteractableReagent = null
var focused_campfire: InteractableCampfire = null

var _overlapping_interactables: Array[Interactable] = []
var _overlapping_clues: Array[InteractableClue] = []
var _overlapping_reagents: Array[InteractableReagent] = []
var _overlapping_campfires: Array[InteractableCampfire] = []

var _active_interactable: Interactable = null
var _inspecting_clue: InteractableClue = null
var _interaction_elapsed: float = 0.0
var _interaction_target_duration: float = 0.0


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

	if _active_interactable != null:
		if not _can_remain_interacting():
			cancel_active_interaction()
			return

		_interaction_elapsed += delta
		var ratio: float = 1.0
		if _interaction_target_duration > 0.0:
			ratio = clampf(_interaction_elapsed / _interaction_target_duration, 0.0, 1.0)

		_active_interactable.set_interaction_progress(ratio)
		interaction_progress.emit(_active_interactable, ratio)

		if _inspecting_clue != null:
			inspection_progress_changed.emit(_inspecting_clue, ratio)

		if _interaction_elapsed >= _interaction_target_duration:
			_finish_interaction()


func try_start_interaction() -> bool:
	if not is_in_allowed_interaction_state():
		return false
	_refresh_focused_targets()

	if focused_interactable == null or not is_instance_valid(focused_interactable):
		return false

	if not focused_interactable.can_interact(self):
		return false

	var hold_time: float = focused_interactable.get_hold_duration()
	if hold_time <= 0.0001:
		_execute_instant_interaction(focused_interactable)
		return true

	_active_interactable = focused_interactable
	_inspecting_clue = focused_interactable as InteractableClue
	_interaction_elapsed = 0.0
	_interaction_target_duration = hold_time

	_active_interactable.start_interaction(self)
	_active_interactable.set_interaction_progress(0.01)
	interaction_started_target.emit(_active_interactable, _interaction_target_duration)

	if _inspecting_clue != null:
		inspection_started.emit(_inspecting_clue, _interaction_target_duration)

	return true


func cancel_active_interaction() -> void:
	if _active_interactable == null:
		return
	var prev: Interactable = _active_interactable
	_active_interactable = null
	_inspecting_clue = null
	_interaction_elapsed = 0.0
	_interaction_target_duration = 0.0

	if is_instance_valid(prev):
		prev.cancel_interaction(self)
		prev.set_interaction_progress(0.0)

	if prev is InteractableClue:
		inspection_cancelled.emit(prev as InteractableClue)
	interaction_cancelled_target.emit(prev)


func cancel_active_inspection() -> void:
	cancel_active_interaction()


func is_inspecting() -> bool:
	return _active_interactable != null


func is_interacting() -> bool:
	return _active_interactable != null


func is_in_allowed_interaction_state() -> bool:
	if input_component != null and input_component.gameplay_inputs_blocked:
		return false
	if state_machine == null or state_machine.current_state == null:
		return true
	var state_name: StringName = state_machine.current_state.name
	return state_name == &"IdleState" or state_name == &"MoveState"


static func compute_interactable_score(origin: Vector2, target: Interactable) -> float:
	if target == null or not is_instance_valid(target):
		return -INF
	if not target.can_interact(null):
		return -INF
	var priority: float = float(target.get_effective_priority())
	var distance: float = origin.distance_to(target.global_position)
	return (priority * 1000.0) - distance


static func select_best_interactable(origin: Vector2, candidates: Array[Interactable]) -> Interactable:
	var best_target: Interactable = null
	var highest_score: float = -INF
	for target: Interactable in candidates:
		if target == null or not is_instance_valid(target):
			continue
		var score: float = compute_interactable_score(origin, target)
		if score > highest_score and score > -INF:
			highest_score = score
			best_target = target
	return best_target


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


func _can_remain_interacting() -> bool:
	if _active_interactable == null or not is_instance_valid(_active_interactable):
		return false
	if _active_interactable != focused_interactable or not is_in_allowed_interaction_state():
		return false
	if input_component != null and input_component.move_direction.length_squared() > 0.01:
		return false
	return true


func _execute_instant_interaction(target: Interactable) -> void:
	var result: Variant = target.complete_interaction(self)
	_emit_legacy_domain_signals(target, result)
	interaction_completed.emit(target, result)
	_refresh_focused_targets()


func _finish_interaction() -> void:
	if _active_interactable == null:
		return
	var target: Interactable = _active_interactable
	_active_interactable = null
	_inspecting_clue = null
	_interaction_elapsed = 0.0
	_interaction_target_duration = 0.0

	var result: Variant = target.complete_interaction(self)
	_emit_legacy_domain_signals(target, result)
	interaction_completed.emit(target, result)
	_refresh_focused_targets()


func _emit_legacy_domain_signals(target: Interactable, result: Variant) -> void:
	if target is InteractableClue:
		var clue_data: ClueData = result as ClueData
		if clue_data == null and target.clue_data != null:
			clue_data = target.clue_data
		if clue_data != null:
			clue_inspection_completed.emit(clue_data)
	elif target is InteractableReagent:
		var dict: Dictionary = result as Dictionary if result is Dictionary else {}
		var r_data: ReagentData = dict.get("reagent", target.reagent_data) as ReagentData
		var amt: int = int(dict.get("amount", target.pickup_amount))
		if r_data != null:
			reagent_collected_from_world.emit(r_data, amt)
	elif target is InteractableCampfire:
		campfire_interacted.emit(target as InteractableCampfire)


func _refresh_focused_targets() -> void:
	for i: int in range(_overlapping_interactables.size() - 1, -1, -1):
		if not is_instance_valid(_overlapping_interactables[i]):
			_overlapping_interactables.remove_at(i)

	var best_target: Interactable = select_best_interactable(global_position, _overlapping_interactables)

	if best_target != focused_interactable:
		if focused_interactable != null and is_instance_valid(focused_interactable):
			focused_interactable.set_focused(false)
		focused_interactable = best_target
		if focused_interactable != null and is_instance_valid(focused_interactable):
			focused_interactable.set_focused(true)
		focused_interactable_changed.emit(focused_interactable)

	var new_focused_clue: InteractableClue = focused_interactable as InteractableClue
	if new_focused_clue != focused_clue:
		focused_clue = new_focused_clue
		focused_clue_changed.emit(focused_clue)

	focused_reagent = focused_interactable as InteractableReagent
	focused_campfire = focused_interactable as InteractableCampfire


func _on_area_entered(area: Area2D) -> void:
	if area is Interactable:
		var interactable: Interactable = area as Interactable
		if not _overlapping_interactables.has(interactable):
			_overlapping_interactables.append(interactable)
		if interactable is InteractableClue and not _overlapping_clues.has(interactable as InteractableClue):
			_overlapping_clues.append(interactable as InteractableClue)
		elif interactable is InteractableReagent and not _overlapping_reagents.has(interactable as InteractableReagent):
			_overlapping_reagents.append(interactable as InteractableReagent)
		elif interactable is InteractableCampfire and not _overlapping_campfires.has(interactable as InteractableCampfire):
			_overlapping_campfires.append(interactable as InteractableCampfire)
	_refresh_focused_targets()


func _on_area_exited(area: Area2D) -> void:
	if area is Interactable:
		var interactable: Interactable = area as Interactable
		if _overlapping_interactables.has(interactable):
			_overlapping_interactables.erase(interactable)
		if _active_interactable == interactable:
			cancel_active_interaction()
		if interactable is InteractableClue and _overlapping_clues.has(interactable as InteractableClue):
			_overlapping_clues.erase(interactable as InteractableClue)
		elif interactable is InteractableReagent and _overlapping_reagents.has(interactable as InteractableReagent):
			_overlapping_reagents.erase(interactable as InteractableReagent)
		elif interactable is InteractableCampfire and _overlapping_campfires.has(interactable as InteractableCampfire):
			_overlapping_campfires.erase(interactable as InteractableCampfire)
	_refresh_focused_targets()
