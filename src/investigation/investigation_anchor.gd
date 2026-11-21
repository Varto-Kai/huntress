class_name InvestigationAnchor
extends Interactable
## Ponto de ancoragem para investigação física no mundo (Issue #25 & SPEC-003).

func _init() -> void:
	interaction_type = InteractionType.CLUE
	base_priority = 100
