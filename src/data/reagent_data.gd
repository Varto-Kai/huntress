class_name ReagentData
extends Resource
## Recurso de dados imutável que define um reagente alquímico coletável no mapa (SPEC-004: RF-001, RF-008, EC-005).

@export var reagent_id: StringName = &""
@export var display_name: String = "Reagente Desconhecido"
@export_multiline var description: String = ""
@export_range(1, 99, 1) var max_stack: int = 10
@export var greybox_color: Color = Color("#2ECC71")


func is_valid() -> bool:
	return reagent_id != &""


func sanitize() -> void:
	max_stack = maxi(1, max_stack)
	if display_name.strip_edges().is_empty():
		display_name = String(reagent_id) if reagent_id != &"" else "Reagente"
