class_name InteractableReagent
extends Area2D
## Entidade física de reagente alquímico coletável no mapa em Greybox (SPEC-004: RF-003, RF-008, EC-002).
## Suporta esgotamento após coleta e reabastecimento via respawn_reagent() ao descansar na Fogueira.

signal reagent_picked_up(reagent_data: ReagentData, amount: int)

@export var reagent_data: ReagentData
@export_range(1, 10, 1) var pickup_amount: int = 1
@export var available_color: Color = Color("#2ECC71")
@export var focused_color: Color = Color("#00FFFF")
@export var depleted_color: Color = Color("#34495E")

var is_collected: bool = false
var is_focused: bool = false

@onready var visual_polygon: Polygon2D = get_node_or_null("ReagentVisual") as Polygon2D
@onready var prompt_bg: ColorRect = get_node_or_null("PromptBg") as ColorRect
@onready var prompt_label: Label = get_node_or_null("PromptLabel") as Label


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	monitorable = true

	if reagent_data != null:
		reagent_data.sanitize()
		available_color = reagent_data.greybox_color

	_refresh_visuals()


func set_focused(focused: bool) -> void:
	is_focused = focused
	_refresh_visuals()


func collect_reagent() -> Dictionary:
	if is_collected or reagent_data == null or not reagent_data.is_valid():
		return {"collected": false, "reagent": null, "amount": 0}
	is_collected = true
	var amt: int = maxi(1, pickup_amount)
	_refresh_visuals()
	reagent_picked_up.emit(reagent_data, amt)
	return {"collected": true, "reagent": reagent_data, "amount": amt}


func respawn_reagent() -> void:
	is_collected = false
	_refresh_visuals()


func _refresh_visuals() -> void:
	if visual_polygon != null:
		if is_collected:
			visual_polygon.color = depleted_color
			visual_polygon.scale = Vector2(0.65, 0.65)
		elif is_focused:
			visual_polygon.color = focused_color
			visual_polygon.scale = Vector2(1.22, 1.22)
		else:
			visual_polygon.color = available_color
			visual_polygon.scale = Vector2.ONE

	var show_prompt: bool = is_focused and not is_collected
	if prompt_bg != null:
		prompt_bg.visible = show_prompt
	if prompt_label != null:
		prompt_label.visible = show_prompt
		if show_prompt:
			var r_name: String = reagent_data.display_name if reagent_data != null else "Reagente"
			prompt_label.text = "[E] Coletar %dx %s" % [maxi(1, pickup_amount), r_name]
