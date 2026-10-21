class_name MonsterGrimoireEntryData
extends Resource
## Ficha de uma criatura no Grimório, agrupando metadados, perfil de defesa (SPEC-002)
## e o catálogo de pistas autênticas e falsas da caçada (SPEC-003: RF-004, RF-005, RF-008).

@export var monster_id: StringName = &""
@export var display_name: String = "Criatura Desconhecida"
@export var subtitle: String = "Ameaça Não Classificada"
@export var defense_profile: DefenseProfileData
@export var available_clues: Array[ClueData] = []
@export var locked_placeholder_text: String = "???"


func is_valid() -> bool:
	return monster_id != &""


func sanitize() -> void:
	if locked_placeholder_text.strip_edges().is_empty():
		locked_placeholder_text = "???"
	for clue: ClueData in available_clues:
		if clue != null:
			clue.sanitize()
