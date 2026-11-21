extends SceneTree
## Runner CLI para execução headless de toda a suíte de testes do Projeto Huntress (SPEC-001, SPEC-002, SPEC-003 & SPEC-004).
## Uso: godot --headless --path . -s res://tests/unit/run_tests.gd


func _init() -> void:
	print("==============================================================")
	print("🧪 HUNTRESS SDD TEST RUNNER — SPEC-001, SPEC-002, SPEC-003 & SPEC-004")
	print("==============================================================")

	var total_passed: int = 0
	var total_failed: int = 0

	var suites: Array[Variant] = [
		["TestMovementMath (SPEC-001)", (load("res://tests/unit/test_movement_math.gd") as GDScript).new()],
		["TestPlayerStateMachine (SPEC-001)", (load("res://tests/unit/test_player_state_machine.gd") as GDScript).new()],
		["TestCombatDamageResolver (SPEC-002)", (load("res://tests/unit/test_combat_damage_resolver.gd") as GDScript).new()],
		["TestCombatComponentsAndStates (SPEC-002)", (load("res://tests/unit/test_combat_components_and_states.gd") as GDScript).new()],
		["TestGrimoireTracker (SPEC-003)", (load("res://tests/unit/test_grimoire_tracker.gd") as GDScript).new()],
		["TestInteractionAndClues (SPEC-003)", (load("res://tests/unit/test_interaction_and_clues.gd") as GDScript).new()],
		["TestPreparationManager (SPEC-004)", (load("res://tests/unit/test_preparation_manager.gd") as GDScript).new()],
		["TestReagentAndCampfire (SPEC-004)", (load("res://tests/unit/test_reagent_and_campfire.gd") as GDScript).new()],
	]

	for entry: Variant in suites:
		var pair: Array = entry as Array
		var suite_name: String = String(pair[0])
		var suite_obj: Object = pair[1] as Object
		var res: Dictionary = suite_obj.call("run_all") as Dictionary
		_print_suite_report(suite_name, res)
		total_passed += int(res["passed"])
		total_failed += int(res["failed"])

	print("--------------------------------------------------------------")
	print("RESUMO TOTAL: %d PASS | %d FAIL" % [total_passed, total_failed])
	print("==============================================================")

	if total_failed > 0:
		quit(1)
	else:
		quit(0)


func _print_suite_report(suite_name: String, report: Dictionary) -> void:
	print("\n▶ Suite: %s" % suite_name)
	var passed_list: Array = report["results"] as Array
	for item: Variant in passed_list:
		print("  ✅ %s" % String(item))
	var failed_list: Array = report["failures"] as Array
	for item: Variant in failed_list:
		print("  ❌ %s" % String(item))
