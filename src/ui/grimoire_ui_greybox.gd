class_name GrimoireUIGreybox
extends Control
## Interface Greybox do Grimório em Tempo Real Tático (Q3) com suporte a modo tela cheia (Investigação)
## e modo acoplado Lado a Lado à esquerda da Bancada de Alquimia na Fogueira (SPEC-003 & SPEC-004: Q3, RF-006).

signal grimoire_visibility_changed(is_open: bool)

@export var pause_tree_on_open: bool = false
@export_range(0.5, 10.0, 0.25, "suffix:s") var notification_display_duration: float = 3.2

var grimoire_component: GrimoireComponent
var input_component: PlayerInputComponent
var selected_monster_id: StringName = &"armored_carapace"
var is_grimoire_open: bool = false
var is_docked_with_bench: bool = false

var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_timer: float = 0.0
var _backdrop: ColorRect
var _main_panel: PanelContainer
var _monster_tabs_box: HBoxContainer
var _content_split: BoxContainer
var _left_card: PanelContainer
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


func set_docked_mode(docked: bool) -> void:
	is_docked_with_bench = docked
	if _main_panel == null or _content_split == null or _left_card == null:
		return
	if is_docked_with_bench:
		_main_panel.position = Vector2(8.0, 10.0)
		_main_panel.size = Vector2(308.0, 340.0)
		_content_split.vertical = true
		_left_card.custom_minimum_size = Vector2(290.0, 118.0)
		_synthesis_label.custom_minimum_size = Vector2(276.0, 0.0)
	else:
		_main_panel.position = Vector2(14.0, 10.0)
		_main_panel.size = Vector2(612.0, 340.0)
		_content_split.vertical = false
		_left_card.custom_minimum_size = Vector2(236.0, 0.0)
		_synthesis_label.custom_minimum_size = Vector2(220.0, 0.0)
	refresh_ui()


func toggle_grimoire() -> void:
	if is_grimoire_open:
		set_docked_mode(false)
		set_grimoire_open(false)
	else:
		set_docked_mode(false)
		set_grimoire_open(true)


func set_grimoire_open(open_state: bool) -> void:
	is_grimoire_open = open_state
	if not is_grimoire_open:
		is_docked_with_bench = false
	if _backdrop != null:
		_backdrop.visible = is_grimoire_open
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
	if _toast_label != null and _toast_panel != null:
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
	var s_warn: String = " [⚠️ CONFLITO]" if bool(style_sec.get("has_conflict", false)) else ""
	var o_warn: String = " [⚠️ CONFLITO]" if bool(oil_sec.get("has_conflict", false)) else ""
	var banner: String = "✅ DEDUÇÃO CONCLUÍDA" if solved else "🔍 EM INVESTIGAÇÃO"

	_synthesis_label.text = (
		"📖 %s (%d/%d) | %s\n"
		+ "⚔️ Postura: %s (Evitar: %s)%s\n"
		+ "🧪 Óleo: %s | %s%s\n"
		+ "⚡ Stagger: %s"
	) % [
		String(state.get("display_name", "???")),
		int(state.get("discovered_count", 0)), int(state.get("total_clues", 0)), banner,
		String(style_sec.get("style_weakness_text", "???")), String(style_sec.get("style_resistance_text", "???")), s_warn,
		String(oil_sec.get("element_weakness_text", "???")), String(oil_sec.get("oil_recipe_text", "???")), o_warn,
		String(beh_sec.get("behavior_text", "???")),
	]

	for child: Node in _clues_vbox.get_children():
		child.queue_free()
	var discovered: Array[ClueData] = grimoire_component.tracker.get_discovered_clues_for_monster(selected_monster_id)
	for clue: ClueData in discovered:
		_add_clue_card(clue)


func _add_clue_card(clue: ClueData) -> void:
	var discarded: bool = grimoire_component.tracker.is_clue_discarded(clue.clue_id)
	var card: PanelContainer = PanelContainer.new()
	var bg: Color = Color(0.08, 0.09, 0.11, 0.9) if discarded else Color(0.12, 0.15, 0.2, 1.0)
	card.add_theme_stylebox_override("panel", _make_box(bg, Color(0.28, 0.34, 0.44, 1.0), 4))
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	var header: HBoxContainer = HBoxContainer.new()
	var title_lbl: Label = Label.new()
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 8)
	title_lbl.text = "%s%s" % ["[DESCARTADA] " if discarded else "🟢 ", clue.title]
	title_lbl.modulate = Color(0.6, 0.6, 0.65, 1.0) if discarded else Color(1.0, 0.88, 0.4, 1.0)
	var btn: Button = Button.new()
	btn.add_theme_font_size_override("font_size", 8)
	btn.text = "Restaurar" if discarded else "Descartar Pista"
	var cid: StringName = clue.clue_id
	var mid: StringName = clue.monster_id
	btn.pressed.connect(func() -> void: grimoire_component.toggle_clue_discard(cid, mid))
	header.add_child(title_lbl)
	header.add_child(btn)
	vbox.add_child(header)

	var desc_lbl: Label = Label.new()
	desc_lbl.custom_minimum_size = Vector2(265.0 if is_docked_with_bench else 315.0, 0.0)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 8)
	desc_lbl.text = clue.evidence_description
	desc_lbl.modulate = Color(0.55, 0.55, 0.6, 0.85) if discarded else Color(0.92, 0.94, 0.98, 1.0)
	vbox.add_child(desc_lbl)
	_clues_vbox.add_child(card)


