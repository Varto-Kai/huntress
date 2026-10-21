class_name PreparationUIGreybox
extends Control
## Interface Greybox da Bancada de Alquimia & Loadout acoplada Lado a Lado à direita do Grimório (SPEC-004: Q3, Q4, RF-006, RF-007, EC-003).
## Lista as receitas de forma 100% neutra (sem spoilers) e permite descansar na Fogueira (acionando a Adaptação Silenciosa nos bastidores).

signal bench_visibility_changed(is_open: bool)
signal campfire_rest_requested()

@export var heal_on_campfire_rest: bool = true

var inventory_component: InventoryComponent
var combat_style_component: CombatStyleComponent
var grimoire_ui: GrimoireUIGreybox
var health_component: HealthComponent
var is_bench_open: bool = false

var _bench_panel: PanelContainer
var _reagents_label: Label
var _recipes_vbox: VBoxContainer
var _loadout_label: Label
var _status_feedback_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_bench_layout()
	set_bench_open(false)


func bind_components(
	p_inventory: InventoryComponent,
	p_combat_style: CombatStyleComponent,
	p_grimoire_ui: GrimoireUIGreybox,
	p_health: HealthComponent
) -> void:
	inventory_component = p_inventory
	combat_style_component = p_combat_style
	grimoire_ui = p_grimoire_ui
	health_component = p_health

	if inventory_component != null:
		if not inventory_component.reagent_count_changed.is_connected(_on_inventory_updated):
			inventory_component.reagent_count_changed.connect(_on_inventory_updated)
		if not inventory_component.oil_charges_changed.is_connected(_on_oil_charges_updated):
			inventory_component.oil_charges_changed.connect(_on_oil_charges_updated)
		if not inventory_component.crafting_failed.is_connected(_on_crafting_failed):
			inventory_component.crafting_failed.connect(_on_crafting_failed)
	if combat_style_component != null:
		if not combat_style_component.style_changed.is_connected(_on_style_updated):
			combat_style_component.style_changed.connect(_on_style_updated)
		if not combat_style_component.oil_changed.is_connected(_on_oil_updated):
			combat_style_component.oil_changed.connect(_on_oil_updated)
	if grimoire_ui != null and not grimoire_ui.grimoire_visibility_changed.is_connected(_on_grimoire_visibility_changed):
		grimoire_ui.grimoire_visibility_changed.connect(_on_grimoire_visibility_changed)
	if health_component != null and not health_component.damaged.is_connected(_on_player_damaged):
		health_component.damaged.connect(_on_player_damaged)
	refresh_bench()


func open_at_campfire() -> void:
	if grimoire_ui != null:
		grimoire_ui.set_grimoire_open( true )
		grimoire_ui.set_docked_mode( true )
	set_bench_open( true )


func set_bench_open(open_state: bool) -> void:
	is_bench_open = open_state
	if _bench_panel != null:
		_bench_panel.visible = is_bench_open
	mouse_filter = Control.MOUSE_FILTER_PASS if is_bench_open else Control.MOUSE_FILTER_IGNORE
	if not is_bench_open and grimoire_ui != null and grimoire_ui.is_docked_with_bench:
		grimoire_ui.set_docked_mode(false)
		grimoire_ui.set_grimoire_open(false)
	if is_bench_open:
		_status_feedback_label.text = "Estude o Grimório à esquerda e sintetize o Óleo escolhido."
		refresh_bench()
	bench_visibility_changed.emit(is_bench_open)


func refresh_bench() -> void:
	if inventory_component == null or _reagents_label == null or _recipes_vbox == null:
		return
	inventory_component.ensure_default_catalog()

	var r_parts: PackedStringArray = PackedStringArray()
	for r_data: ReagentData in inventory_component.manager.get_registered_reagents():
		var cnt: int = inventory_component.get_reagent_count(r_data.reagent_id)
		r_parts.append("%s: %d" % [r_data.display_name, cnt])
	_reagents_label.text = "🎒 REAGENTES: " + " | ".join(r_parts)

	for child: Node in _recipes_vbox.get_children():
		child.queue_free()
	for recipe: OilRecipeData in inventory_component.manager.get_registered_recipes():
		_add_recipe_card(recipe)

	_refresh_loadout_summary()


