class_name GrimoireUIGreybox
extends Control
## Interface Greybox do Grimório em Tempo Real Tático (Q3) com suporte a
## Julgamento Manual de Pistas Falsas (Q5 / toggle_clue_discarded), Síntese de Estilo,
## Fórmula de Materiais do Óleo Fabricável e Banner Toast de descoberta (SPEC-003: RF-006, RF-007, RF-008).

signal grimoire_visibility_changed(is_open: bool)

@export var pause_tree_on_open: bool = false
@export_range(0.5, 10.0, 0.25, "suffix:s") var notification_display_duration: float = 3.2

var grimoire_component: GrimoireComponent
var input_component: PlayerInputComponent
var selected_monster_id: StringName = &"armored_carapace"
var is_grimoire_open: bool = false

var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_timer: float = 0.0
var _main_panel: PanelContainer
var _monster_tabs_box: HBoxContainer
var _synthesis_label: Label
var _clues_vbox: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_greybox_layout()
	set_grimoire_open(false)


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer = maxf(0.0, _toast_timer - delta)
		if _toast_timer <= 0.0 and _toast_panel != null:
			_toast_panel.visible = false


func bind_components(p_grimoire: GrimoireComponent, p_input: PlayerInputComponent, p_health: HealthComponent) -> void:
	grimoire_component = p_grimoire
	input_component = p_input
	if grimoire_component != null:
		if not grimoire_component.clue_discovered.is_connected(_on_clue_discovered):
			grimoire_component.clue_discovered.connect(_on_clue_discovered)
		if not grimoire_component.entry_updated.is_connected(_on_entry_updated):
			grimoire_component.entry_updated.connect(_on_entry_updated)
	if input_component != null and not input_component.grimoire_toggle_requested.is_connected(toggle_grimoire):
		input_component.grimoire_toggle_requested.connect(toggle_grimoire)
	if p_health != null and not p_health.damaged.is_connected(_on_player_damaged):
		p_health.damaged.connect(_on_player_damaged)
	_rebuild_monster_tabs()
	refresh_ui()


func toggle_grimoire() -> void:
	set_grimoire_open(not is_grimoire_open)


func set_grimoire_open(open_state: bool) -> void:
	is_grimoire_open = open_state
	if _main_panel != null:
		_main_panel.visible = is_grimoire_open
	mouse_filter = Control.MOUSE_FILTER_STOP if is_grimoire_open else Control.MOUSE_FILTER_IGNORE
	if input_component != null:
		input_component.set_gameplay_inputs_blocked(is_grimoire_open)
	if is_inside_tree() and pause_tree_on_open:
		get_tree().paused = is_grimoire_open
	if is_grimoire_open:
		refresh_ui()
	grimoire_visibility_changed.emit(is_grimoire_open)


func show_toast(message: String) -> void:
	if _toast_label == null or _toast_panel == null:
		return
	_toast_label.text = message
	_toast_panel.visible = true
	_toast_timer = notification_display_duration


func refresh_ui() -> void:
	if grimoire_component == null or _synthesis_label == null or _clues_vbox == null:
		return
	var state: Dictionary = grimoire_component.get_monster_state(selected_monster_id)
	var style_sec: Dictionary = state.get("style_section", {}) as Dictionary
	var oil_sec: Dictionary = state.get("oil_section", {}) as Dictionary
	var beh_sec: Dictionary = state.get("behavior_section", {}) as Dictionary
	var solved: bool = bool(state.get("deduction_solved", false))
	var style_warn: String = " [⚠️ Conflito!]" if bool(style_sec.get("has_conflict", false)) else ""
	var oil_warn: String = " [⚠️ Conflito!]" if bool(oil_sec.get("has_conflict", false)) else ""
	var banner: String = "✅ DEDUÇÃO CONCLUÍDA" if solved else "🔍 EM INVESTIGAÇÃO (Descarte pistas falsas)"

	_synthesis_label.text = (
		"📖 %s — %s (%d/%d Pistas) | %s\n"
		+ "• Postura Recomendada: %s | Evitar: %s%s\n"
		+ "• Fraqueza Alquímica: %s | Receita: %s%s\n"
		+ "• Comportamento & Stagger: %s"
	) % [
		String(state.get("display_name", "???")), String(state.get("subtitle", "???")),
		int(state.get("discovered_count", 0)), int(state.get("total_clues", 0)), banner,
		String(style_sec.get("style_weakness_text", "???")), String(style_sec.get("style_resistance_text", "???")), style_warn,
		String(oil_sec.get("element_weakness_text", "???")), String(oil_sec.get("oil_recipe_text", "???")), oil_warn,
		String(beh_sec.get("behavior_text", "???")),
	]

	for child: Node in _clues_vbox.get_children():
		child.queue_free()

	var discovered: Array[ClueData] = grimoire_component.tracker.get_discovered_clues_for_monster(selected_monster_id)
	for clue: ClueData in discovered:
		_add_clue_row(clue)


