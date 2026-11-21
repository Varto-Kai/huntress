class_name TestPreparationManager
extends RefCounted
## Suíte de testes unitários para PreparationManager e InventoryComponent (SPEC-004: RF-001, RF-002, RF-005, RF-008, EC-001, EC-004, EC-005, SC-001).

var _results: Array[String] = []
var _failures: Array[String] = []


func run_all() -> Dictionary:
	_results.clear()
	_failures.clear()

	test_reagent_accumulation_and_max_stack_rf001()
	test_atomic_crafting_rejection_on_missing_reagents_ec001()
	test_successful_crafting_and_hit_connected_charge_depletion_q2_ec004()
	test_silent_prey_adaptation_scaling_and_true_weakness_preservation_q4()
	test_defensive_null_and_invalid_resource_handling_ec005()
	test_preparation_data_isolation_and_cloning()
	test_preparation_data_round_trip_serialization()
	test_preparation_validation_and_application_against_alert_level()

	return {
		"passed": _results.size(),
		"failed": _failures.size(),
		"results": _results,
		"failures": _failures,
	}


func _assert_true(condition: bool, label: String) -> void:
	if condition:
		_results.append("PASS: %s" % label)
	else:
		_failures.append("FAIL: %s" % label)


func test_reagent_accumulation_and_max_stack_rf001() -> void:
	var mgr: PreparationManager = PreparationManager.new()
	var base: ReagentData = load("res://src/data/reagent_alchemical_base.tres") as ReagentData
	mgr.register_reagent(base)

	var c1: int = mgr.add_reagent(base, 3)
	var c2: int = mgr.add_reagent(base, 50)
	_assert_true(
		c1 == 3 and c2 == base.max_stack,
		"RF-001/RF-002: PreparationManager acumula reagentes por ID e respeita o limite max_stack"
	)


func test_atomic_crafting_rejection_on_missing_reagents_ec001() -> void:
	var mgr: PreparationManager = PreparationManager.new()
	var base: ReagentData = load("res://src/data/reagent_alchemical_base.tres") as ReagentData
	var bile: ReagentData = load("res://src/data/reagent_corrosive_bile.tres") as ReagentData
	var recipe_acid: OilRecipeData = load("res://src/data/recipe_vitriol_acid.tres") as OilRecipeData

	# Adiciona apenas 2 dos 3 ingredientes necessários (falta sulfur_powder)
	mgr.add_reagent(base, 1)
	mgr.add_reagent(bile, 1)

	var res: Dictionary = mgr.craft_oil(recipe_acid)
	_assert_true(
		not bool(res.get("success", true))
		and mgr.get_reagent_count(&"alchemical_base") == 1
		and mgr.get_reagent_count(&"corrosive_bile") == 1
		and mgr.get_oil_charges(CombatTypes.ElementOil.VITRIOL_ACID) == 0,
		"EC-001: Tentativa de síntese sem todos os reagentes é rejeitada atomicamente sem debitar materiais parciais"
	)


func test_successful_crafting_and_hit_connected_charge_depletion_q2_ec004() -> void:
	var inv: InventoryComponent = InventoryComponent.new()
	inv.ensure_default_catalog()

	var base: ReagentData = load("res://src/data/reagent_alchemical_base.tres") as ReagentData
	var bile: ReagentData = load("res://src/data/reagent_corrosive_bile.tres") as ReagentData
	var sulfur: ReagentData = load("res://src/data/reagent_sulfur_powder.tres") as ReagentData
	var recipe_acid: OilRecipeData = load("res://src/data/recipe_vitriol_acid.tres") as OilRecipeData

	inv.collect_reagent_from_world(base, 1)
	inv.collect_reagent_from_world(bile, 1)
	inv.collect_reagent_from_world(sulfur, 1)

	var crafted: bool = inv.try_craft_recipe(recipe_acid)
	_assert_true(
		crafted
		and inv.get_oil_charges(CombatTypes.ElementOil.VITRIOL_ACID) == 8
		and inv.get_reagent_count(&"alchemical_base") == 0,
		"RF-002/RF-005: Síntese debita os 3 reagentes e concede exatamente 8 cargas de Vitríolo Ácido"
	)

	var depleted_events: Array[int] = []
	inv.active_oil_depleted.connect(func(oil: CombatTypes.ElementOil) -> void:
		depleted_events.append(int(oil))
	)

	for i: int in range(7):
		inv.consume_charge_for_oil(CombatTypes.ElementOil.VITRIOL_ACID)
	_assert_true(
		inv.get_oil_charges(CombatTypes.ElementOil.VITRIOL_ACID) == 1 and depleted_events.is_empty(),
		"Q2/RF-005: Após 7 golpes conectados restam 1 carga ativa e o óleo ainda não esgotou"
	)

	inv.consume_charge_for_oil(CombatTypes.ElementOil.VITRIOL_ACID)
	_assert_true(
		inv.get_oil_charges(CombatTypes.ElementOil.VITRIOL_ACID) == 0 and depleted_events.size() == 1,
		"EC-004: O 8º golpe conectado zera as cargas e emite active_oil_depleted imediatamente"
	)
	inv.free()


