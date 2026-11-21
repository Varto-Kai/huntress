class_name TestPlayerStateMachine
extends RefCounted
## Testes automatizados de componente para a StateMachine da Caçadora:
## Idle <-> Move <-> Dodge, Backstep, i-frames vs recovery, cooldown e Input Buffer (T011).


func run_all() -> Dictionary:
	var results: Array[String] = []
	var failures: Array[String] = []

	_test_idle_to_move_and_back_rf003(results, failures)
	_test_directional_dodge_locks_direction_rf005(results, failures)
	_test_idle_backstep_preserves_facing_ec002(results, failures)
	_test_iframes_and_recovery_curve_rf006(results, failures)
	_test_cooldown_and_input_buffer_ec003(results, failures)
	_test_bidirectional_transition_negotiation_issue24(results, failures)
	_test_player_states_is_active_and_dodge_can_enter_issue24(results, failures)

	return {"passed": results.size(), "failed": failures.size(), "results": results, "failures": failures}


func _assert_true(condition: bool, message: String, results: Array[String], failures: Array[String]) -> void:
	if condition:
		results.append("PASS: " + message)
	else:
		failures.append("FAIL: " + message)


func _build_test_rig() -> Dictionary:
	var config: PlayerMovementConfig = PlayerMovementConfig.new()
	config.max_speed = 200.0
	config.acceleration = 2000.0
	config.friction = 2000.0
	config.dodge_speed = 400.0
	config.dodge_end_speed_factor = 0.5
	config.dodge_cooldown = 0.30

	var movement: MovementComponent = MovementComponent.new()
	movement.setup(null, config)
	var input_comp: PlayerInputComponent = PlayerInputComponent.new()
	input_comp.config = config

	var sm: StateMachine = StateMachine.new()
	var idle_state: PlayerIdleState = PlayerIdleState.new()
	var move_state: PlayerMoveState = PlayerMoveState.new()
	var dodge_state: PlayerDodgeState = PlayerDodgeState.new()
	idle_state.name = "IdleState"
	move_state.name = "MoveState"
	dodge_state.name = "DodgeState"

	idle_state.movement_component = movement
	idle_state.input_component = input_comp
	move_state.movement_component = movement
	move_state.input_component = input_comp
	dodge_state.movement_component = movement
	dodge_state.input_component = input_comp
	dodge_state.config = config

	sm.add_child(idle_state)
	sm.add_child(move_state)
	sm.add_child(dodge_state)
	sm.initial_state = idle_state
	sm.initialize()

	return {"movement": movement, "input": input_comp, "sm": sm, "dodge": dodge_state}


func _free_rig(rig: Dictionary) -> void:
	(rig["sm"] as StateMachine).free()
	(rig["movement"] as MovementComponent).free()
	(rig["input"] as PlayerInputComponent).free()


func _test_idle_to_move_and_back_rf003(results: Array[String], failures: Array[String]) -> void:
	var rig: Dictionary = _build_test_rig()
	var sm: StateMachine = rig["sm"] as StateMachine
	var input_comp: PlayerInputComponent = rig["input"] as PlayerInputComponent
	var movement: MovementComponent = rig["movement"] as MovementComponent

	_assert_true(sm.get_current_state_name() == &"IdleState", "RF-003: StateMachine inicia em IdleState", results, failures)
	input_comp.move_direction = Vector2.RIGHT
	sm._physics_process(0.016)
	_assert_true(sm.get_current_state_name() == &"MoveState", "SC-002: Transição Idle -> Move no próximo frame", results, failures)
	sm._physics_process(0.05)
	_assert_true(movement.facing_direction.is_equal_approx(Vector2.RIGHT), "RF-004: MoveState atualiza facing_direction", results, failures)

	input_comp.move_direction = Vector2.ZERO
	sm._physics_process(0.2)
	_assert_true(
		sm.get_current_state_name() == &"IdleState" and movement.facing_direction.is_equal_approx(Vector2.RIGHT),
		"RF-004: Retorno para IdleState preserva última facing_direction válida",
		results,
		failures
	)
	_free_rig(rig)


func _test_directional_dodge_locks_direction_rf005(results: Array[String], failures: Array[String]) -> void:
	var rig: Dictionary = _build_test_rig()
	var sm: StateMachine = rig["sm"] as StateMachine
	var input_comp: PlayerInputComponent = rig["input"] as PlayerInputComponent
	var movement: MovementComponent = rig["movement"] as MovementComponent

	input_comp.move_direction = Vector2.RIGHT
	sm._physics_process(0.016)
	input_comp.register_dodge_press()
	sm._physics_process(0.016)
	input_comp.move_direction = Vector2.LEFT
	sm._physics_process(0.05)

	_assert_true(
		sm.get_current_state_name() == &"DodgeState" and movement.current_velocity.x > 0.0,
		"RF-005: DodgeState trava direção inicial e ignora mudança no meio do trajeto",
		results,
		failures
	)
	_free_rig(rig)


