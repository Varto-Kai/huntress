extends Node2D
## Cena Sandbox Greybox de Investigação e Grimório Dinâmico (SPEC-003: RF-009, SC-003).
## Barra superior de telemetria compacta que se oculta quando o Grimório está aberto,
## evitando qualquer sobreposição de textos na arena.

@onready var player: Player = $Player as Player
@onready var armored_dummy: CombatDummy = $ArmoredDummy as CombatDummy
@onready var agile_dummy: CombatDummy = $AgileDummy as CombatDummy
@onready var grimoire_ui: GrimoireUIGreybox = $CanvasLayer/GrimoireUIGreybox as GrimoireUIGreybox
@onready var telemetry_panel: ColorRect = $CanvasLayer/TelemetryPanel as ColorRect
@onready var telemetry_label: Label = $CanvasLayer/TelemetryPanel/TelemetryLabel as Label

var _last_event_log: String = "Aproxime-se de uma pista e pressione [E]"


func _ready() -> void:
	if player != null and grimoire_ui != null:
		grimoire_ui.bind_components(
			player.grimoire_component,
			player.input_component,
			player.health_component
		)
		grimoire_ui.grimoire_visibility_changed.connect(_on_grimoire_visibility_changed)
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

	var focused_name: String = "Nenhuma"
	if player.interaction_component != null and player.interaction_component.focused_clue != null:
		var fc: InteractableClue = player.interaction_component.focused_clue
		focused_name = fc.clue_data.title if fc.clue_data != null else "Vestígio"

	telemetry_label.text = (
		"[WASD] Mover | [E] Inspecionar | [G/Tab] Grimório | [Q] Estilo | [R] Óleo | [J] Atacar | [Espaço] Esquivar\n"
		+ "Build: %s + %s  |  Em Alcance: %s  |  %s"
	) % [style_name, oil_name, focused_name, _last_event_log]


func _on_grimoire_visibility_changed(is_open: bool) -> void:
	if telemetry_panel != null:
		telemetry_panel.visible = not is_open


func _on_grimoire_entry_updated(monster_id: StringName, state: Dictionary) -> void:
	if armored_dummy != null and armored_dummy.monster_id == monster_id:
		armored_dummy.apply_grimoire_state(state)
	if agile_dummy != null and agile_dummy.monster_id == monster_id:
		agile_dummy.apply_grimoire_state(state)
	_last_event_log = "Grimório atualizado: %s" % String(state.get("display_name", monster_id))


func _on_monster_research_completed(monster_id: StringName) -> void:
	_last_event_log = "✅ Dedução 100%% concluída: %s!" % String(monster_id)


func _on_dummy_hit_logged(dummy_name: String, resolution: Dictionary) -> void:
	var dmg: float = float(resolution.get("final_damage", 0.0))
	var matchup: CombatTypes.MatchupResult = int(resolution.get("matchup", 1)) as CombatTypes.MatchupResult
	_last_event_log = "%s: -%.1f HP [%s]" % [dummy_name, dmg, CombatTypes.get_matchup_display_name(matchup)]