func _build_greybox_layout() -> void:
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.03, 0.04, 0.06, 0.94)
	add_child(_backdrop)

	_main_panel = PanelContainer.new()
	_main_panel.position = Vector2(14.0, 10.0)
	_main_panel.size = Vector2(612.0, 340.0)
	_main_panel.add_theme_stylebox_override("panel", _make_box(Color(0.07, 0.09, 0.13, 0.99), Color(0.26, 0.34, 0.46, 1.0), 6))
	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 5)
	_main_panel.add_child(root_vbox)

	_monster_tabs_box = HBoxContainer.new()
	_monster_tabs_box.add_theme_constant_override("separation", 4)
	root_vbox.add_child(_monster_tabs_box)

	_content_split = BoxContainer.new()
	_content_split.vertical = false
	_content_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_split.add_theme_constant_override("separation", 6)
	root_vbox.add_child(_content_split)

	_left_card = PanelContainer.new()
	_left_card.custom_minimum_size = Vector2(236.0, 0.0)
	_left_card.add_theme_stylebox_override("panel", _make_box(Color(0.09, 0.11, 0.16, 1.0), Color(0.2, 0.25, 0.34, 1.0), 5))
	_synthesis_label = Label.new()
	_synthesis_label.custom_minimum_size = Vector2(220.0, 0.0)
	_synthesis_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_synthesis_label.add_theme_font_size_override("font_size", 8)
	_left_card.add_child(_synthesis_label)
	_content_split.add_child(_left_card)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_clues_vbox = VBoxContainer.new()
	_clues_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clues_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(_clues_vbox)
	_content_split.add_child(scroll)
	add_child(_main_panel)

	_toast_panel = PanelContainer.new()
	_toast_panel.visible = false
	_toast_panel.position = Vector2(130.0, 326.0)
	_toast_panel.size = Vector2(380.0, 26.0)
	_toast_panel.add_theme_stylebox_override("panel", _make_box(Color(0.05, 0.13, 0.19, 0.96), Color(0.0, 0.82, 1.0, 1.0), 4))
	_toast_label = Label.new()
	_toast_label.add_theme_font_size_override("font_size", 8)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_panel.add_child(_toast_label)
	add_child(_toast_panel)


func _make_box(bg: Color, border: Color, pad: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_content_margin_all(float(pad))
	return sb


func _rebuild_monster_tabs() -> void:
	if _monster_tabs_box == null or grimoire_component == null:
		return
	for child: Node in _monster_tabs_box.get_children():
		child.queue_free()
	for mid: StringName in grimoire_component.tracker.get_registered_monster_ids():
		var entry: MonsterGrimoireEntryData = grimoire_component.tracker.get_entry(mid)
		var btn: Button = Button.new()
		btn.add_theme_font_size_override("font_size", 8)
		btn.text = "📖 " + (entry.display_name if entry != null else String(mid))
		var target_id: StringName = mid
		btn.pressed.connect(func() -> void: selected_monster_id = target_id; refresh_ui())
		_monster_tabs_box.add_child(btn)
	var close_btn: Button = Button.new()
	close_btn.add_theme_font_size_override("font_size", 8)
	close_btn.text = "Fechar [G]"
	close_btn.pressed.connect(func() -> void: set_grimoire_open(false))
	_monster_tabs_box.add_child(close_btn)


func _on_clue_discovered(clue_data: ClueData, is_new: bool) -> void:
	selected_monster_id = clue_data.monster_id
	show_toast("🔎 %s: %s" % ["Nova Pista [G/Tab]" if is_new else "Pista Revisitada [G/Tab]", clue_data.title])
	if is_grimoire_open:
		refresh_ui()


func _on_entry_updated(_monster_id: StringName, _state: Dictionary) -> void:
	if is_grimoire_open:
		refresh_ui()


func _on_player_damaged(_amount: float, _kb: Vector2, _matchup: int) -> void:
	if is_grimoire_open:
		set_grimoire_open(false)
		show_toast("⚠️ Grimório fechado ao sofrer ataque!")
