class_name TestMovementMath
extends RefCounted
## Testes unitários de matemática de locomoção, normalização diagonal,
## anulação de eixos opostos, perda de foco e proporção Top-Down (T009: RF-001, RF-002, EC-001, EC-005, EC-006, SC-001).


func run_all() -> Dictionary:
	var results: Array[String] = []
	var failures: Array[String] = []

	_test_diagonal_normalization_sc001(results, failures)
	_test_opposite_inputs_cancel_ec001(results, failures)
	_test_window_focus_loss_ec005(results, failures)
	_test_acceleration_and_friction_rf002(results, failures)
	_test_y_axis_speed_ratio_ec006(results, failures)
	_test_config_sanitization_rf008(results, failures)

	return {
		"passed": results.size(),
		"failed": failures.size(),
		"results": results,
		"failures": failures,
	}


func _assert_true(condition: bool, message: String, results: Array[String], failures: Array[String]) -> void:
	if condition:
		results.append("PASS: " + message)
	else:
		failures.append("FAIL: " + message)


func _test_diagonal_normalization_sc001(results: Array[String], failures: Array[String]) -> void:
	var cardinal_dir: Vector2 = PlayerInputComponent.compute_normalized_direction(false, true, false, false)
	var diagonal_dir: Vector2 = PlayerInputComponent.compute_normalized_direction(false, true, true, false)

	var config: PlayerMovementConfig = PlayerMovementConfig.new()
	config.max_speed = 200.0
	config.y_axis_speed_ratio = 1.0

	var comp: MovementComponent = MovementComponent.new()
	comp.setup(null, config)

	var cardinal_speed: float = comp.compute_target_velocity(cardinal_dir, config.max_speed).length()
	var diagonal_speed: float = comp.compute_target_velocity(diagonal_dir, config.max_speed).length()
	var variation_pct: float = absf(diagonal_speed - cardinal_speed) / cardinal_speed * 100.0

	_assert_true(
		variation_pct <= 0.01,
		"SC-001: Velocidade diagonal (%.4f) tem variação <= 0.01%% em relação à cardinal (%.4f)" % [diagonal_speed, cardinal_speed],
		results,
		failures
	)
	comp.free()


func _test_opposite_inputs_cancel_ec001(results: Array[String], failures: Array[String]) -> void:
	var horiz_cancel: Vector2 = PlayerInputComponent.compute_normalized_direction(true, true, false, false)
	var vert_cancel: Vector2 = PlayerInputComponent.compute_normalized_direction(false, false, true, true)
	var all_cancel: Vector2 = PlayerInputComponent.compute_normalized_direction(true, true, true, true)
	var horiz_cancel_with_up: Vector2 = PlayerInputComponent.compute_normalized_direction(true, true, true, false)

	_assert_true(
		horiz_cancel == Vector2.ZERO and vert_cancel == Vector2.ZERO and all_cancel == Vector2.ZERO,
		"EC-001: Entradas opostas simultâneas se anulam exatamente para Vector2.ZERO",
		results,
		failures
	)
	_assert_true(
		horiz_cancel_with_up == Vector2.UP,
		"EC-001: Esquerda+Direita+Cima resulta exatamente em Vector2.UP sem desvio lateral",
		results,
		failures
	)


func _test_window_focus_loss_ec005(results: Array[String], failures: Array[String]) -> void:
	var input_comp: PlayerInputComponent = PlayerInputComponent.new()
	input_comp.move_direction = Vector2.RIGHT
	input_comp.register_dodge_press()
	input_comp.on_window_focus_lost()

	_assert_true(
		input_comp.move_direction == Vector2.ZERO and not input_comp.has_buffered_dodge(),
		"EC-005: Perda de foco da janela zera move_direction e limpa o buffer de esquiva",
		results,
		failures
	)
	input_comp.free()


func _test_acceleration_and_friction_rf002(results: Array[String], failures: Array[String]) -> void:
	var config: PlayerMovementConfig = PlayerMovementConfig.new()
	config.max_speed = 200.0
	config.acceleration = 1000.0
	config.friction = 1000.0

	var comp: MovementComponent = MovementComponent.new()
	comp.setup(null, config)

	var v1: Vector2 = comp.accelerate_in_direction(Vector2.RIGHT, 0.1)
	var v2: Vector2 = comp.accelerate_in_direction(Vector2.RIGHT, 0.15)
	var v3: Vector2 = comp.apply_friction(0.1)
	var v4: Vector2 = comp.apply_friction(0.15)

	_assert_true(
		is_equal_approx(v1.x, 100.0) and is_equal_approx(v2.x, 200.0),
		"RF-002: Aceleração progressiva respeita taxa e teto max_speed (200.0 px/s)",
		results,
		failures
	)
	_assert_true(
		is_equal_approx(v3.x, 100.0) and v4 == Vector2.ZERO,
		"RF-002: Desaceleração por atrito reduz velocidade progressivamente até parar em Vector2.ZERO",
		results,
		failures
	)
	comp.free()


func _test_y_axis_speed_ratio_ec006(results: Array[String], failures: Array[String]) -> void:
	var config: PlayerMovementConfig = PlayerMovementConfig.new()
	config.max_speed = 200.0
	config.y_axis_speed_ratio = 0.75

	var comp: MovementComponent = MovementComponent.new()
	comp.setup(null, config)

	var vel_down: Vector2 = comp.compute_target_velocity(Vector2.DOWN, config.max_speed)
	_assert_true(
		is_equal_approx(vel_down.y, 150.0),
		"EC-006: y_axis_speed_ratio escala corretamente a componente vertical da velocidade",
		results,
		failures
	)
	comp.free()


func _test_config_sanitization_rf008(results: Array[String], failures: Array[String]) -> void:
	var config: PlayerMovementConfig = PlayerMovementConfig.new()
	config.dodge_duration = 0.20
	config.invulnerability_duration = 0.50
	config.default_facing_direction = Vector2.ZERO
	config.sanitize()

	_assert_true(
		is_equal_approx(config.invulnerability_duration, 0.20) and config.default_facing_direction == Vector2.DOWN,
		"RF-006 / RF-008: Sanitização limita invulnerability_duration <= dodge_duration e impede facing_direction nula",
		results,
		failures
	)
