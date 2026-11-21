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
@export var equipped_traps: Array[StringName] = []
@export var active_food_buff: StringName = &""
@export var applied_oil_charges: int = 0

var _reagent_catalog: Dictionary = {}
var _reagent_counts: Dictionary = {}
var _recipe_catalog: Array[OilRecipeData] = []
var _oil_charges: Dictionary = {
	CombatTypes.ElementOil.NONE: 0,
	CombatTypes.ElementOil.IGNIS_OIL: 0,
	CombatTypes.ElementOil.VITRIOL_ACID: 0,
}


func ensure_default_catalog() -> void:
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
			register_reagent(r_data)

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
			register_recipe(rec_data)


func register_reagent(reagent: ReagentData) -> bool:
	if reagent == null or not reagent.is_valid():
		push_warning("PreparationData: ReagentData nulo ou inválido ignorado (EC-005).")
		return false
	var copy: ReagentData = reagent.duplicate() as ReagentData
	copy.sanitize()
	_reagent_catalog[copy.reagent_id] = copy
	if not _reagent_counts.has(copy.reagent_id):
		_reagent_counts[copy.reagent_id] = 0
	return true


func register_recipe(recipe: OilRecipeData) -> bool:
	if recipe == null or not recipe.is_valid():
		push_warning("PreparationData: OilRecipeData nulo ou inválido ignorado (EC-005).")
		return false
	var copy: OilRecipeData = recipe.duplicate() as OilRecipeData
	copy.sanitize()
	for existing: OilRecipeData in _recipe_catalog:
		if existing.recipe_id == copy.recipe_id:
			return false
	_recipe_catalog.append(copy)
	return true


func get_registered_recipes() -> Array[OilRecipeData]:
	return _recipe_catalog.duplicate()


func get_registered_reagents() -> Array[ReagentData]:
	var list: Array[ReagentData] = []
	for key: Variant in _reagent_catalog.keys():
		var r: ReagentData = _reagent_catalog[key] as ReagentData
		if r != null:
			list.append(r)
	return list


func add_reagent(reagent: ReagentData, amount: int = 1) -> int:
	if reagent == null or not reagent.is_valid() or amount <= 0:
		push_warning("PreparationData: Tentativa inválida de adicionar reagente (EC-005).")
		return 0
	if not _reagent_catalog.has(reagent.reagent_id):
		register_reagent(reagent)
	var cat_entry: ReagentData = _reagent_catalog[reagent.reagent_id] as ReagentData
	var current: int = int(_reagent_counts.get(reagent.reagent_id, 0))
	var updated: int = clampi(current + amount, 0, cat_entry.max_stack)
	_reagent_counts[reagent.reagent_id] = updated
	reagent_count_changed.emit(reagent.reagent_id, updated)
	return updated


func get_reagent_count(reagent_id: StringName) -> int:
	return int(_reagent_counts.get(reagent_id, 0))


func get_reagent_display_name(reagent_id: StringName) -> String:
	if _reagent_catalog.has(reagent_id):
		var r: ReagentData = _reagent_catalog[reagent_id] as ReagentData
		return r.display_name
	return String(reagent_id)


func get_oil_charges(oil: CombatTypes.ElementOil) -> int:
	return int(_oil_charges.get(oil, 0))


func set_oil_charges(oil: CombatTypes.ElementOil, charges: int) -> int:
	if oil == CombatTypes.ElementOil.NONE:
		return 0
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
		if owned < needed:
			missing.append("%dx %s" % [needed - owned, get_reagent_display_name(r_id)])
	return missing


func can_craft_recipe(recipe: OilRecipeData) -> bool:
	if recipe == null or not recipe.is_valid():
		return false
	if get_oil_charges(recipe.result_oil) >= max_oil_charges:
		return false
	return get_missing_reagents(recipe).is_empty()