func _test_idle_backstep_preserves_facing_ec002(results: Array[String], failures: Array[String]) -> void:
	var rig: Dictionary = _build_test_rig()
	var sm: StateMachine = rig["sm"] as StateMachine
	var input_comp: PlayerInputComponent = rig["input"] as PlayerInputComponent
	var movement: MovementComponent = rig["movement"] as MovementComponent
	var dodge: PlayerDodgeState = rig["dodge"] as PlayerDodgeState

	movement.set_facing_direction(Vector2.RIGHT)
	input_comp.move_direction = Vector2.ZERO
	input_comp.register_dodge_press()
	sm._physics_process(0.016)

	_assert_true(
		dodge.is_backstep() and is_equal_approx(movement.current_velocity.x, -300.0),
		"EC-002 / RF-005: Esquiva em Idle executa Backstep em -facing_direction com backstep_speed_multiplier",
		results,
		failures
	)
	_assert_true(
		movement.facing_direction.is_equal_approx(Vector2.RIGHT),
		"EC-002: Backstep preserva facing_direction apontada para a frente",
		results,
		failures
	)
	_free_rig(rig)


func _test_iframes_and_recovery_curve_rf006(results: Array[String], failures: Array[String]) -> void:
	var rig: Dictionary = _build_test_rig()
	var sm: StateMachine = rig["sm"] as StateMachine
	var input_comp: PlayerInputComponent = rig["input"] as PlayerInputComponent
	var movement: MovementComponent = rig["movement"] as MovementComponent
	var dodge: PlayerDodgeState = rig["dodge"] as PlayerDodgeState

	input_comp.move_direction = Vector2.RIGHT
	input_comp.register_dodge_press()
	sm._physics_process(0.016)

	var invuln_at_start: bool = dodge.is_invulnerable()
	var speed_at_start: float = movement.current_velocity.length()
	sm._physics_process(0.18)
	var invuln_in_recovery: bool = dodge.is_invulnerable()
	var speed_in_recovery: float = movement.current_velocity.length()

	_assert_true(
		invuln_at_start and not invuln_in_recovery,
		"RF-006: i-frames iniciam no frame 1 e encerram antes do fim de dodge_duration",
		results,
		failures
	)
	_assert_true(
		speed_in_recovery < speed_at_start and speed_in_recovery >= 200.0,
		"RF-006 / DT-05: Velocidade desacelera suavemente no terço final (recovery)",
		results,
		failures
	)
	_free_rig(rig)


func _test_cooldown_and_input_buffer_ec003(results: Array[String], failures: Array[String]) -> void:
	var rig: Dictionary = _build_test_rig()
	var sm: StateMachine = rig["sm"] as StateMachine
	var input_comp: PlayerInputComponent = rig["input"] as PlayerInputComponent
	var dodge: PlayerDodgeState = rig["dodge"] as PlayerDodgeState

	input_comp.move_direction = Vector2.RIGHT
	input_comp.register_dodge_press()
	sm._physics_process(0.016)
	sm._physics_process(0.25)

	var blocked_during_cd: bool = not dodge.can_dodge()
	dodge._physics_process(0.22)
	input_comp.register_dodge_press()
	input_comp._physics_process(0.09)
	dodge._physics_process(0.09)
	sm._physics_process(0.016)

	_assert_true(
		blocked_during_cd and sm.get_current_state_name() == &"DodgeState",
		"RF-007 / EC-003: Cooldown bloqueia esquiva precoce e Input Buffer dispara ao expirar",
		results,
		failures
	)
	_free_rig(rig)


class MockTestState extends State:
	var allow_interrupt: bool = true
	var allow_enter_flag: bool = true

	func can_be_interrupted_by(_to_state: State) -> bool:
		return allow_interrupt

	func can_enter(_from_state: State) -> bool:
		return allow_enter_flag


