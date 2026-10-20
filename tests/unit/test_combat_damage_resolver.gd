class_name TestCombatDamageResolver
extends RefCounted
## Testes unitários para a camada de cálculo de dano, fraquezas, resistências e stagger (SPEC-002: T004, RF-004, EC-005, SC-002).


func run_all() -> Dictionary:
	var results: Array[String] = []
	var failures: Array[String] = []

	_test_armored_carapace_resist_vs_weakness_sc002(results, failures)
	_test_agile_beast_weakness_and_ignis_oil_sc002(results, failures)
	_test_staggered_bonus_damage_multiplier_rf004(results, failures)
	_test_null_safety_fallback_ec005(results, failures)

	return {"passed": results.size(), "failed": failures.size(), "results": results, "failures": failures}


func _assert_true(condition: bool, message: String, results: Array[String], failures: Array[String]) -> void:
	if condition:
		results.append("PASS: " + message)
	else:
		failures.append("FAIL: " + message)


func _test_armored_carapace_resist_vs_weakness_sc002(results: Array[String], failures: Array[String]) -> void:
	var armored: DefenseProfileData = load("res://src/data/defense_armored_carapace.tres") as DefenseProfileData

	var fast_atk: AttackData = AttackData.new()
	fast_atk.base_damage = 20.0
	fast_atk.stagger_damage = 20.0
	fast_atk.style_type = CombatTypes.StyleType.FAST_STEEL
	fast_atk.element_oil = CombatTypes.ElementOil.NONE

	var res_resist: Dictionary = DamageResolver.resolve_attack(fast_atk, armored, false)
	_assert_true(
		is_equal_approx(float(res_resist["final_damage"]), 10.0)
		and is_equal_approx(float(res_resist["final_stagger_damage"]), 5.0)
		and int(res_resist["matchup"]) == CombatTypes.MatchupResult.RESISTED,
		"SC-002: Couraça Blindada resiste a Postura Rápida (0.5x dano = 10.0, 0.25x stagger = 5.0, RESISTED)",
		results,
		failures
	)

	var heavy_acid_atk: AttackData = AttackData.new()
	heavy_acid_atk.base_damage = 20.0
	heavy_acid_atk.stagger_damage = 20.0
	heavy_acid_atk.style_type = CombatTypes.StyleType.HEAVY_IMPACT
	heavy_acid_atk.element_oil = CombatTypes.ElementOil.VITRIOL_ACID

	var res_weak: Dictionary = DamageResolver.resolve_attack(heavy_acid_atk, armored, false)
	# 20.0 * 1.5 (Heavy) * 1.5 (Acid) = 45.0 damage; 20.0 * 2.0 (Heavy) * 1.5 (Acid) = 60.0 stagger
	_assert_true(
		is_equal_approx(float(res_weak["final_damage"]), 45.0)
		and is_equal_approx(float(res_weak["final_stagger_damage"]), 60.0)
		and int(res_weak["matchup"]) == CombatTypes.MatchupResult.WEAKNESS,
		"SC-002: Couraça Blindada sofre Fraqueza Crítica contra Postura Pesada + Vitríolo Ácido (45.0 dano, 60.0 stagger)",
		results,
		failures
	)


func _test_agile_beast_weakness_and_ignis_oil_sc002(results: Array[String], failures: Array[String]) -> void:
	var agile: DefenseProfileData = load("res://src/data/defense_agile_beast.tres") as DefenseProfileData

	var fast_ignis: AttackData = AttackData.new()
	fast_ignis.base_damage = 16.0
	fast_ignis.stagger_damage = 16.0
	fast_ignis.style_type = CombatTypes.StyleType.FAST_STEEL
	fast_ignis.element_oil = CombatTypes.ElementOil.IGNIS_OIL

	var res: Dictionary = DamageResolver.resolve_attack(fast_ignis, agile, false)
	# 16.0 * 1.5 * 1.5 = 36.0
	_assert_true(
		is_equal_approx(float(res["final_damage"]), 36.0)
		and int(res["matchup"]) == CombatTypes.MatchupResult.WEAKNESS,
		"SC-002: Fera Ágil sofre Fraqueza contra Postura Rápida + Óleo Ígneo (2.25x = 36.0 dano)",
		results,
		failures
	)


func _test_staggered_bonus_damage_multiplier_rf004(results: Array[String], failures: Array[String]) -> void:
	var armored: DefenseProfileData = load("res://src/data/defense_armored_carapace.tres") as DefenseProfileData
	var atk: AttackData = AttackData.new()
	atk.base_damage = 20.0
	atk.style_type = CombatTypes.StyleType.HEAVY_IMPACT
	atk.element_oil = CombatTypes.ElementOil.NONE

	var res_normal: Dictionary = DamageResolver.resolve_attack(atk, armored, false)
	var res_staggered: Dictionary = DamageResolver.resolve_attack(atk, armored, true)

	_assert_true(
		is_equal_approx(float(res_normal["final_damage"]), 30.0)
		and is_equal_approx(float(res_staggered["final_damage"]), 45.0),
		"RF-004: Alvo em estado Staggered (Break) sofre multiplicador adicional staggered_damage_multiplier (1.5x)",
		results,
		failures
	)


func _test_null_safety_fallback_ec005(results: Array[String], failures: Array[String]) -> void:
	var res: Dictionary = DamageResolver.resolve_attack(null, null, false)
	_assert_true(
		is_equal_approx(float(res["final_damage"]), 10.0)
		and int(res["matchup"]) == CombatTypes.MatchupResult.NEUTRAL,
		"EC-005: DamageResolver trata AttackData e DefenseProfileData nulos com fallback seguro (10.0 dano, NEUTRAL)",
		results,
		failures
	)
