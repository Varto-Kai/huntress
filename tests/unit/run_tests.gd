extends SceneTree
## Runner CLI para execução headless de toda a suíte de testes da SPEC-001 (T011, T015).
## Uso: godot --headless --path . -s res://tests/unit/run_tests.gd


func _init() -> void:
	print("==================================================")
	print("🧪 HUNTRESS SDD TEST RUNNER — SPEC-001")
	print("==================================================")

	var total_passed: int = 0
	var total_failed: int = 0

	var math_suite: TestMovementMath = TestMovementMath.new()
	var math_res: Dictionary = math_suite.run_all()
	_print_suite_report("TestMovementMath", math_res)
	total_passed += int(math_res["passed"])
	total_failed += int(math_res["failed"])

	var sm_suite: TestPlayerStateMachine = TestPlayerStateMachine.new()
	var sm_res: Dictionary = sm_suite.run_all()
	_print_suite_report("TestPlayerStateMachine", sm_res)
	total_passed += int(sm_res["passed"])
	total_failed += int(sm_res["failed"])

	print("--------------------------------------------------")
	print("RESUMO TOTAL: %d PASS | %d FAIL" % [total_passed, total_failed])
	print("==================================================")

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
