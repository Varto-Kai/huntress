class_name PreparationData
extends Resource
## Recurso serializável customizado para gestão de alquimia, loadout de preparo,
## cargas de óleos elementais e adaptação silenciosa da presa (SPEC-004 / Issue #26).

signal reagent_count_changed(reagent_id: StringName, new_count: int)
signal oil_charges_changed(oil: CombatTypes.ElementOil, new_charges: int)
signal oil_crafted(recipe: OilRecipeData, new_charges: int)
signal crafting_failed(recipe_id: StringName, reason: String)
signal active_oil_depleted(depleted_oil: CombatTypes.ElementOil)
signal campfire_rest_completed(new_hidden_alert_level: int)
signal preparation_applied(recipe_id: StringName, charges: int)

@export_group("Limits & Scaling")
@export_range(1, 50, 1) var max_oil_charges: int = 16
@export_range(1, 5, 1) var max_alert_level: int = 3
@export_range(0.05, 0.40, 0.05) var non_weakness_penalty_per_level: float = 0.20
@export_range(0.0, 0.50, 0.05) var stagger_scale_per_level: float = 0.15
@export_range(0.0, 0.30, 0.02) var hazard_speedup_per_level: float = 0.12

@export_group("Catalogs")
@export var known_reagents: Array[ReagentData] = []
@export var known_recipes: Array[OilRecipeData] = []

@export_group("Serializable Preparation Loadout")
@export var region_alert_level: int = 0
@export var active_oil_recipe_id: StringName = &""
@export var applied_oil_charges: int = 0

var _reagent_catalog: Dictionary[StringName, ReagentData] = {}
var _reagent_counts: Dictionary[StringName, int] = {}
var _recipe_catalog: Array[OilRecipeData] = []
var _oil_charges: Dictionary[int, int] = {
	CombatTypes.ElementOil.NONE: 0,
	CombatTypes.ElementOil.IGNIS_OIL: 0,
	CombatTypes.ElementOil.VITRIOL_ACID: 0,
}

func ensure_default_catalog() -> void:
	if known_reagents.is_empty():
		for p: String in ["res://src/data/reagent_alchemical_base.tres", "res://src/data/reagent_corrosive_bile.tres", "res://src/data/reagent_sulfur_powder.tres", "res://src/data/reagent_flammable_tallow.tres", "res://src/data/reagent_dry_ember.tres"]:
			var r: ReagentData = load(p) as ReagentData
			if r != null: known_reagents.append(r)
	for r_data: ReagentData in known_reagents:
		if r_data != null: register_reagent(r_data)
	if known_recipes.is_empty():
		for rp: String in ["res://src/data/recipe_vitriol_acid.tres", "res://src/data/recipe_ignis_oil.tres"]:
			var rec: OilRecipeData = load(rp) as OilRecipeData
			if rec != null: known_recipes.append(rec)
	for rec_data: OilRecipeData in known_recipes:
		if rec_data != null: register_recipe(rec_data)

func register_reagent(reagent: ReagentData) -> bool:
	if reagent == null or not reagent.is_valid():
		push_warning("PreparationData: ReagentData nulo ou inválido ignorado (EC-005).")
		return false
	var copy: ReagentData = reagent.duplicate() as ReagentData
	copy.sanitize()
	_reagent_catalog[copy.reagent_id] = copy
	if not _reagent_counts.has(copy.reagent_id): _reagent_counts[copy.reagent_id] = 0
	return true

func register_recipe(recipe: OilRecipeData) -> bool:
	if recipe == null or not recipe.is_valid():
		push_warning("PreparationData: OilRecipeData nulo ou inválido ignorado (EC-005).")
		return false
	var copy: OilRecipeData = recipe.duplicate() as OilRecipeData
	copy.sanitize()
	for existing: OilRecipeData in _recipe_catalog:
		if existing.recipe_id == copy.recipe_id: return false
	_recipe_catalog.append(copy)
	return true

func get_registered_recipes() -> Array[OilRecipeData]:
	return _recipe_catalog.duplicate()

func get_registered_reagents() -> Array[ReagentData]:
	var list: Array[ReagentData] = []
	for r: ReagentData in _reagent_catalog.values():
		if r != null: list.append(r)
	return list

func add_reagent(reagent: ReagentData, amount: int = 1) -> int:
	if reagent == null or not reagent.is_valid() or amount <= 0:
		push_warning("PreparationData: Tentativa inválida de adicionar reagente (EC-005).")
		return 0
	if not _reagent_catalog.has(reagent.reagent_id): register_reagent(reagent)
	var cat_entry: ReagentData = _reagent_catalog[reagent.reagent_id]
	var current: int = _reagent_counts.get(reagent.reagent_id, 0)
	var updated: int = clampi(current + amount, 0, cat_entry.max_stack)
	_reagent_counts[reagent.reagent_id] = updated
	reagent_count_changed.emit(reagent.reagent_id, updated)
	return updated

