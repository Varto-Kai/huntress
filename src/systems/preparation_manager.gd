class_name PreparationManager
extends RefCounted
## Motor puro e determinístico para gestão de reagentes, síntese atômica de Óleos (EC-001),
## consumo de cargas por golpe conectado (Q2 / EC-004) e Adaptação Silenciosa da Presa (Q4).

var max_oil_charges: int = 16
var max_alert_level: int = 3
var non_weakness_penalty_per_level: float = 0.20
var stagger_scale_per_level: float = 0.15
var hazard_speedup_per_level: float = 0.12
var region_alert_level: int = 0

var _reagent_catalog: Dictionary = {}
var _reagent_counts: Dictionary = {}
var _recipe_catalog: Array[OilRecipeData] = []
var _oil_charges: Dictionary = {
	CombatTypes.ElementOil.NONE: 0,
	CombatTypes.ElementOil.IGNIS_OIL: 0,
	CombatTypes.ElementOil.VITRIOL_ACID: 0,
}


func register_reagent(reagent: ReagentData) -> bool:
	if reagent == null or not reagent.is_valid():
		push_warning("PreparationManager: ReagentData nulo ou inválido ignorado (EC-005).")
		return false
	var copy: ReagentData = reagent.duplicate() as ReagentData
	copy.sanitize()
	_reagent_catalog[copy.reagent_id] = copy
	if not _reagent_counts.has(copy.reagent_id):
		_reagent_counts[copy.reagent_id] = 0
	return true


func register_recipe(recipe: OilRecipeData) -> bool:
	if recipe == null or not recipe.is_valid():
		push_warning("PreparationManager: OilRecipeData nulo ou inválido ignorado (EC-005).")
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
		push_warning("PreparationManager: Tentativa inválida de adicionar reagente (EC-005).")
		return 0
	if not _reagent_catalog.has(reagent.reagent_id):
		register_reagent(reagent)
	var cat_entry: ReagentData = _reagent_catalog[reagent.reagent_id] as ReagentData
	var current: int = int(_reagent_counts.get(reagent.reagent_id, 0))
	var updated: int = clampi(current + amount, 0, cat_entry.max_stack)
	_reagent_counts[reagent.reagent_id] = updated
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
		return {"success": false, "reason": "Receita inválida."}
	if get_oil_charges(recipe.result_oil) >= max_oil_charges:
		return {"success": false, "reason": "Estoque de cargas deste Óleo já está cheio."}
	var missing: Array[String] = get_missing_reagents(recipe)
	if not missing.is_empty():
		return {
			"success": false,
			"reason": "Faltam reagentes: %s" % ", ".join(missing),
		}

	var reqs: Dictionary = recipe.get_requirements_map()
	for r_id_var: Variant in reqs.keys():
		var r_id: StringName = r_id_var as StringName
		var needed: int = int(reqs[r_id])
		_reagent_counts[r_id] = maxi(0, get_reagent_count(r_id) - needed)

	var prev_charges: int = get_oil_charges(recipe.result_oil)
	var new_charges: int = set_oil_charges(recipe.result_oil, prev_charges + recipe.charges_per_craft)
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
		return {"consumed": false, "remaining": 0, "depleted": true}
	var next_val: int = maxi(0, current - 1)
	_oil_charges[oil] = next_val
	return {
		"consumed": true,
		"remaining": next_val,
		"depleted": next_val == 0,
	}


## Registra um descanso na Fogueira e incrementa silenciosamente a adaptação regional (Q4).
func register_campfire_rest() -> int:
	region_alert_level = clampi(region_alert_level + 1, 0, maxi(1, max_alert_level))
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
