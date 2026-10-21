class_name OilRecipeData
extends Resource
## Recurso de dados imutável que define a fórmula alquímica de um Óleo de Caça (SPEC-004: RF-001, RF-005, EC-005).

@export var recipe_id: StringName = &""
@export var display_name: String = "Fórmula Alquímica"
@export_multiline var description: String = ""
@export var result_oil: CombatTypes.ElementOil = CombatTypes.ElementOil.NONE
@export var required_reagent_ids: Array[StringName] = []
@export var required_reagent_amounts: Array[int] = []
@export_range(1, 30, 1) var charges_per_craft: int = 8


func is_valid() -> bool:
	if recipe_id == &"" or result_oil == CombatTypes.ElementOil.NONE:
		return false
	if required_reagent_ids.is_empty():
		return false
	return required_reagent_ids.size() == required_reagent_amounts.size()


func sanitize() -> void:
	charges_per_craft = maxi(1, charges_per_craft)
	if display_name.strip_edges().is_empty():
		display_name = CombatTypes.get_oil_display_name(result_oil)
	for i: int in range(required_reagent_amounts.size()):
		required_reagent_amounts[i] = maxi(1, required_reagent_amounts[i])


func get_requirements_map() -> Dictionary:
	var reqs: Dictionary = {}
	var count: int = mini(required_reagent_ids.size(), required_reagent_amounts.size())
	for i: int in range(count):
		var r_id: StringName = required_reagent_ids[i]
		if r_id == &"":
			continue
		var amt: int = maxi(1, required_reagent_amounts[i])
		reqs[r_id] = int(reqs.get(r_id, 0)) + amt
	return reqs
