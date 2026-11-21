class_name InteractableCampfire
extends Interactable
## Estação de Preparação (Fogueira / Bancada de Alquimia) posicionada no mapa em Greybox (SPEC-004: RF-003, RF-006 & Issue #25).

signal campfire_activated(campfire: InteractableCampfire)

@export var campfire_title: String = "Fogueira de Caça"
@export var base_color: Color = Color("#7F8C8D")
@export var flame_color: Color = Color("#E67E22")
@export var focused_flame_color: Color = Color("#00FFFF")

@onready var base_visual: Polygon2D = get_node_or_null("CampfireBaseVisual") as Polygon2D
@onready var flame_visual: Polygon2D = get_node_or_null("FlameVisual") as Polygon2D
@onready var prompt_bg: ColorRect = get_node_or_null("PromptBg") as ColorRect
@onready var prompt_label: Label = get_node_or_null("PromptLabel") as Label


func _init() -> void:
	interaction_type = InteractionType.CAMPFIRE
	base_priority = 50
	hold_duration = 0.0


func _ready() -> void:
	super._ready()
	_refresh_visuals()


func can_interact(_interactor: Node2D) -> bool:
	return true


func interact(_interactor: Node2D) -> void:
	activate_campfire()


func cancel_interaction(_interactor: Node2D) -> void:
	pass


func get_interaction_prompt() -> String:
	return "[E] %s (Grimório & Bancada)" % campfire_title


func get_effective_priority() -> int:
	return base_priority


func set_focused(focused: bool) -> void:
	super.set_focused(focused)
	_refresh_visuals()


func activate_campfire() -> void:
	campfire_activated.emit(self)
	interaction_completed.emit(null, self)


func complete_interaction(interactor: Node2D) -> Variant:
	start_interaction(interactor)
	activate_campfire()
	return self


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
			prompt_label.text = get_interaction_prompt()