func get_reagent_count(reagent_id: StringName) -> int:
	return _reagent_counts.get(reagent_id, 0)

func get_reagent_display_name(reagent_id: StringName) -> String:
	return _reagent_catalog[reagent_id].display_name if _reagent_catalog.has(reagent_id) else String(reagent_id)

func get_oil_charges(oil: CombatTypes.ElementOil) -> int:
	return _oil_charges.get(oil, 0)

func set_oil_charges(oil: CombatTypes.ElementOil, charges: int) -> int:
	if oil == CombatTypes.ElementOil.NONE: return 0
	var clamped: int = clampi(charges, 0, maxi(1, max_oil_charges))
	_oil_charges[oil] = clamped
	oil_charges_changed.emit(oil, clamped)
	return clamped

func get_missing_reagents(recipe: OilRecipeData) -> Array[String]:
	var missing: Array[String] = []
	if recipe == null or not recipe.is_valid():
		missing.append("Receita inválida")
		return missing
	var reqs: Dictionary = recipe.get_requirements_map()
	for r_id_var: Variant in reqs.keys():
		var r_id: StringName = r_id_var as StringName
		var needed: int = int(reqs[r_id])
		var owned: int = get_reagent_count(r_id)
		if owned < needed: missing.append("%dx %s" % [needed - owned, get_reagent_display_name(r_id)])
	return missing

func can_craft_recipe(recipe: OilRecipeData) -> bool:
	if recipe == null or not recipe.is_valid() or get_oil_charges(recipe.result_oil) >= max_oil_charges:
		return false
	return get_missing_reagents(recipe).is_empty()

func craft_oil(recipe: OilRecipeData) -> Dictionary:
	if recipe == null or not recipe.is_valid():
		crafting_failed.emit(&"", "Receita inválida.")
		return {"success": false, "reason": "Receita inválida."}
	if get_oil_charges(recipe.result_oil) >= max_oil_charges:
		crafting_failed.emit(recipe.recipe_id, "Estoque cheio.")
		return {"success": false, "reason": "Estoque cheio."}
	var missing: Array[String] = get_missing_reagents(recipe)
	if not missing.is_empty():
		var reason_missing: String = "Faltam reagentes: %s" % ", ".join(missing)
		crafting_failed.emit(recipe.recipe_id, reason_missing)
		return {"success": false, "reason": reason_missing}
	var reqs: Dictionary = recipe.get_requirements_map()
	for r_id_var: Variant in reqs.keys():
		var r_id: StringName = r_id_var as StringName
		var updated_count: int = maxi(0, get_reagent_count(r_id) - int(reqs[r_id]))
		_reagent_counts[r_id] = updated_count
		reagent_count_changed.emit(r_id, updated_count)
	var prev_charges: int = get_oil_charges(recipe.result_oil)
	var new_charges: int = set_oil_charges(recipe.result_oil, prev_charges + recipe.charges_per_craft)
	oil_crafted.emit(recipe, new_charges)
	return {"success": true, "oil": recipe.result_oil, "charges_added": new_charges - prev_charges, "total_charges": new_charges}

func consume_oil_charge(oil: CombatTypes.ElementOil) -> Dictionary:
	if oil == CombatTypes.ElementOil.NONE: return {"consumed": false, "remaining": 0, "depleted": false}
	var current: int = get_oil_charges(oil)
	if current <= 0:
		active_oil_depleted.emit(oil)
		return {"consumed": false, "remaining": 0, "depleted": true}
	var next_val: int = maxi(0, current - 1)
	_oil_charges[oil] = next_val
	oil_charges_changed.emit(oil, next_val)
	if next_val == 0: active_oil_depleted.emit(oil)
	return {"consumed": true, "remaining": next_val, "depleted": next_val == 0}

func register_campfire_rest() -> int:
	region_alert_level = clampi(region_alert_level + 1, 0, maxi(1, max_alert_level))
	campfire_rest_completed.emit(region_alert_level)
	return region_alert_level

