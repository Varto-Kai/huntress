class_name TestCombatComponentsAndStates
extends RefCounted
## Testes automatizados de componente para Hitbox/Hurtbox, Health, Stagger,
## PlayerAttackState (combos e Dodge Cancel) e PlayerHurtState (SPEC-002: T010).


func run_all() -> Dictionary:
	var results: Array[String] = []
	var failures: Array[String] = []

	_test_single_hit_per_swing_and_multitarget_sc001(results, failures)
	_test_dodge_and_post_hit_iframes_block_damage_sc003(results, failures)
	_test_combo_chain_fast_vs_heavy_rf006(results, failures)
	_test_dodge_cancel_windows_rf007(results, failures)
	_test_hurt_state_aborts_attack_and_deactivates_hitbox_ec003(results, failures)
	_test_tagged_invulnerability_leases_rf008(results, failures)

	return {"passed": results.size(), "failed": failures.size(), "results": results, "failures": failures}


func _assert_true(condition: bool, message: String, results: Array[String], failures: Array[String]) -> void:
	if condition:
		results.append("PASS: " + message)
	else:
		failures.append("FAIL: " + message)


func _build_combat_rig() -> Dictionary:
	var config: PlayerMovementConfig = PlayerMovementConfig.new()
	var movement: MovementComponent = MovementComponent.new()
	movement.setup(null, config)
	var input_comp: PlayerInputComponent = PlayerInputComponent.new()
	input_comp.config = config
	var style_comp: CombatStyleComponent = CombatStyleComponent.new()
	style_comp.ensure_default_styles()
	var weapon_pivot: Node2D = Node2D.new()
	var hitbox: HitboxComponent = HitboxComponent.new()
	weapon_pivot.add_child(hitbox)
	var health: HealthComponent = HealthComponent.new()
	health.reset_health()
	var hurtbox: HurtboxComponent = HurtboxComponent.new()
	hurtbox.team = CombatTypes.Team.PLAYER
	hurtbox.health_component = health

	var sm: StateMachine = StateMachine.new()
	var idle_state: PlayerIdleState = PlayerIdleState.new()
	var move_state: PlayerMoveState = PlayerMoveState.new()
	var dodge_state: PlayerDodgeState = PlayerDodgeState.new()
	var attack_state: PlayerAttackState = PlayerAttackState.new()
	var hurt_state: PlayerHurtState = PlayerHurtState.new()
	idle_state.name = "IdleState"
	move_state.name = "MoveState"
	dodge_state.name = "DodgeState"
	attack_state.name = "AttackState"
	hurt_state.name = "HurtState"

	idle_state.movement_component = movement
	idle_state.input_component = input_comp
	idle_state.dodge_state = dodge_state
	move_state.movement_component = movement
	move_state.input_component = input_comp
	move_state.dodge_state = dodge_state
	dodge_state.movement_component = movement
	dodge_state.input_component = input_comp
	dodge_state.config = config
	dodge_state.health_component = health
	attack_state.movement_component = movement
	attack_state.input_component = input_comp
	attack_state.combat_style_component = style_comp
	attack_state.hitbox_component = hitbox
	attack_state.weapon_pivot = weapon_pivot
	attack_state.dodge_state = dodge_state
	hurt_state.movement_component = movement
	hurt_state.input_component = input_comp
	hurt_state.config = config

	sm.add_child(idle_state)
	sm.add_child(move_state)
	sm.add_child(dodge_state)
	sm.add_child(attack_state)
	sm.add_child(hurt_state)
	sm.initial_state = idle_state
	sm.initialize()

	return {
		"movement": movement, "input": input_comp, "style": style_comp,
		"pivot": weapon_pivot, "hitbox": hitbox, "hurtbox": hurtbox,
		"health": health, "sm": sm, "dodge": dodge_state,
		"attack": attack_state, "hurt": hurt_state,
	}


func _free_combat_rig(rig: Dictionary) -> void:
	(rig["sm"] as StateMachine).free()
	(rig["hurtbox"] as HurtboxComponent).free()
	(rig["health"] as HealthComponent).free()
	(rig["pivot"] as Node2D).free()
	(rig["style"] as CombatStyleComponent).free()
	(rig["input"] as PlayerInputComponent).free()
	(rig["movement"] as MovementComponent).free()


