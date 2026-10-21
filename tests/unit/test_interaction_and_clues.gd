class_name TestInteractionAndClues
extends RefCounted
## Suíte de testes de componentes para PlayerInteractionComponent, InteractableClue e Estados (SPEC-003: RF-001, RF-002, EC-001, EC-003, EC-004, SC-002).

var _results: Array[String] = []
var _failures: Array[String] = []


func run_all() -> Dictionary:
	_results.clear()
	_failures.clear()

	test_select_best_clue_prioritizes_uninspected_and_closest_ec001()
	test_channeled_inspection_completes_and_emits_signal_q2()
	test_inspection_cancelled_on_dodge_hurt_or_movement_ec003_ec004()
	test_gameplay_inputs_blocked_when_grimoire_open_q3()

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


func test_select_best_clue_prioritizes_uninspected_and_closest_ec001() -> void:
	var c_inspected_close: InteractableClue = InteractableClue.new()
	c_inspected_close.global_position = Vector2(5.0, 0.0)
	c_inspected_close.is_inspected = true

	var c_uninspected_mid: InteractableClue = InteractableClue.new()
	c_uninspected_mid.global_position = Vector2(18.0, 0.0)
	c_uninspected_mid.is_inspected = false

	var c_uninspected_far: InteractableClue = InteractableClue.new()
	c_uninspected_far.global_position = Vector2(36.0, 0.0)
	c_uninspected_far.is_inspected = false

	var candidates: Array[InteractableClue] = [c_inspected_close, c_uninspected_far, c_uninspected_mid]
	var chosen: InteractableClue = PlayerInteractionComponent.select_best_clue(Vector2.ZERO, candidates)

	_assert_true(
		chosen == c_uninspected_mid,
		"EC-001/SC-002: Prioriza deterministicamente a pista NÃO inspecionada mais próxima sobre pistas já coletadas"
	)

	c_uninspected_mid.free()
	c_uninspected_far.free()
	c_inspected_close.free()


func test_channeled_inspection_completes_and_emits_signal_q2() -> void:
	var interaction: PlayerInteractionComponent = PlayerInteractionComponent.new()
	var clue: InteractableClue = InteractableClue.new()
	clue.clue_data = load("res://src/data/clue_carapace_deep_tracks.tres") as ClueData
	clue.inspect_duration = 0.4

	var completed_counter: Array[int] = [0]
	interaction.clue_inspection_completed.connect(func(_d: ClueData) -> void: completed_counter[0] += 1)

	interaction.register_candidate_for_test(clue)
	var started: bool = interaction.try_start_interaction()
	interaction._physics_process(0.2)
	var mid_inspecting: bool = interaction.is_inspecting() and not clue.is_inspected
	interaction._physics_process(0.25)

	_assert_true(
		started and mid_inspecting and clue.is_inspected and completed_counter[0] == 1,
		"Q2/RF-002: Canalização de 0.4s progride e emite clue_inspection_completed exatamente ao concluir"
	)

	clue.free()
	interaction.free()


func test_inspection_cancelled_on_dodge_hurt_or_movement_ec003_ec004() -> void:
	var interaction: PlayerInteractionComponent = PlayerInteractionComponent.new()
	var input_comp: PlayerInputComponent = PlayerInputComponent.new()
	var sm: StateMachine = StateMachine.new()
	var idle_st: PlayerIdleState = PlayerIdleState.new()
	idle_st.name = &"IdleState"
	var dodge_st: PlayerDodgeState = PlayerDodgeState.new()
	dodge_st.name = &"DodgeState"
	sm.add_child(idle_st)
	sm.add_child(dodge_st)
	sm.current_state = idle_st

	interaction.input_component = input_comp
	interaction.state_machine = sm

	var clue: InteractableClue = InteractableClue.new()
	clue.clue_data = load("res://src/data/clue_beast_light_fur.tres") as ClueData
	clue.inspect_duration = 0.5
	interaction.register_candidate_for_test(clue)

	# 1. Inicia em IdleState e cancela ao mudar para DodgeState
	interaction.try_start_interaction()
	sm.current_state = dodge_st
	interaction._physics_process(0.1)
	var cancelled_by_state: bool = not interaction.is_inspecting() and not clue.is_inspected

	# 2. Tenta iniciar durante DodgeState (EC-004: deve recusar)
	var blocked_in_dodge: bool = not interaction.try_start_interaction()

	# 3. Volta para IdleState, inicia e cancela por movimento
	sm.current_state = idle_st
	interaction.try_start_interaction()
	input_comp.move_direction = Vector2.RIGHT
	interaction._physics_process(0.1)
	var cancelled_by_move: bool = not interaction.is_inspecting() and not clue.is_inspected

	_assert_true(
		cancelled_by_state and blocked_in_dodge and cancelled_by_move,
		"EC-003/EC-004: Canalização é bloqueada fora de Idle/Move e abortada imediatamente por Esquiva, Dano ou Movimento"
	)

	clue.free()
	sm.free()
	input_comp.free()
	interaction.free()


func test_gameplay_inputs_blocked_when_grimoire_open_q3() -> void:
	var input_comp: PlayerInputComponent = PlayerInputComponent.new()
	input_comp.register_attack_press()
	input_comp.register_dodge_press()
	input_comp.set_gameplay_inputs_blocked(true)
	input_comp.register_attack_press()

	_assert_true(
		not input_comp.has_buffered_attack() and not input_comp.has_buffered_dodge(),
		"Q3/EC-003: Ativar gameplay_inputs_blocked limpa buffers e impede ataques acidentais com o Grimório aberto"
	)

	input_comp.free()