func _add_clue_row(clue: ClueData) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var discarded: bool = grimoire_component.tracker.is_clue_discarded(clue.clue_id)
	var info_lbl: Label = Label.new()
	info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_lbl.add_theme_font_size_override("font_size", 9)
	var prefix: String = "[DESCARTADA] " if discarded else "[ATIVA] "
	info_lbl.text = "%s%s (%s): %s" % [prefix, clue.title, GrimoireTypes.get_section_title(clue.section_type), clue.evidence_description]
	info_lbl.modulate = Color(0.6, 0.6, 0.6, 0.85) if discarded else Color(0.95, 0.95, 0.95, 1.0)

	var btn: Button = Button.new()
	btn.add_theme_font_size_override("font_size", 9)
	btn.text = "Restaurar Pista" if discarded else "Descartar Pista"
	var cid: StringName = clue.clue_id
	var mid: StringName = clue.monster_id
	btn.pressed.connect(func() -> void: grimoire_component.toggle_clue_discard(cid, mid))
	row.add_child(info_lbl)
	row.add_child(btn)
	_clues_vbox.add_child(row)


func _build_greybox_layout() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.visible = false
	_toast_panel.position = Vector2(180.0, 8.0)
	_toast_panel.size = Vector2(448.0, 34.0)
	_toast_label = Label.new()
	_toast_label.add_theme_font_size_override("font_size", 9)
	_toast_panel.add_child(_toast_label)
	add_child(_toast_panel)

	_main_panel = PanelContainer.new()
	_main_panel.position = Vector2(36.0, 24.0)
	_main_panel.size = Vector2(568.0, 312.0)
	var root_vbox: VBoxContainer = VBoxContainer.new()
	_main_panel.add_child(root_vbox)
	_monster_tabs_box = HBoxContainer.new()
	root_vbox.add_child(_monster_tabs_box)
	_synthesis_label = Label.new()
	_synthesis_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_synthesis_label.add_theme_font_size_override("font_size", 9)
	root_vbox.add_child(_synthesis_label)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_clues_vbox = VBoxContainer.new()
	_clues_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_clues_vbox)
	root_vbox.add_child(scroll)
	add_child(_main_panel)


func _rebuild_monster_tabs() -> void:
	if _monster_tabs_box == null or grimoire_component == null:
		return
	for child: Node in _monster_tabs_box.get_children():
		child.queue_free()
	for mid: StringName in grimoire_component.tracker.get_registered_monster_ids():
		var entry: MonsterGrimoireEntryData = grimoire_component.tracker.get_entry(mid)
		var btn: Button = Button.new()
		btn.add_theme_font_size_override("font_size", 9)
		btn.text = entry.display_name if entry != null else String(mid)
		var target_id: StringName = mid
		btn.pressed.connect(func() -> void:
			selected_monster_id = target_id
			refresh_ui()
		)
		_monster_tabs_box.add_child(btn)


func _on_clue_discovered(clue_data: ClueData, is_new: bool) -> void:
	selected_monster_id = clue_data.monster_id
	var tag: String = "Nova Pista no Grimório [G/Tab]" if is_new else "Pista Revisitada [G/Tab]"
	show_toast("🔎 %s: %s (%s)" % [tag, clue_data.title, GrimoireTypes.get_section_title(clue_data.section_type)])
	if is_grimoire_open:
		refresh_ui()


func _on_entry_updated(_monster_id: StringName, _state: Dictionary) -> void:
	if is_grimoire_open:
		refresh_ui()


func _on_player_damaged(_amount: float, _kb: Vector2, _matchup: int) -> void:
	if is_grimoire_open:
		set_grimoire_open(false)
		show_toast("⚠️ Grimório fechado automaticamente ao sofrer ataque!")