func _test_single_hit_per_swing_and_multitarget_sc001(results: Array[String], failures: Array[String]) -> void:
	var hitbox: HitboxComponent = HitboxComponent.new()
	var hp1: HealthComponent = HealthComponent.new()
	hp1.post_hit_invulnerability_duration = 0.0
	hp1.reset_health()
	var hb1: HurtboxComponent = HurtboxComponent.new()
	hb1.team = CombatTypes.Team.ENEMY
	hb1.health_component = hp1

	var hp2: HealthComponent = HealthComponent.new()
	hp2.post_hit_invulnerability_duration = 0.0
	hp2.reset_health()
	var hb2: HurtboxComponent = HurtboxComponent.new()
	hb2.team = CombatTypes.Team.ENEMY
	hb2.health_component = hp2

	var atk: AttackData = AttackData.new()
	atk.base_damage = 25.0
	atk.team = CombatTypes.Team.PLAYER
	hitbox.activate(atk)

	var first_hit: bool = hitbox.try_hit_hurtbox(hb1)
	var duplicate_hit_same_frame: bool = hitbox.try_hit_hurtbox(hb1)
	var second_target_hit: bool = hitbox.try_hit_hurtbox(hb2)

	_assert_true(
		first_hit and not duplicate_hit_same_frame and is_equal_approx(hp1.current_health, 75.0),
		"SC-001 / EC-001: Um mesmo golpe ativo atinge o mesmo Hurtbox exatamente 1 vez (75.0 HP restante)",
		results,
		failures
	)
	_assert_true(
		second_target_hit and is_equal_approx(hp2.current_health, 75.0),
		"EC-002: A mesma Hitbox ativa consegue atingir um segundo alvo distinto no mesmo golpe",
		results,
		failures
	)

	hitbox.free()
	hb1.free()
	hp1.free()
	hb2.free()
	hp2.free()


func _test_dodge_and_post_hit_iframes_block_damage_sc003(results: Array[String], failures: Array[String]) -> void:
	var rig: Dictionary = _build_combat_rig()
	var sm: StateMachine = rig["sm"] as StateMachine
	var input_comp: PlayerInputComponent = rig["input"] as PlayerInputComponent
	var hurtbox: HurtboxComponent = rig["hurtbox"] as HurtboxComponent
	var health: HealthComponent = rig["health"] as HealthComponent

	input_comp.register_dodge_press()
	sm._physics_process(0.016) # Entra em DodgeState com i-frames ativos

	var enemy_atk: AttackData = AttackData.new()
	enemy_atk.base_damage = 30.0
	enemy_atk.team = CombatTypes.Team.ENEMY
	var res_during_dodge: Dictionary = hurtbox.receive_attack(enemy_atk)

	_assert_true(
		not bool(res_during_dodge.get("applied", true)) and is_equal_approx(health.current_health, 100.0),
		"SC-003 / RF-003: Ataque inimigo durante i-frames do DodgeState causa ZERO perda de vida",
		results,
		failures
	)

	sm._physics_process(0.30) # Sai do DodgeState (vulnerável)
	var res_vulnerable: Dictionary = hurtbox.receive_attack(enemy_atk)
	var res_post_hit_iframe: Dictionary = hurtbox.receive_attack(enemy_atk)

	_assert_true(
		bool(res_vulnerable.get("applied", false)) and not bool(res_post_hit_iframe.get("applied", true)) and is_equal_approx(health.current_health, 70.0),
		"SC-003 / RF-008: Ataque fora de i-frames aplica dano e ativa i-frames pós-dano que bloqueiam golpe subsequente",
		results,
		failures
	)
	_free_combat_rig(rig)


func _test_combo_chain_fast_vs_heavy_rf006(results: Array[String], failures: Array[String]) -> void:
	var rig: Dictionary = _build_combat_rig()
	var sm: StateMachine = rig["sm"] as StateMachine
	var input_comp: PlayerInputComponent = rig["input"] as PlayerInputComponent
	var attack_state: PlayerAttackState = rig["attack"] as PlayerAttackState

	input_comp.register_attack_press()
	sm._physics_process(0.016) # Entra em AttackState Golpe #1 (WINDUP)
	sm._physics_process(0.07)  # Entra em ACTIVE do Golpe #1
	input_comp.register_attack_press() # Bufferiza Golpe #2 durante ACTIVE
	sm._physics_process(0.09)  # Entra em RECOVERY do Golpe #1
	sm._physics_process(0.12)  # Avança para Golpe #2

	_assert_true(
		sm.get_current_state_name() == &"AttackState" and attack_state.current_step_index == 1,
		"RF-006: Input Buffer durante ataque encadeia automaticamente o próximo golpe do combo (#1 -> #2)",
		results,
		failures
	)
	_free_combat_rig(rig)


