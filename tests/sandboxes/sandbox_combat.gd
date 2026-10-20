extends Node2D
## Cena Sandbox Greybox de Combate para validação rápida (< 30s) da SPEC-002 (RF-010, SC-001 a SC-004).
## Exibe telemetria de Estilo, Combo, Óleo, HP/i-frames e log de impacto contra os Bonecos de Treino.

@onready var player: Player = $Player as Player
@onready var armored_dummy: CombatDummy = $ArmoredDummy as CombatDummy
@onready var agile_dummy: CombatDummy = $AgileDummy as CombatDummy
@onready var telemetry_label: Label = $CanvasLayer/TelemetryPanel/TelemetryLabel as Label

var _last_combat_event: String = "Nenhum golpe registrado ainda."


func _ready() -> void:
	if armored_dummy != null:
		armored_dummy.dummy_hit_logged.connect(_on_dummy_hit_logged)
	if agile_dummy != null:
		agile_dummy.dummy_hit_logged.connect(_on_dummy_hit_logged)
	if player != null and player.hurtbox_component != null:
		player.hurtbox_component.hit_ignored.connect(_on_player_hit_ignored)
		player.hurtbox_component.hit_received.connect(_on_player_hit_received)


func _process(_delta: float) -> void:
	if player == null or telemetry_label == null:
		return

	var state_name: String = String(player.state_machine.get_current_state_name())
	var style_name: String = "N/A"
	var oil_name: String = "N/A"
	if player.combat_style_component != null:
		var style: CombatStyleData = player.combat_style_component.get_active_style()
		style_name = style.style_name
		oil_name = CombatTypes.get_oil_display_name(player.combat_style_component.active_oil)

	var attack_info: String = "Inativo"
	if state_name == "AttackState" and player.attack_state != null:
		var step_num: int = player.attack_state.current_step_index + 1
		var phase_str: String = String(player.attack_state.get_phase_name())
		attack_info = "Golpe #%d [%s]" % [step_num, phase_str]

	var hp_curr: float = player.health_component.current_health if player.health_component != null else 100.0
	var hp_max: float = player.health_component.max_health if player.health_component != null else 100.0
	var iframes_status: String = "VULNERÁVEL"
	if player.dodge_state != null and player.dodge_state.is_invulnerable():
		iframes_status = "DODGE i-frames (Imune)"
	elif player.health_component != null and player.health_component.is_invulnerable():
		iframes_status = "PÓS-DANO i-frames (%.2fs)" % player.health_component.get_invulnerability_remaining()

	telemetry_label.text = (
		"=== HUNTRESS GREYBOX SANDBOX: SPEC-002 (COMBATE & FRAQUEZAS) ===\n"
		+ "[WASD] Mover | [J / Clique Esq] Atacar | [Espaço] Esquivar | [Q] Trocar Estilo | [E] Trocar Óleo\n"
		+ "------------------------------------------------------------------------------------\n"
		+ "HP da Caçadora : %.0f / %.0f  |  Defesa: %s  |  Estado: %s\n"
		+ "Estilo Ativo   : %s  |  Fase de Ataque: %s\n"
		+ "Óleo na Lâmina : %s\n"
		+ "Último Evento  : %s"
	) % [
		hp_curr,
		hp_max,
		iframes_status,
		state_name,
		style_name,
		attack_info,
		oil_name,
		_last_combat_event,
	]


func _on_dummy_hit_logged(dummy_name: String, resolution: Dictionary) -> void:
	var dmg: float = float(resolution.get("final_damage", 0.0))
	var stg: float = float(resolution.get("final_stagger_damage", 0.0))
	var matchup: CombatTypes.MatchupResult = int(resolution.get("matchup", 1)) as CombatTypes.MatchupResult
	var matchup_str: String = CombatTypes.get_matchup_display_name(matchup)
	_last_combat_event = "Acertou [%s] -> %.1f Dano | +%.1f Stagger [%s]" % [dummy_name, dmg, stg, matchup_str]


func _on_player_hit_ignored(_attack_data: AttackData) -> void:
	_last_combat_event = "✨ ATAQUE INIMIGO ESQUIVADO! (Ignorado por i-frames)"


func _on_player_hit_received(_attack_data: AttackData, resolution: Dictionary) -> void:
	var dmg: float = float(resolution.get("final_damage", 0.0))
	_last_combat_event = "💥 CAÇADORA ATINGIDA! -%.1f HP -> Entrou em PlayerHurtState (+i-frames)" % dmg
