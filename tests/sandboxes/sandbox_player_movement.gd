extends Node2D
## Cena Sandbox Greybox para validação rápida (< 30s) da SPEC-001 (RF-010, SC-001 a SC-004).
## Exibe telemetria em tempo real de Estado, Velocidade, Orientação, i-frames, Backstep, Cooldown e Input Buffer.

@onready var player: Player = $Player as Player
@onready var telemetry_label: Label = $CanvasLayer/TelemetryPanel/TelemetryLabel as Label


func _process(_delta: float) -> void:
	if player == null or telemetry_label == null:
		return

	var state_name: String = String(player.state_machine.get_current_state_name())
	var vel: Vector2 = player.movement_component.current_velocity
	var speed: float = vel.length()
	var facing: Vector2 = player.movement_component.facing_direction
	var invuln: bool = player.dodge_state.is_invulnerable()
	var backstep: bool = player.dodge_state.is_backstep()
	var cooldown: float = player.dodge_state.get_cooldown_remaining()
	var buffer_rem: float = player.input_component.get_dodge_buffer_time_remaining()

	var dodge_mode_str: String = "N/A"
	if state_name == "DodgeState":
		dodge_mode_str = "BACKSTEP (-facing)" if backstep else "DASH (direcional)"

	var iframes_str: String = "ATIVOS (Azul Ciano)" if invuln else ("RECOVERY VULNERÁVEL (Laranja)" if state_name == "DodgeState" else "Inativos")

	telemetry_label.text = (
		"=== HUNTRESS GREYBOX SANDBOX: SPEC-001 ===\n"
		+ "Controles: [WASD / Setas] Mover | [Espaço / Shift] Esquivar (Dash / Backstep)\n"
		+ "--------------------------------------------------------\n"
		+ "Estado Atual (StateMachine) : %s\n"
		+ "Modo de Esquiva             : %s\n"
		+ "Janela de i-frames (RF-006) : %s\n"
		+ "Velocidade Atual (px/s)     : %.1f px/s  (Vetor: %.1f, %.1f)\n"
		+ "Orientação (facing_dir)     : (%.2f, %.2f)\n"
		+ "Cooldown da Esquiva (RF-007): %.2f s\n"
		+ "Input Buffer (EC-003)       : %.2f s"
	) % [
		state_name,
		dodge_mode_str,
		iframes_str,
		speed,
		vel.x,
		vel.y,
		facing.x,
		facing.y,
		cooldown,
		buffer_rem,
	]
