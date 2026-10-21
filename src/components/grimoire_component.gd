class_name GrimoireComponent
extends Node
## Componente de cena que encapsula o GrimoireTracker e emite sinais desacoplados
## para a UI do Grimório e para o HUD dos monstros (SPEC-003: RF-003, RF-005).

signal clue_discovered(clue_data: ClueData, is_new: bool)
signal clue_discard_toggled(clue_id: StringName, is_discarded: bool)
signal entry_updated(monster_id: StringName, resolved_state: Dictionary)
signal monster_research_completed(monster_id: StringName)

@export var initial_entries: Array[MonsterGrimoireEntryData] = []

var tracker: GrimoireTracker = GrimoireTracker.new()
var _announced_completions: Dictionary = {}


func _ready() -> void:
	if initial_entries.is_empty():
		var carapace: MonsterGrimoireEntryData = load("res://src/data/entry_armored_carapace.tres") as MonsterGrimoireEntryData
		var beast: MonsterGrimoireEntryData = load("res://src/data/entry_agile_beast.tres") as MonsterGrimoireEntryData
		if carapace != null:
			initial_entries.append(carapace)
		if beast != null:
			initial_entries.append(beast)

	for entry: MonsterGrimoireEntryData in initial_entries:
		if entry != null:
			tracker.register_entry(entry)


func register_clue_from_world(clue_data: ClueData) -> bool:
	if clue_data == null or not clue_data.is_valid():
		return false
	var is_new: bool = tracker.discover_clue(clue_data)
	clue_discovered.emit(clue_data, is_new)
	_emit_entry_state(clue_data.monster_id)
	return is_new


func toggle_clue_discard(clue_id: StringName, monster_id: StringName) -> bool:
	if not tracker.is_clue_discovered(clue_id):
		return false
	var is_discarded: bool = tracker.toggle_clue_discarded(clue_id)
	clue_discard_toggled.emit(clue_id, is_discarded)
	_emit_entry_state(monster_id)
	return is_discarded


func get_monster_state(monster_id: StringName) -> Dictionary:
	return tracker.resolve_monster_entry(monster_id)


func _emit_entry_state(monster_id: StringName) -> void:
	var state: Dictionary = tracker.resolve_monster_entry(monster_id)
	entry_updated.emit(monster_id, state)
	var solved: bool = bool(state.get("deduction_solved", false))
	if solved and not _announced_completions.has(monster_id):
		_announced_completions[monster_id] = true
		monster_research_completed.emit(monster_id)
	elif not solved and _announced_completions.has(monster_id):
		_announced_completions.erase(monster_id)