func _test_dodge_cancel_windows_rf007(results: Array[String], failures: Array[String]) -> void:
	var rig: Dictionary = _build_combat_rig()
	var sm: StateMachine = rig["sm"] as StateMachine
	var input_comp: PlayerInputComponent = rig["input"] as PlayerInputComponent
	var hitbox: HitboxComponent = rig["hitbox"] as HitboxComponent

	input_comp.register_attack_press()
	sm._physics_process(0.016) # AttackState WINDUP
	sm._physics_process(0.07)  # Avança para ACTIVE (hitbox ligada)

	# Tenta esquivar no meio da fase ACTIVE: deve permanecer em AttackState durante ACTIVE, mas reter no buffer
	input_comp.register_dodge_press()
	sm._physics_process(0.02)
	var locked_during_active: bool = sm.get_current_state_name() == &"AttackState"

	# Conclui o restante de ACTIVE (0.07s): ao entrar em RECOVERY, deve disparar Dodge Cancel imediatamente!
	sm._physics_process(0.07)
	_assert_true(
		locked_during_active and sm.get_current_state_name() == &"DodgeState" and not hitbox.is_active(),
		"RF-007 / EC-004: Dodge Cancel é bloqueado durante ACTIVE, mas dispara do buffer no 1º frame de RECOVERY desligando a Hitbox",
		results,
		failures
	)
	_free_combat_rig(rig)


func _test_hurt_state_aborts_attack_and_deactivates_hitbox_ec003(results: Array[String], failures: Array[String]) -> void:
	var rig: Dictionary = _build_combat_rig()
	var sm: StateMachine = rig["sm"] as StateMachine
	var input_comp: PlayerInputComponent = rig["input"] as PlayerInputComponent
	var hitbox: HitboxComponent = rig["hitbox"] as HitboxComponent
	var hurt_state: PlayerHurtState = rig["hurt"] as PlayerHurtState

	input_comp.register_attack_press()
	sm._physics_process(0.016)
	sm._physics_process(0.07) # ACTIVE com hitbox ligada

	hurt_state.setup_knockback(Vector2.LEFT * 200.0)
	sm.transition_to(&"HurtState")

	_assert_true(
		sm.get_current_state_name() == &"HurtState" and not hitbox.is_active(),
		"EC-003 / RF-008: Transição para PlayerHurtState aborta AttackState e desliga imediatamente a HitboxComponent",
		results,
		failures
	)
	_free_combat_rig(rig)


func _test_tagged_invulnerability_leases_rf008(results: Array[String], failures: Array[String]) -> void:
	var hp: HealthComponent = HealthComponent.new()
	hp.reset_health()

	var initial_invuln: bool = hp.is_invulnerable()
	hp.grant_invulnerability(&"dodge", 0.16)
	hp.grant_invulnerability(&"hit_recovery", 0.60)

	var both_active: bool = (
		hp.is_invulnerable()
		and hp.is_invulnerable(&"dodge")
		and hp.is_invulnerable(&"hit_recovery")
		and not hp.is_invulnerable(&"stagger_buff")
	)
	var durations_valid: bool = (
		is_equal_approx(hp.get_invulnerability_remaining(&"dodge"), 0.16)
		and is_equal_approx(hp.get_invulnerability_remaining(&"hit_recovery"), 0.60)
		and is_equal_approx(hp.get_invulnerability_remaining(), 0.60)
	)

	# Concurrent duration handling: dodge expires at 0.20s, but hit_recovery remains active
	hp._process(0.20)
	var dodge_expired_recovery_active: bool = (
		hp.is_invulnerable()
		and not hp.is_invulnerable(&"dodge")
		and hp.is_invulnerable(&"hit_recovery")
		and is_equal_approx(hp.get_invulnerability_remaining(&"hit_recovery"), 0.40)
	)

	# Piercing check: an attack that pierces 'dodge' is still blocked while 'hit_recovery' is active
	var pierced_dodge_safe: bool = hp.is_invulnerable_against([&"dodge"])
	var pierced_all_hits: bool = not hp.is_invulnerable_against([&"dodge", &"hit_recovery"])

	# Re-grant tag with longer duration: max duration is preserved
	hp.grant_invulnerability(&"hit_recovery", 0.80)
	var max_extended: bool = is_equal_approx(hp.get_invulnerability_remaining(&"hit_recovery"), 0.80)

	# Explicit tag revocation
	hp.revoke_invulnerability(&"hit_recovery")
	var fully_vulnerable: bool = not hp.is_invulnerable() and not hp.is_invulnerable(&"hit_recovery")

	hp.free()

	_assert_true(
		not initial_invuln and both_active and durations_valid,
		"RF-008 / Issue #23: Leases de invulnerabilidade com tags concorrentes coexistem em HealthComponent",
		results,
		failures
	)
	_assert_true(
		dodge_expired_recovery_active and pierced_dodge_safe and pierced_all_hits and max_extended and fully_vulnerable,
		"RF-008 / Issue #23: Expiração e revogação de tags concorrentes preserva leases remanescentes e respeita piercing",
		results,
		failures
	)
