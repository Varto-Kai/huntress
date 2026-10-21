class_name TestGrimoireTracker
extends RefCounted
## Suíte de testes unitários para GrimoireTracker e GrimoireComponent (SPEC-003: RF-004, RF-005, EC-002, EC-005, EC-006, SC-001).

var _results: Array[String] = []
var _failures: Array[String] = []


func run_all() -> Dictionary:
	_results.clear()
	_failures.clear()

	test_initial_state_all_locked_placeholders()
	test_idempotent_clue_discovery_ec002()
	test_deterministic_1to1_section_unlock_and_oil_recipe()
	test_false_lead_contaminates_section_until_discarded_q5()
	test_reversible_discard_restores_or_hides_section_ec006()
	test_null_and_invalid_clue_defensive_handling_ec005()

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


func test_initial_state_all_locked_placeholders() -> void:
	var tracker: GrimoireTracker = GrimoireTracker.new()
	var entry: MonsterGrimoireEntryData = load("res://src/data/entry_armored_carapace.tres") as MonsterGrimoireEntryData
	tracker.register_entry(entry)

	var state: Dictionary = tracker.resolve_monster_entry(&"armored_carapace")
	var style_sec: Dictionary = state["style_section"] as Dictionary
	var oil_sec: Dictionary = state["oil_section"] as Dictionary
	var beh_sec: Dictionary = state["behavior_section"] as Dictionary

	_assert_true(
		not bool(style_sec["unlocked"]) and String(style_sec["style_weakness_text"]) == "???",
		"RF-005: Seção de estilo inicia bloqueada com placeholder '???'"
	)
	_assert_true(
		not bool(oil_sec["unlocked"]) and String(oil_sec["oil_recipe_text"]) == "???",
		"RF-004/RF-005: Seção de receita de óleo inicia bloqueada com '???'"
	)
	_assert_true(
		not bool(beh_sec["unlocked"]) and not bool(state["deduction_solved"]),
		"RF-005: Dedução completa do monstro inicia como false"
	)


func test_idempotent_clue_discovery_ec002() -> void:
	var tracker: GrimoireTracker = GrimoireTracker.new()
	var entry: MonsterGrimoireEntryData = load("res://src/data/entry_armored_carapace.tres") as MonsterGrimoireEntryData
	tracker.register_entry(entry)

	var clue_tracks: ClueData = load("res://src/data/clue_carapace_deep_tracks.tres") as ClueData
	var first_register: bool = tracker.discover_clue(clue_tracks)
	var second_register: bool = tracker.discover_clue(clue_tracks)

	_assert_true(
		first_register and not second_register and tracker.get_discovered_clues_for_monster(&"armored_carapace").size() == 1,
		"EC-002: Re-inspecionar a mesma pista é idempotente e não duplica contagem"
	)


func test_deterministic_1to1_section_unlock_and_oil_recipe() -> void:
	var tracker: GrimoireTracker = GrimoireTracker.new()
	var entry: MonsterGrimoireEntryData = load("res://src/data/entry_armored_carapace.tres") as MonsterGrimoireEntryData
	tracker.register_entry(entry)

	var clue_shell: ClueData = load("res://src/data/clue_carapace_molted_shell.tres") as ClueData
	tracker.discover_clue(clue_shell)

	var state: Dictionary = tracker.resolve_monster_entry(&"armored_carapace")
	var style_sec: Dictionary = state["style_section"] as Dictionary
	var oil_sec: Dictionary = state["oil_section"] as Dictionary

	_assert_true(
		not bool(style_sec["unlocked"]) and bool(oil_sec["unlocked"]),
		"Q1/RF-004: Coletar pista de carapaça destrava exclusivamente a seção 1:1 de Alquimia/Óleo"
	)
	_assert_true(
		int(oil_sec["element_weakness"]) == CombatTypes.ElementOil.VITRIOL_ACID
		and String(oil_sec["oil_recipe_text"]).find("Bile Corrosiva") != -1,
		"RF-004: Seção de óleo revela VITRIOL_ACID e a Fórmula de Materiais do Óleo Fabricável"
	)


