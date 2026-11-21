class_name Interactable
extends Area2D
## Classe base abstrata e polimórfica para entidades interagíveis do mundo (Issue #25 & SPEC-003/004).
## Unifica pistas, reagentes, fogueiras, NPCs e itens com scoring composto de prioridade e distância.

enum InteractionType {
	CLUE,
	REAGENT,
	CAMPFIRE,
	NPC,
	ITEM,
}

signal interaction_started(interactor: Node2D)
signal interaction_progress_changed(ratio: float)
signal interaction_completed(interactor: Node2D, result: Variant)
signal interaction_cancelled(interactor: Node2D)
signal focus_changed(is_focused: bool)

@export var interaction_type: InteractionType = InteractionType.ITEM
@export var base_priority: int = 10
@export_range(0.0, 5.0, 0.05, "suffix:s") var hold_duration: float = 0.0

var is_focused: bool = false

var interaction_priority: int:
	get:
		return base_priority
	set(value):
		base_priority = value


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	monitorable = true


func can_interact(_interactor: Node2D) -> bool:
	return true


func interact(_interactor: Node2D) -> void:
	pass


func cancel_interaction(_interactor: Node2D) -> void:
	pass


func get_interaction_prompt() -> String:
	return ""


func get_effective_priority() -> int:
	return base_priority


func get_hold_duration() -> float:
	return maxf(0.0, hold_duration)


func set_focused(focused: bool) -> void:
	if is_focused != focused:
		is_focused = focused
		focus_changed.emit(focused)


func set_interaction_progress(_ratio: float) -> void:
	pass


func start_interaction(interactor: Node2D) -> void:
	interaction_started.emit(interactor)


func complete_interaction(interactor: Node2D) -> Variant:
	interact(interactor)
	return null
