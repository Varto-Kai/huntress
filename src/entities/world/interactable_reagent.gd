class_name InteractableReagent
extends Interactable
## Entidade física de reagente alquímico coletável no mapa em Greybox (SPEC-004: RF-003, RF-008, EC-002 & Issue #25).
## Suporta esgotamento após coleta e reabastecimento via respawn_reagent() ao descansar na Fogueira.

signal reagent_picked_up(reagent_data: ReagentData, amount: int)

@export var reagent_data: ReagentData
@export_range(1, 10, 1) var pickup_amount: int = 1
@export var available_color: Color = Color("#2ECC71")
@export var focused_color: Color = Color("#00FFFF")
@export var depleted_color: Color = Color("#34495E")

var is_collected: bool = false

@onready var visual_polygon: Polygon2D = get_node_or_null("ReagentVisual") as Polygon2D
@onready var prompt_bg: ColorRect = get_node_or_null("PromptBg") as ColorRect
@onready var prompt_label: Label = get_node_or_null("PromptLabel") as Label


func _init() -> void:
	interaction_type = InteractionType.REAGENT
	base_priority = 10
	hold_duration = 0.0


func _ready() -> void:
	super._ready()

	if reagent_data != null:
		reagent_data.sanitize()
		available_color = reagent_data.greybox_color

	_refresh_visuals()


func can_interact(_interactor: Node2D) -> bool:
	return not is_collected and reagent_data != null and reagent_data.is_valid()


func interact(_interactor: Node2D) -> void:
	collect_reagent()


func cancel_interaction(_interactor: Node2D) -> void:
	pass


func get_interaction_prompt() -> String:
	var r_name: String = reagent_data.display_name if reagent_data != null else "Reagente"
	return "[E] Coletar %dx %s" % [maxi(1, pickup_amount), r_name]


func get_effective_priority() -> int:
	if not can_interact(null):
		return -1
	return base_priority


func set_focused(focused: bool) -> void:
	super.set_focused(focused)
	_refresh_visuals()


func collect_reagent() -> Dictionary:
	if not can_interact(null):
		return {"collected": false, "reagent": null, "amount": 0}
	is_collected = true
	var amt: int = maxi(1, pickup_amount)
	_refresh_visuals()
	reagent_picked_up.emit(reagent_data, amt)
	interaction_completed.emit(null, {"reagent": reagent_data, "amount": amt})
	return {"collected": true, "reagent": reagent_data, "amount": amt}


func complete_interaction(interactor: Node2D) -> Variant:
	start_interaction(interactor)
	return collect_reagent()


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
			prompt_label.text = get_interaction_prompt()
