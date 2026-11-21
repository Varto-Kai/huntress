class_name InventoryComponent
extends Node
## Componente de inventário da Caçadora conectado ao PreparationData Resource (SPEC-004 / Issue #26).
## Desacopla parâmetros do Inspector via Resource e sincroniza sinais de alquimia e cargas de óleos.

signal reagent_count_changed(reagent_id: StringName, new_count: int)
signal oil_charges_changed(oil: CombatTypes.ElementOil, new_charges: int)
signal oil_crafted(recipe: OilRecipeData, new_charges: int)
signal crafting_failed(recipe_id: StringName, reason: String)
signal active_oil_depleted(depleted_oil: CombatTypes.ElementOil)
signal campfire_rest_completed(new_hidden_alert_level: int)

@export var preparation_data: PreparationData = null

var manager: PreparationData:
	get:
		if preparation_data == null:
			ensure_default_catalog()
		return preparation_data
	set(val):
		preparation_data = val
		_connect_preparation_signals()

var max_oil_charges: int:
	get:
		if preparation_data == null:
			ensure_default_catalog()
		return preparation_data.max_oil_charges
	set(val):
		if preparation_data == null:
			ensure_default_catalog()
		preparation_data.max_oil_charges = val

var known_reagents: Array[ReagentData]:
	get:
		if preparation_data == null:
			ensure_default_catalog()
		return preparation_data.known_reagents
	set(val):
		if preparation_data == null:
			ensure_default_catalog()
		preparation_data.known_reagents = val

var known_recipes: Array[OilRecipeData]:
	get:
		if preparation_data == null:
			ensure_default_catalog()
		return preparation_data.known_recipes
	set(val):
		if preparation_data == null:
			ensure_default_catalog()
		preparation_data.known_recipes = val

var _is_isolated: bool = false


func _ready() -> void:
	ensure_default_catalog()


func ensure_default_catalog() -> void:
	if preparation_data == null:
		preparation_data = PreparationData.new()
		_is_isolated = true
	elif not _is_isolated:
		preparation_data = preparation_data.clone() if preparation_data.has_method("clone") else preparation_data.duplicate() as PreparationData
		_is_isolated = true

	_connect_preparation_signals()
	preparation_data.ensure_default_catalog()


func _connect_preparation_signals() -> void:
	if preparation_data == null:
		return
	if not preparation_data.reagent_count_changed.is_connected(_on_pdata_reagent_count_changed):
		preparation_data.reagent_count_changed.connect(_on_pdata_reagent_count_changed)
	if not preparation_data.oil_charges_changed.is_connected(_on_pdata_oil_charges_changed):
		preparation_data.oil_charges_changed.connect(_on_pdata_oil_charges_changed)
	if not preparation_data.oil_crafted.is_connected(_on_pdata_oil_crafted):
		preparation_data.oil_crafted.connect(_on_pdata_oil_crafted)
	if not preparation_data.crafting_failed.is_connected(_on_pdata_crafting_failed):
		preparation_data.crafting_failed.connect(_on_pdata_crafting_failed)
	if not preparation_data.active_oil_depleted.is_connected(_on_pdata_active_oil_depleted):
		preparation_data.active_oil_depleted.connect(_on_pdata_active_oil_depleted)
	if not preparation_data.campfire_rest_completed.is_connected(_on_pdata_campfire_rest_completed):
		preparation_data.campfire_rest_completed.connect(_on_pdata_campfire_rest_completed)


func _on_pdata_reagent_count_changed(reagent_id: StringName, new_count: int) -> void:
	reagent_count_changed.emit(reagent_id, new_count)


func _on_pdata_oil_charges_changed(oil: CombatTypes.ElementOil, new_charges: int) -> void:
	oil_charges_changed.emit(oil, new_charges)


func _on_pdata_oil_crafted(recipe: OilRecipeData, new_charges: int) -> void:
	oil_crafted.emit(recipe, new_charges)


func _on_pdata_crafting_failed(recipe_id: StringName, reason: String) -> void:
	crafting_failed.emit(recipe_id, reason)


func _on_pdata_active_oil_depleted(depleted_oil: CombatTypes.ElementOil) -> void:
	active_oil_depleted.emit(depleted_oil)


func _on_pdata_campfire_rest_completed(new_hidden_alert_level: int) -> void:
	campfire_rest_completed.emit(new_hidden_alert_level)


func collect_reagent_from_world(reagent_data: ReagentData, amount: int = 1) -> int:
	ensure_default_catalog()
	if reagent_data == null or not reagent_data.is_valid():
		return 0
	return preparation_data.add_reagent(reagent_data, amount)


func get_reagent_count(reagent_id: StringName) -> int:
	ensure_default_catalog()
	return preparation_data.get_reagent_count(reagent_id)


func get_oil_charges(oil: CombatTypes.ElementOil) -> int:
	ensure_default_catalog()
	return preparation_data.get_oil_charges(oil)


func has_oil_charges(oil: CombatTypes.ElementOil) -> bool:
	if oil == CombatTypes.ElementOil.NONE:
		return true
	ensure_default_catalog()
	return preparation_data.get_oil_charges(oil) > 0


func try_craft_recipe(recipe: OilRecipeData) -> bool:
	ensure_default_catalog()
	var result: Dictionary = preparation_data.craft_oil(recipe)
	return bool(result.get("success", false))


func consume_charge_for_oil(oil: CombatTypes.ElementOil) -> bool:
	if oil == CombatTypes.ElementOil.NONE:
		return false
	ensure_default_catalog()
	var res: Dictionary = preparation_data.consume_oil_charge(oil)
	return bool(res.get("consumed", false))


func trigger_campfire_rest() -> int:
	ensure_default_catalog()
	return preparation_data.register_campfire_rest()


func get_hidden_alert_level() -> int:
	ensure_default_catalog()
	return preparation_data.region_alert_level