func test_silent_prey_adaptation_scaling_and_true_weakness_preservation_q4() -> void:
	var mgr: PreparationManager = PreparationManager.new()
	var lvl0_improvised: Dictionary = mgr.compute_adaptation_modifiers(0, false)
	var lvl1: int = mgr.register_campfire_rest()
	var lvl2: int = mgr.register_campfire_rest()
	var lvl3: int = mgr.register_campfire_rest()
	var lvl_cap: int = mgr.register_campfire_rest()

	var mod_improvised_l3: Dictionary = mgr.compute_adaptation_modifiers(lvl3, false)
	var mod_weakness_l3: Dictionary = mgr.compute_adaptation_modifiers(lvl3, true)

	_assert_true(
		lvl1 == 1 and lvl2 == 2 and lvl3 == 3 and lvl_cap == 3,
		"Q4/RF-003: Descansar na Fogueira incrementa region_alert_level silenciosamente de 0 até o teto 3"
	)
	_assert_true(
		float(mod_improvised_l3["damage_scale"]) < float(lvl0_improvised["damage_scale"])
		and is_equal_approx(float(mod_improvised_l3["damage_scale"]), 0.40)
		and float(mod_improvised_l3["max_stagger_multiplier"]) > 1.40
		and float(mod_improvised_l3["hazard_interval_multiplier"]) < 0.70,
		"Q4/RF-008: No nível 3 de adaptação, golpes improvisados sofrem punição severa (0.4x) e o monstro fica mais rápido e resiliente"
	)
	_assert_true(
		is_equal_approx(float(mod_weakness_l3["damage_scale"]), 1.0)
		and is_equal_approx(float(mod_weakness_l3["stagger_scale"]), 1.0),
		"Q4/RF-008: Mesmo no nível 3 de adaptação, atingir a Fraqueza Verdadeira (Postura + Óleo corretos) preserva 100% da eficácia"
	)


func test_defensive_null_and_invalid_resource_handling_ec005() -> void:
	var mgr: PreparationManager = PreparationManager.new()
	var ok_null_reagent: bool = mgr.register_reagent(null)
	var ok_null_recipe: bool = mgr.register_recipe(null)
	var added_invalid: int = mgr.add_reagent(null, -5)
	var craft_null: Dictionary = mgr.craft_oil(null)

	_assert_true(
		not ok_null_reagent
		and not ok_null_recipe
		and added_invalid == 0
		and not bool(craft_null.get("success", true)),
		"EC-005: PreparationManager rejeita ReagentData/OilRecipeData nulos e quantidades negativas sem crash"
	)


func test_preparation_data_isolation_and_cloning() -> void:
	var base_preset: PreparationData = PreparationData.new()
	base_preset.max_oil_charges = 24
	var base_reagent: ReagentData = load("res://src/data/reagent_alchemical_base.tres") as ReagentData
	base_preset.register_reagent(base_reagent)
	base_preset.add_reagent(base_reagent, 2)

	var inv1: InventoryComponent = InventoryComponent.new()
	inv1.preparation_data = base_preset
	inv1.ensure_default_catalog()

	var inv2: InventoryComponent = InventoryComponent.new()
	inv2.preparation_data = base_preset
	inv2.ensure_default_catalog()

	# Mutar inv1 (adiciona 5, respeitando max_stack = 10 de alchemical_base)
	inv1.collect_reagent_from_world(base_reagent, 5)

	var c_inv1: int = inv1.get_reagent_count(&"alchemical_base")
	var c_inv2: int = inv2.get_reagent_count(&"alchemical_base")
	var c_base: int = base_preset.get_reagent_count(&"alchemical_base")

	_assert_true(
		c_inv1 == 7
		and c_inv2 == 2
		and c_base == 2,
		"Phase 4 / Constitution: PreparationData.duplicate()/clone() isola o estado entre instâncias sem contaminação mútua"
	)
	inv1.free()
	inv2.free()


