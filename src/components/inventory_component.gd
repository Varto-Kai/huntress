class_name InventoryComponent
extends Node
## Componente acoplado à Caçadora que encapsula o PreparationManager e emite sinais
## desacoplados para reagentes, síntese de Óleos, cargas e descanso na Fogueira (SPEC-004: RF-002, RF-005).

signal reagent_count_changed(reagent_id: StringName, new_count: int)
signal oil_charges_changed(oil: CombatTypes.ElementOil, new_charges: int)
signal oil_crafted(recipe: OilRecipeData, new_charges: int)
signal crafting_failed(recipe_id: StringName, reason: String)
signal active_oil_depleted(depleted_oil: CombatTypes.ElementOil)
signal campfire_rest_completed(new_hidden_alert_level: int)

@export var known_reagents: Array[ReagentData] = []
@export var known_recipes: Array[OilRecipeData] = []
@export_range(1, 50, 1) var max_oil_charges: int = 16
@export_range(1, 5, 1) var max_alert_level: int = 3
@export_range(0.05, 0.40, 0.05) var non_weakness_penalty_per_level: float = 0.20
@export_range(0.0, 0.50, 0.05) var stagger_scale_per_level: float = 0.15
@export_range(0.0, 0.30, 0.02) var hazard_speedup_per_level: float = 0.12

var manager: PreparationManager = PreparationManager.new()


func _ready() -> void:
	_sync_parameters()
	ensure_default_catalog()


func _sync_parameters() -> void:
	manager.max_oil_charges = max_oil_charges
	manager.max_alert_level = max_alert_level
	manager.non_weakness_penalty_per_level = non_weakness_penalty_per_level
	manager.stagger_scale_per_level = stagger_scale_per_level
	manager.hazard_speedup_per_level = hazard_speedup_per_level


func ensure_default_catalog() -> void:
	_sync_parameters()
	if known_reagents.is_empty():
		var default_reagent_paths: Array[String] = [
			"res://src/data/reagent_alchemical_base.tres",
			"res://src/data/reagent_corrosive_bile.tres",
			"res://src/data/reagent_sulfur_powder.tres",
			"res://src/data/reagent_flammable_tallow.tres",
			"res://src/data/reagent_dry_ember.tres",
		]
		for p: String in default_reagent_paths:
			var r: ReagentData = load(p) as ReagentData
			if r != null:
				known_reagents.append(r)

	for r_data: ReagentData in known_reagents:
		if r_data != null:
			manager.register_reagent(r_data)

	if known_recipes.is_empty():
		var default_recipe_paths: Array[String] = [
			"res://src/data/recipe_vitriol_acid.tres",
			"res://src/data/recipe_ignis_oil.tres",
		]
		for rp: String in default_recipe_paths:
			var rec: OilRecipeData = load(rp) as OilRecipeData
			if rec != null:
				known_recipes.append(rec)

	for rec_data: OilRecipeData in known_recipes:
		if rec_data != null:
			manager.register_recipe(rec_data)


func collect_reagent_from_world(reagent_data: ReagentData, amount: int = 1) -> int:
	ensure_default_catalog()
	if reagent_data == null or not reagent_data.is_valid():
		return 0
	var new_count: int = manager.add_reagent(reagent_data, amount)
	reagent_count_changed.emit(reagent_data.reagent_id, new_count)
	return new_count


func get_reagent_count(reagent_id: StringName) -> int:
	return manager.get_reagent_count(reagent_id)


func get_oil_charges(oil: CombatTypes.ElementOil) -> int:
	return manager.get_oil_charges(oil)


func has_oil_charges(oil: CombatTypes.ElementOil) -> bool:
	if oil == CombatTypes.ElementOil.NONE:
		return true
	return manager.get_oil_charges(oil) > 0


func try_craft_recipe(recipe: OilRecipeData) -> bool:
	ensure_default_catalog()
	var result: Dictionary = manager.craft_oil(recipe)
	if not bool(result.get("success", false)):
		var rec_id: StringName = recipe.recipe_id if recipe != null else &""
		crafting_failed.emit(rec_id, String(result.get("reason", "Falha na síntese.")))
		return false

	var reqs: Dictionary = recipe.get_requirements_map()
	for r_id_var: Variant in reqs.keys():
		var r_id: StringName = r_id_var as StringName
		reagent_count_changed.emit(r_id, manager.get_reagent_count(r_id))

	var new_charges: int = int(result.get("total_charges", 0))
	oil_charges_changed.emit(recipe.result_oil, new_charges)
	oil_crafted.emit(recipe, new_charges)
	return true


func consume_charge_for_oil(oil: CombatTypes.ElementOil) -> bool:
	if oil == CombatTypes.ElementOil.NONE:
		return false
	var res: Dictionary = manager.consume_oil_charge(oil)
	if bool(res.get("consumed", false)):
		var remaining: int = int(res.get("remaining", 0))
		oil_charges_changed.emit(oil, remaining)
		if bool(res.get("depleted", false)):
			active_oil_depleted.emit(oil)
		return true
	if bool(res.get("depleted", false)):
		active_oil_depleted.emit(oil)
	return false


func trigger_campfire_rest() -> int:
	var new_alert: int = manager.register_campfire_rest()
	campfire_rest_completed.emit(new_alert)
	return new_alert


func get_hidden_alert_level() -> int:
	return manager.region_alert_level
