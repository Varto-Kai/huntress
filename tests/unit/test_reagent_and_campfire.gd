class_name TestReagentAndCampfire
extends RefCounted
## Suíte de testes automatizados para InteractableReagent, InteractableCampfire e integração com PlayerInteractionComponent (SPEC-004: RF-003, EC-002, SC-002).

var _results: Array[String] = []
var _failures: Array[String] = []


func run_all() -> Dictionary:
	_results.clear()
	_failures.clear()

	test_reagent_collection_depletes_and_campfire_rest_respawns_ec002()
	test_campfire_interaction_signal_emission_rf003()

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


func test_reagent_collection_depletes_and_campfire_rest_respawns_ec002() -> void:
	var interaction: PlayerInteractionComponent = PlayerInteractionComponent.new()
	var reagent_node: InteractableReagent = InteractableReagent.new()
	reagent_node.reagent_data = load("res://src/data/reagent_corrosive_bile.tres") as ReagentData
	reagent_node.pickup_amount = 2

	var collected_ids: Array[StringName] = []
	var collected_amounts: Array[int] = []
	interaction.reagent_collected_from_world.connect(func(r_data: ReagentData, amt: int) -> void:
		collected_ids.append(r_data.reagent_id)
		collected_amounts.append(amt)
	)

	interaction.register_candidate_for_test(reagent_node)
	var first_ok: bool = interaction.try_start_interaction()
	var second_ok: bool = interaction.try_start_interaction()

	_assert_true(
		first_ok
		and not second_ok
		and reagent_node.is_collected
		and collected_ids.size() == 1
		and collected_ids[0] == &"corrosive_bile"
		and collected_amounts[0] == 2,
		"RF-003: InteractableReagent coleta a quantidade configurada e impede re-coleta duplicada enquanto esgotado"
	)

	reagent_node.respawn_reagent()
	var third_ok: bool = interaction.try_start_interaction()
	_assert_true(
		third_ok and collected_ids.size() == 2,
		"EC-002: respawn_reagent() ao descansar na Fogueira reabastece o nó para nova coleta"
	)

	reagent_node.free()
	interaction.free()


func test_campfire_interaction_signal_emission_rf003() -> void:
	var interaction: PlayerInteractionComponent = PlayerInteractionComponent.new()
	var campfire: InteractableCampfire = InteractableCampfire.new()

	var activated_count: int = 0
	interaction.campfire_interacted.connect(func(_cf: InteractableCampfire) -> void:
		activated_count += 1
	)

	interaction.register_candidate_for_test(campfire)
	var ok: bool = interaction.try_start_interaction()

	_assert_true(
		ok and activated_count == 1,
		"RF-003: Interagir com InteractableCampfire emite campfire_interacted de forma desacoplada"
	)

	campfire.free()
	interaction.free()