func _test_bidirectional_transition_negotiation_issue24(results: Array[String], failures: Array[String]) -> void:
	var sm: StateMachine = StateMachine.new()
	var state_a: MockTestState = MockTestState.new()
	var state_b: MockTestState = MockTestState.new()
	state_a.name = "StateA"
	state_b.name = "StateB"
	sm.add_child(state_a)
	sm.add_child(state_b)
	sm.initial_state = state_a
	sm.initialize()

	_assert_true(
		sm.get_current_state_name() == &"StateA" and state_a.is_active and not state_b.is_active,
		"Issue #24: Estado inicial fica ativo (is_active = true) e outros inativos (is_active = false)",
		results,
		failures
	)

	# 1. can_be_interrupted_by bloqueia transição quando retorna false
	state_a.allow_interrupt = false
	state_b.allow_enter_flag = true
	var transitioned: bool = sm.transition_to(&"StateB")
	_assert_true(
		not transitioned and sm.get_current_state_name() == &"StateA" and state_a.is_active and not state_b.is_active,
		"Issue #24: Transição é rejeitada quando current_state.can_be_interrupted_by() retorna false",
		results,
		failures
	)

	# 2. can_enter bloqueia transição quando retorna false
	state_a.allow_interrupt = true
	state_b.allow_enter_flag = false
	transitioned = sm.transition_to(&"StateB")
	_assert_true(
		not transitioned and sm.get_current_state_name() == &"StateA" and state_a.is_active and not state_b.is_active,
		"Issue #24: Transição é rejeitada quando target_state.can_enter() retorna false",
		results,
		failures
	)

	# 3. Transição bem-sucedida quando ambos concordam (protocolo bidirecional)
	state_a.allow_interrupt = true
	state_b.allow_enter_flag = true
	transitioned = sm.transition_to(&"StateB")
	_assert_true(
		transitioned and sm.get_current_state_name() == &"StateB" and not state_a.is_active and state_b.is_active,
		"Issue #24: Transição sucede quando can_be_interrupted_by e can_enter retornam true, atualizando is_active",
		results,
		failures
	)

	# 4. change_state alias preservando protocolo bidirecional
	state_b.allow_interrupt = true
	state_a.allow_enter_flag = true
	var changed: bool = sm.change_state(&"StateA")
	_assert_true(
		changed and sm.get_current_state_name() == &"StateA" and state_a.is_active and not state_b.is_active,
		"Issue #24: change_state funciona como alias para transition_to preservando protocolo bidirecional",
		results,
		failures
	)

	sm.free()


func _test_player_states_is_active_and_dodge_can_enter_issue24(results: Array[String], failures: Array[String]) -> void:
	var rig: Dictionary = _build_test_rig()
	var sm: StateMachine = rig["sm"] as StateMachine
	var input_comp: PlayerInputComponent = rig["input"] as PlayerInputComponent
	var dodge: PlayerDodgeState = rig["dodge"] as PlayerDodgeState
	var idle: State = sm.get_state(&"IdleState")
	var move: State = sm.get_state(&"MoveState")

	# Lifecycle no rig da jogadora
	_assert_true(
		idle.is_active and not move.is_active and not dodge.is_active,
		"Issue #24: Player StateMachine inicia com apenas IdleState.is_active == true",
		results,
		failures
	)

	input_comp.move_direction = Vector2.RIGHT
	sm._physics_process(0.016)
	_assert_true(
		not idle.is_active and move.is_active and not dodge.is_active,
		"Issue #24: Transição para MoveState desativa IdleState e ativa MoveState via is_active",
		results,
		failures
	)

	input_comp.register_dodge_press()
	sm._physics_process(0.016)
	_assert_true(
		not move.is_active and dodge.is_active,
		"Issue #24: Transição para DodgeState desativa MoveState e ativa DodgeState via is_active",
		results,
		failures
	)

	# Aguarda término da esquiva
	sm._physics_process(0.25)
	# input é Vector2.RIGHT, então retorna para MoveState
	_assert_true(
		not dodge.is_active and move.is_active,
		"Issue #24: Término de esquiva desativa DodgeState.is_active",
		results,
		failures
	)

	# Enquanto esquiva estiver em cooldown, dodge.can_enter(move) é false e bloqueia transição
	_assert_true(
		not dodge.can_enter(move),
		"Issue #24: PlayerDodgeState.can_enter() retorna false durante o cooldown",
		results,
		failures
	)
	var blocked_transition: bool = sm.transition_to(&"DodgeState")
	_assert_true(
		not blocked_transition and sm.get_current_state_name() == &"MoveState" and move.is_active and not dodge.is_active,
		"Issue #24: StateMachine bloqueia transição para DodgeState enquanto can_enter() for false",
		results,
		failures
	)

	_free_rig(rig)