func test_false_lead_contaminates_section_until_discarded_q5() -> void:
	var tracker: GrimoireTracker = GrimoireTracker.new()
	var entry: MonsterGrimoireEntryData = load("res://src/data/entry_armored_carapace.tres") as MonsterGrimoireEntryData
	tracker.register_entry(entry)

	var c1: ClueData = load("res://src/data/clue_carapace_deep_tracks.tres") as ClueData
	var c2_true: ClueData = load("res://src/data/clue_carapace_molted_shell.tres") as ClueData
	var c3_false: ClueData = load("res://src/data/clue_carapace_false_campfire.tres") as ClueData
	var c4: ClueData = load("res://src/data/clue_carapace_cracked_pillar.tres") as ClueData

	tracker.discover_clue(c1)
	tracker.discover_clue(c2_true)
	tracker.discover_clue(c3_false)
	tracker.discover_clue(c4)

	var contaminated_state: Dictionary = tracker.resolve_monster_entry(&"armored_carapace")
	var oil_contaminated: Dictionary = contaminated_state["oil_section"] as Dictionary

	_assert_true(
		bool(oil_contaminated["is_contaminated"])
		and int(oil_contaminated["element_weakness"]) == CombatTypes.ElementOil.IGNIS_OIL
		and not bool(contaminated_state["deduction_solved"]),
		"Q5/RF-005: Pista falsa ativa contamina a síntese com o Óleo errado (IGNIS_OIL) e impede conclusão precisa"
	)

	var discarded_now: bool = tracker.toggle_clue_discarded(&"carapace_false_campfire")
	var solved_state: Dictionary = tracker.resolve_monster_entry(&"armored_carapace")
	var oil_solved: Dictionary = solved_state["oil_section"] as Dictionary

	_assert_true(
		discarded_now
		and bool(oil_solved["is_accurate"])
		and int(oil_solved["element_weakness"]) == CombatTypes.ElementOil.VITRIOL_ACID
		and bool(solved_state["deduction_solved"]),
		"Q5/RF-005: Descartar manualmente a pista falsa no Grimório revela o Óleo verdadeiro (VITRIOL_ACID) e soluciona a caçada"
	)


func test_reversible_discard_restores_or_hides_section_ec006() -> void:
	var tracker: GrimoireTracker = GrimoireTracker.new()
	var entry: MonsterGrimoireEntryData = load("res://src/data/entry_agile_beast.tres") as MonsterGrimoireEntryData
	tracker.register_entry(entry)

	var clue_fur: ClueData = load("res://src/data/clue_beast_light_fur.tres") as ClueData
	tracker.discover_clue(clue_fur)

	tracker.toggle_clue_discarded(&"beast_light_fur")
	var state_discarded: Dictionary = tracker.resolve_section(&"agile_beast", GrimoireTypes.SectionType.STYLE_MATCHUP)
	_assert_true(
		not bool(state_discarded["unlocked"]),
		"EC-006: Descartar por engano a única pista verdadeira oculta novamente a seção ('???')"
	)

	tracker.toggle_clue_discarded(&"beast_light_fur")
	var state_restored: Dictionary = tracker.resolve_section(&"agile_beast", GrimoireTypes.SectionType.STYLE_MATCHUP)
	_assert_true(
		bool(state_restored["unlocked"]) and bool(state_restored["is_accurate"]),
		"EC-006: Restaurar a pista verdadeira restabelece imediatamente a síntese correta"
	)


func test_null_and_invalid_clue_defensive_handling_ec005() -> void:
	var tracker: GrimoireTracker = GrimoireTracker.new()
	var ok_null_entry: bool = tracker.register_entry(null)
	var ok_null_clue: bool = tracker.discover_clue(null)
	var orphan_clue: ClueData = ClueData.new()
	orphan_clue.clue_id = &"orphan"
	orphan_clue.monster_id = &"non_existent_monster"
	var ok_orphan: bool = tracker.discover_clue(orphan_clue)

	_assert_true(
		not ok_null_entry and not ok_null_clue and not ok_orphan,
		"EC-005: GrimoireTracker rejeita entradas/pistas nulas ou de monster_id inexistente sem crash"
	)
