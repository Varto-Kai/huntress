class_name InteractableCampfire
extends Area2D
## Estação de Preparação (Fogueira / Bancada de Alquimia) posicionada no mapa em Greybox (SPEC-004: RF-003, RF-006).

signal campfire_activated(campfire: InteractableCampfire)

@export var campfire_title: String = "Fogueira de Caça"
@export var base_color: Color = Color("#7F8C8D")
@export var flame_color: Color = Color("#E67E22")
@export var focused_flame_color: Color = Color("#00FFFF")

var is_focused: bool = false

@onready var base_visual: Polygon2D = get_node_or_null("CampfireBaseVisual") as Polygon2D
@onready var flame_visual: Polygon2D = get_node_or_null("FlameVisual") as Polygon2D
@onready var prompt_bg: ColorRect = get_node_or_null("PromptBg") as ColorRect
@onready var prompt_label: Label = get_node_or_null("PromptLabel") as Label


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	monitorable = true
	_refresh_visuals()


func set_focused(focused: bool) -> void:
	is_focused = focused
	_refresh_visuals()


func activate_campfire() -> void:
	campfire_activated.emit(self)


func _refresh_visuals() -> void:
	if base_visual != null:
		base_visual.color = base_color
	if flame_visual != null:
		flame_visual.color = focused_flame_color if is_focused else flame_color
		flame_visual.scale = Vector2(1.18, 1.18) if is_focused else Vector2.ONE
	if prompt_bg != null:
		prompt_bg.visible = is_focused
	if prompt_label != null:
		prompt_label.visible = is_focused
		if is_focused:
			prompt_label.text = "[E] %s (Grimório & Bancada)" % campfire_title