func _add_recipe_card(recipe: OilRecipeData) -> void:
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_box(Color(0.11, 0.14, 0.19, 1.0), Color(0.28, 0.35, 0.46, 1.0), 4))
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	var req_parts: PackedStringArray = PackedStringArray()
	var req_map: Dictionary = recipe.get_requirements_map()
	for r_id_var: Variant in req_map.keys():
		var r_id: StringName = r_id_var as StringName
		var need: int = int(req_map[r_id])
		var have: int = inventory_component.get_reagent_count(r_id)
		req_parts.append("%dx %s (%d)" % [need, inventory_component.manager.get_reagent_display_name(r_id), have])

	var cur_charges: int = inventory_component.get_oil_charges(recipe.result_oil)
	var header: HBoxContainer = HBoxContainer.new()
	var title_lbl: Label = Label.new()
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 8)
	title_lbl.text = "🧪 %s [Estoque: %d/%d]" % [recipe.display_name, cur_charges, inventory_component.max_oil_charges]
	title_lbl.modulate = Color(0.95, 0.85, 0.45, 1.0)

	var craft_btn: Button = Button.new()
	craft_btn.add_theme_font_size_override("font_size", 8)
	var can_craft: bool = inventory_component.manager.can_craft_recipe(recipe)
	craft_btn.text = "Sintetizar (+%d)" % recipe.charges_per_craft if can_craft else "Falta Reagente"
	var target_rec: OilRecipeData = recipe
	craft_btn.pressed.connect(func() -> void: _on_craft_pressed(target_rec))

	header.add_child(title_lbl)
	header.add_child(craft_btn)
	vbox.add_child(header)

	var ing_lbl: Label = Label.new()
	ing_lbl.custom_minimum_size = Vector2(280.0, 0.0)
	ing_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ing_lbl.add_theme_font_size_override("font_size", 8)
	ing_lbl.text = "Fórmula: " + " + ".join(req_parts)
	ing_lbl.modulate = Color(0.8, 0.86, 0.94, 1.0)
	vbox.add_child(ing_lbl)
	_recipes_vbox.add_child(card)


func _refresh_loadout_summary() -> void:
	if _loadout_label == null or combat_style_component == null or inventory_component == null:
		return
	var style: CombatStyleData = combat_style_component.get_active_style()
	var oil: CombatTypes.ElementOil = combat_style_component.active_oil
	var charges: int = inventory_component.get_oil_charges(oil)
	var charges_txt: String = " (%d cargas)" % charges if oil != CombatTypes.ElementOil.NONE else ""
	_loadout_label.text = "⚔️ BUILD ATIVA: %s | Lâmina: %s%s" % [
		CombatTypes.get_style_display_name(style.style_type),
		CombatTypes.get_oil_display_name(oil),
		charges_txt,
	]