func test_preparation_data_round_trip_serialization() -> void:
	var pdata: PreparationData = PreparationData.new()
	pdata.region_alert_level = 2
	pdata.active_oil_recipe_id = &"recipe_vitriol_acid"
	pdata.equipped_traps = [&"trap_caltrops", &"trap_snare"]
	pdata.active_food_buff = &"buff_bear_stew"
	pdata.applied_oil_charges = 5

	var base_reagent: ReagentData = load("res://src/data/reagent_alchemical_base.tres") as ReagentData
	pdata.register_reagent(base_reagent)
	pdata.add_reagent(base_reagent, 7)
	pdata.set_oil_charges(CombatTypes.ElementOil.VITRIOL_ACID, 5)

	var dict: Dictionary = pdata.to_dict()

	var restored: PreparationData = PreparationData.new()
	restored.from_dict(dict)

	_assert_true(
		restored.region_alert_level == 2
		and restored.active_oil_recipe_id == &"recipe_vitriol_acid"
		and restored.active_food_buff == &"buff_bear_stew"
		and restored.applied_oil_charges == 5
		and restored.equipped_traps.size() == 2
		and restored.equipped_traps[0] == &"trap_caltrops"
		and restored.equipped_traps[1] == &"trap_snare"
		and restored.get_reagent_count(&"alchemical_base") == 7
		and restored.get_oil_charges(CombatTypes.ElementOil.VITRIOL_ACID) == 5,
		"Phase 4 / Issue #26: Serialização round-trip via to_dict() e from_dict() preserva loadout, alertas e estoques em JSON seguro"
	)


func test_preparation_validation_and_application_against_alert_level() -> void:
	var pdata: PreparationData = PreparationData.new()
	pdata.ensure_default_catalog()
	pdata.region_alert_level = 2

	# Sem cargas de vitríolo ácido inicialmente
	var invalid_check: Dictionary = pdata.validate_preparation(&"recipe_vitriol_acid")
	_assert_true(
		not bool(invalid_check.get("valid", true))
		and int(invalid_check.get("alert_level", 0)) == 2
		and int(invalid_check.get("charges", -1)) == 0,
		"Issue #26: validate_preparation() rejeita receita sem cargas disponíveis contra o nível de alerta regional"
	)

	# Adiciona cargas e valida novamente
	pdata.set_oil_charges(CombatTypes.ElementOil.VITRIOL_ACID, 8)
	var valid_check: Dictionary = pdata.validate_preparation(&"recipe_vitriol_acid")
	_assert_true(
		bool(valid_check.get("valid", false))
		and int(valid_check.get("charges", 0)) == 8
		and int(valid_check.get("alert_level", 0)) == 2,
		"Issue #26: validate_preparation() aprova receita com cargas válidas e reporta nível de alerta da presa"
	)

	# Aplica a preparação
	var applied_events: Array[Dictionary] = []
	pdata.preparation_applied.connect(func(recipe_id: StringName, charges: int) -> void:
		applied_events.append({"recipe_id": recipe_id, "charges": charges})
	)

	var ok_applied: bool = pdata.apply_preparation(&"recipe_vitriol_acid")
	_assert_true(
		ok_applied
		and pdata.active_oil_recipe_id == &"recipe_vitriol_acid"
		and pdata.applied_oil_charges == 8
		and applied_events.size() == 1
		and applied_events[0]["recipe_id"] == &"recipe_vitriol_acid"
		and applied_events[0]["charges"] == 8,
		"Issue #26: apply_preparation() sincroniza active_oil_recipe_id, applied_oil_charges e emite preparation_applied"
	)