func compute_adaptation_modifiers(alert_level: int, is_true_weakness: bool) -> Dictionary:
	var lvl: int = clampi(alert_level, 0, maxi(1, max_alert_level))
	var non_weak_mult: float = maxf(0.25, 1.0 - non_weakness_penalty_per_level * float(lvl))
	var scale: float = 1.0 if is_true_weakness else non_weak_mult
	return {
		"alert_level": lvl, "damage_scale": scale, "stagger_scale": scale,
		"max_stagger_multiplier": 1.0 + stagger_scale_per_level * float(lvl),
		"hazard_interval_multiplier": maxf(0.50, 1.0 - hazard_speedup_per_level * float(lvl)),
	}

func validate_preparation(recipe_id: StringName, alert_level: int = -1) -> Dictionary:
	var target_alert: int = region_alert_level if alert_level < 0 else clampi(alert_level, 0, max_alert_level)
	if recipe_id.is_empty():
		return {"valid": false, "reason": "ID de receita vazio.", "alert_level": target_alert, "has_charges": false}
	var target_recipe: OilRecipeData = get_recipe_by_id(recipe_id)
	if target_recipe == null:
		return {"valid": false, "reason": "Receita não encontrada.", "alert_level": target_alert, "has_charges": false}
	var charges: int = get_oil_charges(target_recipe.result_oil)
	return {
		"valid": charges > 0, "reason": "Pronto para combate" if charges > 0 else "Sem cargas disponíveis.",
		"recipe": target_recipe, "oil": target_recipe.result_oil, "charges": charges, "alert_level": target_alert,
	}

func apply_preparation(recipe_id: StringName) -> bool:
	var val: Dictionary = validate_preparation(recipe_id)
	if not bool(val.get("valid", false)): return false
	active_oil_recipe_id = recipe_id
	applied_oil_charges = int(val.get("charges", 0))
	preparation_applied.emit(active_oil_recipe_id, applied_oil_charges)
	return true

func get_recipe_by_id(recipe_id: StringName) -> OilRecipeData:
	for r: OilRecipeData in _recipe_catalog:
		if r != null and r.recipe_id == recipe_id: return r
	for r: OilRecipeData in known_recipes:
		if r != null and r.recipe_id == recipe_id: return r
	return null

func clone() -> PreparationData:
	var copy: PreparationData = duplicate(true) as PreparationData
	copy._reagent_catalog = _reagent_catalog.duplicate()
	copy._reagent_counts = _reagent_counts.duplicate()
	copy._recipe_catalog = _recipe_catalog.duplicate()
	copy._oil_charges = _oil_charges.duplicate()
	return copy

func to_dict() -> Dictionary:
	var reagents_dict: Dictionary = {}
	for k: StringName in _reagent_counts: reagents_dict[String(k)] = _reagent_counts[k]
	var charges_dict: Dictionary = {}
	for k: int in _oil_charges: charges_dict[k] = _oil_charges[k]
	return {
		"max_oil_charges": max_oil_charges, "max_alert_level": max_alert_level,
		"non_weakness_penalty_per_level": non_weakness_penalty_per_level,
		"stagger_scale_per_level": stagger_scale_per_level,
		"hazard_speedup_per_level": hazard_speedup_per_level,
		"region_alert_level": region_alert_level,
		"active_oil_recipe_id": String(active_oil_recipe_id),
		"applied_oil_charges": applied_oil_charges,
		"reagent_counts": reagents_dict, "oil_charges": charges_dict,
	}

func from_dict(data: Dictionary) -> void:
	if data.is_empty(): return
	if data.has("max_oil_charges"): max_oil_charges = int(data["max_oil_charges"])
	if data.has("max_alert_level"): max_alert_level = int(data["max_alert_level"])
	if data.has("non_weakness_penalty_per_level"): non_weakness_penalty_per_level = float(data["non_weakness_penalty_per_level"])
	if data.has("stagger_scale_per_level"): stagger_scale_per_level = float(data["stagger_scale_per_level"])
	if data.has("hazard_speedup_per_level"): hazard_speedup_per_level = float(data["hazard_speedup_per_level"])
	if data.has("region_alert_level"): region_alert_level = clampi(int(data["region_alert_level"]), 0, max_alert_level)
	if data.has("active_oil_recipe_id"): active_oil_recipe_id = StringName(String(data["active_oil_recipe_id"]))
	if data.has("applied_oil_charges"): applied_oil_charges = int(data["applied_oil_charges"])
	if data.has("reagent_counts") and data["reagent_counts"] is Dictionary:
		var r_map: Dictionary = data["reagent_counts"] as Dictionary
		for k: Variant in r_map.keys(): _reagent_counts[StringName(String(k))] = int(r_map[k])
	if data.has("oil_charges") and data["oil_charges"] is Dictionary:
		var o_map: Dictionary = data["oil_charges"] as Dictionary
		for k: Variant in o_map.keys(): _oil_charges[int(k)] = int(o_map[k])