## Executa a síntese atômica de um Óleo debitando reagentes apenas se 100% válidos (EC-001).
func craft_oil(recipe: OilRecipeData) -> Dictionary:
	if recipe == null or not recipe.is_valid():
		var reason_inv: String = "Receita inválida."
		crafting_failed.emit(&"", reason_inv)
		return {"success": false, "reason": reason_inv}
	if get_oil_charges(recipe.result_oil) >= max_oil_charges:
		var reason_full: String = "Estoque de cargas deste Óleo já está cheio."
		crafting_failed.emit(recipe.recipe_id, reason_full)
		return {"success": false, "reason": reason_full}
	var missing: Array[String] = get_missing_reagents(recipe)
	if not missing.is_empty():
		var reason_missing: String = "Faltam reagentes: %s" % ", ".join(missing)
		crafting_failed.emit(recipe.recipe_id, reason_missing)
		return {
			"success": false,
			"reason": reason_missing,
		}

	var reqs: Dictionary = recipe.get_requirements_map()
	for r_id_var: Variant in reqs.keys():
		var r_id: StringName = r_id_var as StringName
		var needed: int = int(reqs[r_id])
		var updated_count: int = maxi(0, get_reagent_count(r_id) - needed)
		_reagent_counts[r_id] = updated_count
		reagent_count_changed.emit(r_id, updated_count)

	var prev_charges: int = get_oil_charges(recipe.result_oil)
	var new_charges: int = set_oil_charges(recipe.result_oil, prev_charges + recipe.charges_per_craft)
	oil_crafted.emit(recipe, new_charges)
	return {
		"success": true,
		"oil": recipe.result_oil,
		"charges_added": new_charges - prev_charges,
		"total_charges": new_charges,
	}


## Debita 1 carga do Óleo ativo após um acerto confirmado em combate (Q2 / EC-004).
func consume_oil_charge(oil: CombatTypes.ElementOil) -> Dictionary:
	if oil == CombatTypes.ElementOil.NONE:
		return {"consumed": false, "remaining": 0, "depleted": false}
	var current: int = get_oil_charges(oil)
	if current <= 0:
		active_oil_depleted.emit(oil)
		return {"consumed": false, "remaining": 0, "depleted": true}
	var next_val: int = maxi(0, current - 1)
	_oil_charges[oil] = next_val
	oil_charges_changed.emit(oil, next_val)
	if next_val == 0:
		active_oil_depleted.emit(oil)
	return {
		"consumed": true,
		"remaining": next_val,
		"depleted": next_val == 0,
	}


## Registra um descanso na Fogueira e incrementa silenciosamente a adaptação regional (Q4).
func register_campfire_rest() -> int:
	region_alert_level = clampi(region_alert_level + 1, 0, maxi(1, max_alert_level))
	campfire_rest_completed.emit(region_alert_level)
	return region_alert_level


## Calcula os multiplicadores de Adaptação Silenciosa da Presa para um nível de alerta (Q4).
func compute_adaptation_modifiers(alert_level: int, is_true_weakness: bool) -> Dictionary:
	var lvl: int = clampi(alert_level, 0, maxi(1, max_alert_level))
	var non_weak_mult: float = maxf(0.25, 1.0 - non_weakness_penalty_per_level * float(lvl))
	var dmg_scale: float = 1.0 if is_true_weakness else non_weak_mult
	var stg_scale: float = 1.0 if is_true_weakness else non_weak_mult
	var max_stagger_mult: float = 1.0 + stagger_scale_per_level * float(lvl)
	var hazard_interval_mult: float = maxf(0.50, 1.0 - hazard_speedup_per_level * float(lvl))
	return {
		"alert_level": lvl,
		"damage_scale": dmg_scale,
		"stagger_scale": stg_scale,
		"max_stagger_multiplier": max_stagger_mult,
		"hazard_interval_multiplier": hazard_interval_mult,
	}


## Valida uma preparação de óleo contra o nível de alerta regional.
func validate_preparation(recipe_id: StringName, alert_level: int = -1) -> Dictionary:
	var target_alert: int = region_alert_level if alert_level < 0 else clampi(alert_level, 0, max_alert_level)
	if recipe_id.is_empty():
		return {
			"valid": false,
			"reason": "ID de receita vazio.",
			"alert_level": target_alert,
			"has_charges": false,
		}
	var target_recipe: OilRecipeData = get_recipe_by_id(recipe_id)
	if target_recipe == null:
		return {
			"valid": false,
			"reason": "Receita não encontrada no catálogo: %s" % String(recipe_id),
			"alert_level": target_alert,
			"has_charges": false,
		}
	var charges: int = get_oil_charges(target_recipe.result_oil)
	return {
		"valid": charges > 0,
		"reason": "Pronto para combate" if charges > 0 else "Sem cargas disponíveis deste óleo.",
		"recipe": target_recipe,
		"oil": target_recipe.result_oil,
		"charges": charges,
		"alert_level": target_alert,
	}