func _build_bench_layout() -> void:
	_bench_panel = PanelContainer.new()
	_bench_panel.position = Vector2(322.0, 10.0)
	_bench_panel.size = Vector2(310.0, 340.0)
	_bench_panel.add_theme_stylebox_override("panel", _make_box(Color(0.08, 0.1, 0.14, 0.99), Color(0.85, 0.48, 0.16, 1.0), 6))
	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 4)
	_bench_panel.add_child(root_vbox)

	var top_bar: HBoxContainer = HBoxContainer.new()
	var title: Label = Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 8)
	title.text = "🔥 FOGUEIRA — BANCADA DE ALQUIMIA & BUILD"
	title.modulate = Color(1.0, 0.72, 0.3, 1.0)
	var close_btn: Button = Button.new()
	close_btn.add_theme_font_size_override("font_size", 8)
	close_btn.text = "Sair da Fogueira"
	close_btn.pressed.connect(func() -> void: set_bench_open(false))
	top_bar.add_child(title)
	top_bar.add_child(close_btn)
	root_vbox.add_child(top_bar)

	_reagents_label = Label.new()
	_reagents_label.custom_minimum_size = Vector2(290.0, 0.0)
	_reagents_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reagents_label.add_theme_font_size_override("font_size", 8)
	root_vbox.add_child(_reagents_label)

	_recipes_vbox = VBoxContainer.new()
	_recipes_vbox.add_theme_constant_override("separation", 4)
	root_vbox.add_child(_recipes_vbox)

	_loadout_label = Label.new()
	_loadout_label.custom_minimum_size = Vector2(290.0, 0.0)
	_loadout_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loadout_label.add_theme_font_size_override("font_size", 8)
	_loadout_label.modulate = Color(0.4, 0.95, 1.0, 1.0)
	root_vbox.add_child(_loadout_label)

	var equip_row: HBoxContainer = HBoxContainer.new()
	equip_row.add_theme_constant_override("separation", 4)
	_add_action_btn(equip_row, "Postura [1/2]", func() -> void:
		if combat_style_component != null:
			combat_style_component.cycle_style()
	)
	_add_action_btn(equip_row, "Aplicar Vitríolo", func() -> void: _try_equip_oil(CombatTypes.ElementOil.VITRIOL_ACID))
	_add_action_btn(equip_row, "Aplicar Ignis", func() -> void: _try_equip_oil(CombatTypes.ElementOil.IGNIS_OIL))
	_add_action_btn(equip_row, "Limpar", func() -> void: _try_equip_oil(CombatTypes.ElementOil.NONE))
	root_vbox.add_child(equip_row)

	var rest_btn: Button = Button.new()
	rest_btn.add_theme_font_size_override("font_size", 8)
	rest_btn.text = "🏕️ Descansar na Fogueira (Restaurar HP & Reagentes do Mapa)"
	rest_btn.pressed.connect(_on_rest_pressed)
	root_vbox.add_child(rest_btn)

	_status_feedback_label = Label.new()
	_status_feedback_label.custom_minimum_size = Vector2(290.0, 0.0)
	_status_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_feedback_label.add_theme_font_size_override("font_size", 8)
	_status_feedback_label.modulate = Color(0.75, 0.92, 0.78, 1.0)
	root_vbox.add_child(_status_feedback_label)
	add_child(_bench_panel)


func _add_action_btn(parent: Container, label_txt: String, callback: Callable) -> void:
	var btn: Button = Button.new()
	btn.add_theme_font_size_override("font_size", 8)
	btn.text = label_txt
	btn.pressed.connect(callback)
	parent.add_child(btn)


func _make_box(bg: Color, border: Color, pad: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_content_margin_all(float(pad))
	return sb


func _on_craft_pressed(recipe: OilRecipeData) -> void:
	if inventory_component == null:
		return
	if inventory_component.try_craft_recipe(recipe):
		if combat_style_component != null:
			combat_style_component.equip_oil(recipe.result_oil)
		_status_feedback_label.text = "✅ %s sintetizado e aplicado na lâmina!" % recipe.display_name
		refresh_bench()


func _try_equip_oil(oil: CombatTypes.ElementOil) -> void:
	if combat_style_component == null:
		return
	if combat_style_component.equip_oil(oil):
		_status_feedback_label.text = "⚔️ Lâmina preparada: %s" % CombatTypes.get_oil_display_name(oil)
	else:
		_status_feedback_label.text = "⚠️ Sem cargas de %s! Sintetize na bancada." % CombatTypes.get_oil_display_name(oil)
	refresh_bench()


func _on_rest_pressed() -> void:
	if health_component != null and heal_on_campfire_rest:
		health_component.reset_health()
	if inventory_component != null:
		inventory_component.trigger_campfire_rest()
	campfire_rest_requested.emit()
	_status_feedback_label.text = "🏕️ Você descansou. HP restaurado e reagentes da região reabastecidos."
	refresh_bench()


func _on_inventory_updated(_id: StringName, _cnt: int) -> void:
	if is_bench_open:
		refresh_bench()


func _on_oil_charges_updated(_oil: CombatTypes.ElementOil, _cnt: int) -> void:
	if is_bench_open:
		refresh_bench()


func _on_crafting_failed(_rec_id: StringName, reason: String) -> void:
	if _status_feedback_label != null:
		_status_feedback_label.text = "❌ " + reason


func _on_style_updated(_style: CombatStyleData) -> void:
	if is_bench_open:
		_refresh_loadout_summary()


func _on_oil_updated(_oil: CombatTypes.ElementOil) -> void:
	if is_bench_open:
		_refresh_loadout_summary()


func _on_grimoire_visibility_changed(grimoire_open: bool) -> void:
	if not grimoire_open and is_bench_open:
		set_bench_open(false)


func _on_player_damaged(_amount: float, _kb: Vector2, _matchup: int) -> void:
	if is_bench_open:
		set_bench_open(false)
