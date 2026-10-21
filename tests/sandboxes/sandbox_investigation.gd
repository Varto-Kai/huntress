extends Node2D
## Cena Sandbox Greybox de Investigação e Grimório Dinâmico (SPEC-003: RF-009, SC-003).
## Integra coleta de pistas físicas (autênticas e falsas), julgamento manual no Grimório,
## Fórmula de Materiais do Óleo Fabricável e combate tático contra alvos inicialmente desconhecidos ('???').

@onready var player: Player = $Player as Player
@onready var armored_dummy: CombatDummy = $ArmoredDummy as CombatDummy
@onready var agile_dummy: CombatDummy = $AgileDummy as CombatDummy
@onready var grimoire_ui: GrimoireUIGreybox = $CanvasLayer/GrimoireUIGreybox as GrimoireUIGreybox
@onready var telemetry_label: Label = $CanvasLayer/TelemetryPanel/TelemetryLabel as Label

var _last_event_log: String = "Explore as pistas e pressione [E] para inspecionar."


func _ready() -> void:
	if player != null and grimoire_ui != null:
		grimoire_ui.bind_components(
			player.grimoire_component,
			player.input_component,
			player.health_component
		)
	if player != null and player.grimoire_component != null:
		player.grimoire_component.entry_updated.connect(_on_grimoire_entry_updated)
		player.grimoire_component.monster_research_completed.connect(_on_monster_research_completed)
	if armored_dummy != null:
		armored_dummy.dummy_hit_logged.connect(_on_dummy_hit_logged)
	if agile_dummy != null:
		agile_dummy.dummy_hit_logged.connect(_on_dummy_hit_logged)


func _process(_delta: float) -> void:
	if player == null or telemetry_label == null:
		return

	var style_name: String = "N/A"
	var oil_name: String = "N/A"
	if player.combat_style_component != null:
		style_name = player.combat_style_component.get_active_style().style_name
		oil_name = CombatTypes.get_oil_display_name(player.combat_style_component.active_oil)

	var focused_name: String = "Nenhuma em alcance"
	if player.interaction_component != null and player.interaction_component.focused_clue != null:
		var fc: InteractableClue = player.interaction_component.focused_clue
		focused_name = fc.clue_data.title if fc.clue_data != null else "Vestígio"

	var grimoire_status: String = "ABERTO (Inputs de combate bloqueados)" if (grimoire_ui != null and grimoire_ui.is_grimoire_open) else "FECHADO"

	telemetry_label.text = (
		"=== HUNTRESS SANDBOX: SPEC-003 (INVESTIGAÇÃO, PISTAS FALSAS & GRIMÓRIO) ===\n"
		+ "[WASD] Mover | [E] Inspecionar (0.5s) | [G/Tab] Grimório | [Q] Estilo | [R] Óleo | [J] Atacar | [Espaço] Esquivar\n"
		+ "Pista em Foco : %s  |  Grimório: %s\n"
		+ "Build Equipada: %s + %s  |  Evento: %s"
	) % [focused_name, grimoire_status, style_name, oil_name, _last_event_log]


func _on_grimoire_entry_updated(monster_id: StringName, state: Dictionary) -> void:
	if armored_dummy != null and armored_dummy.monster_id == monster_id:
		armored_dummy.apply_grimoire_state(state)
	if agile_dummy != null and agile_dummy.monster_id == monster_id:
		agile_dummy.apply_grimoire_state(state)
	_last_event_log = "Grimório atualizado para [%s]" % String(state.get("display_name", monster_id))


func _on_monster_research_completed(monster_id: StringName) -> void:
	_last_event_log = "✅ Dedução 100%% precisa concluída para [%s]!" % String(monster_id)


func _on_dummy_hit_logged(dummy_name: String, resolution: Dictionary) -> void:
	var dmg: float = float(resolution.get("final_damage", 0.0))
	var matchup: CombatTypes.MatchupResult = int(resolution.get("matchup", 1)) as CombatTypes.MatchupResult
	_last_event_log = "Golpe em [%s]: %.1f Dano [%s]" % [dummy_name, dmg, CombatTypes.get_matchup_display_name(matchup)]