## Aplica uma preparação de óleo ativo ao loadout.
func apply_preparation(recipe_id: StringName) -> bool:
	var val: Dictionary = validate_preparation(recipe_id)
	if not bool(val.get("valid", false)):
		return false
	active_oil_recipe_id = recipe_id
	applied_oil_charges = int(val.get("charges", 0))
	preparation_applied.emit(active_oil_recipe_id, applied_oil_charges)
	return true


## Busca uma receita registrada pelo seu ID único.
func get_recipe_by_id(recipe_id: StringName) -> OilRecipeData:
	for r: OilRecipeData in _recipe_catalog:
		if r != null and r.recipe_id == recipe_id:
			return r
	for r: OilRecipeData in known_recipes:
		if r != null and r.recipe_id == recipe_id:
			return r
	return null


func equip_trap(trap_id: StringName) -> bool:
	if trap_id.is_empty() or equipped_traps.has(trap_id):
		return false
	equipped_traps.append(trap_id)
	return true


func unequip_trap(trap_id: StringName) -> bool:
	var idx: int = equipped_traps.find(trap_id)
	if idx >= 0:
		equipped_traps.remove_at(idx)
		return true
	return false


func set_food_buff(buff_id: StringName) -> void:
	active_food_buff = buff_id


func clone() -> PreparationData:
	var copy: PreparationData = duplicate(true) as PreparationData
	copy._reagent_catalog = _reagent_catalog.duplicate()
	copy._reagent_counts = _reagent_counts.duplicate()
	copy._recipe_catalog = _recipe_catalog.duplicate()
	copy._oil_charges = _oil_charges.duplicate()
	copy.equipped_traps = equipped_traps.duplicate()
	return copy


func to_dict() -> Dictionary:
	var reagents_dict: Dictionary = {}
	for k: Variant in _reagent_counts.keys():
		reagents_dict[String(k)] = int(_reagent_counts[k])

	var charges_dict: Dictionary = {}
	for k: Variant in _oil_charges.keys():
		charges_dict[int(k)] = int(_oil_charges[k])

	var traps_array: Array = []
	for t: StringName in equipped_traps:
		traps_array.append(String(t))

	return {
		"max_oil_charges": max_oil_charges,
		"max_alert_level": max_alert_level,
		"non_weakness_penalty_per_level": non_weakness_penalty_per_level,
		"stagger_scale_per_level": stagger_scale_per_level,
		"hazard_speedup_per_level": hazard_speedup_per_level,
		"region_alert_level": region_alert_level,
		"active_oil_recipe_id": String(active_oil_recipe_id),
		"equipped_traps": traps_array,
		"active_food_buff": String(active_food_buff),
		"applied_oil_charges": applied_oil_charges,
		"reagent_counts": reagents_dict,
		"oil_charges": charges_dict,
	}


func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	if data.has("max_oil_charges"):
		max_oil_charges = int(data["max_oil_charges"])
	if data.has("max_alert_level"):
		max_alert_level = int(data["max_alert_level"])
	if data.has("non_weakness_penalty_per_level"):
		non_weakness_penalty_per_level = float(data["non_weakness_penalty_per_level"])
	if data.has("stagger_scale_per_level"):
		stagger_scale_per_level = float(data["stagger_scale_per_level"])
	if data.has("hazard_speedup_per_level"):
		hazard_speedup_per_level = float(data["hazard_speedup_per_level"])
	if data.has("region_alert_level"):
		region_alert_level = clampi(int(data["region_alert_level"]), 0, max_alert_level)
	if data.has("active_oil_recipe_id"):
		active_oil_recipe_id = StringName(String(data["active_oil_recipe_id"]))
	if data.has("active_food_buff"):
		active_food_buff = StringName(String(data["active_food_buff"]))
	if data.has("applied_oil_charges"):
		applied_oil_charges = int(data["applied_oil_charges"])
	if data.has("equipped_traps") and data["equipped_traps"] is Array:
		equipped_traps.clear()
		for t: Variant in data["equipped_traps"]:
			equipped_traps.append(StringName(String(t)))
	if data.has("reagent_counts") and data["reagent_counts"] is Dictionary:
		var r_map: Dictionary = data["reagent_counts"] as Dictionary
		for k: Variant in r_map.keys():
			_reagent_counts[StringName(String(k))] = int(r_map[k])
	if data.has("oil_charges") and data["oil_charges"] is Dictionary:
		var o_map: Dictionary = data["oil_charges"] as Dictionary
		for k: Variant in o_map.keys():
			_oil_charges[int(k)] = int(o_map[k])
