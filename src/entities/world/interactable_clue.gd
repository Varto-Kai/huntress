class_name InteractableClue
extends Interactable
## Entidade física de pista posicionada no mapa em Greybox (SPEC-003: RF-002, RF-008 & Issue #25).
## Exibe rótulo flutuante de alta legibilidade apenas quando focada, evitando poluição e sobreposição visual.

signal clue_inspected(clue_data: ClueData)

@export var clue_data: ClueData
@export_range(0.0, 3.0, 0.05, "suffix:s") var inspect_duration: float = 0.5
@export var uninspected_color: Color = Color("#F39C12")
@export var focused_color: Color = Color("#00FFFF")
@export var inspected_color: Color = Color("#5D6D7E")

@onready var visual_polygon: Polygon2D = get_node_or_null("ClueVisual") as Polygon2D
@onready var progress_bg: ColorRect = get_node_or_null("InspectProgressBarBg") as ColorRect
@onready var progress_fill: ColorRect = get_node_or_null("InspectProgressBarBg/InspectProgressBarFill") as ColorRect
@onready var prompt_bg: ColorRect = get_node_or_null("PromptBg") as ColorRect
@onready var prompt_label: Label = get_node_or_null("PromptLabel") as Label

var is_inspected: bool = false
var _inspect_progress_ratio: float = 0.0


func _init() -> void:
	interaction_type = InteractionType.CLUE
	base_priority = 100
	hold_duration = inspect_duration


func _ready() -> void:
	super._ready()

	if clue_data != null:
		clue_data.sanitize()
		uninspected_color = clue_data.greybox_color
		_apply_shape_geometry(clue_data.visual_shape)

	_refresh_visuals()


func can_interact(_interactor: Node2D) -> bool:
	return true


func interact(_interactor: Node2D) -> void:
	complete_inspection()


func cancel_interaction(interactor: Node2D) -> void:
	super.cancel_interaction(interactor)
	set_inspection_progress(0.0)


func get_interaction_prompt() -> String:
	var title_str: String = clue_data.title if clue_data != null else "Vestígio"
	var action_tag: String = "[E] Reler:" if is_inspected else "[E] Inspecionar:"
	return "%s %s" % [action_tag, title_str]


func get_effective_priority() -> int:
	if is_inspected:
		return 5
	return base_priority


func get_hold_duration() -> float:
	return maxf(0.0, inspect_duration)


func set_focused(focused: bool) -> void:
	super.set_focused(focused)
	if not focused:
		_inspect_progress_ratio = 0.0
	_refresh_visuals()


func set_inspection_progress(ratio: float) -> void:
	_inspect_progress_ratio = clampf(ratio, 0.0, 1.0)
	interaction_progress_changed.emit(_inspect_progress_ratio)
	_refresh_visuals()


func set_interaction_progress(ratio: float) -> void:
	set_inspection_progress(ratio)


func complete_interaction(interactor: Node2D) -> Variant:
	start_interaction(interactor)
	return complete_inspection()


func complete_inspection() -> ClueData:
	is_inspected = true
	_inspect_progress_ratio = 0.0
	_refresh_visuals()
	if clue_data != null:
		clue_inspected.emit(clue_data)
	interaction_completed.emit(null, clue_data)
	return clue_data


func _apply_shape_geometry(shape_kind: GrimoireTypes.ClueVisualShape) -> void:
	if visual_polygon == null:
		return
	match shape_kind:
		GrimoireTypes.ClueVisualShape.FOOTPRINT:
			visual_polygon.polygon = PackedVector2Array([
				Vector2(-9, -7), Vector2(9, -7), Vector2(11, 7), Vector2(-11, 7)
			])
		GrimoireTypes.ClueVisualShape.RESIDUE:
			visual_polygon.polygon = PackedVector2Array([
				Vector2(0, -11), Vector2(10, -3), Vector2(7, 9), Vector2(-7, 9), Vector2(-10, -3)
			])
		GrimoireTypes.ClueVisualShape.CLAW_MARK:
			visual_polygon.polygon = PackedVector2Array([
				Vector2(-11, -9), Vector2(0, -13), Vector2(11, -9), Vector2(5, 11), Vector2(-5, 11)
			])


func _refresh_visuals() -> void:
	if visual_polygon != null:
		if is_focused:
			visual_polygon.color = focused_color
			visual_polygon.scale = Vector2(1.18, 1.18)
		elif is_inspected:
			visual_polygon.color = inspected_color
			visual_polygon.scale = Vector2(0.9, 0.9)
		else:
			visual_polygon.color = uninspected_color
			visual_polygon.scale = Vector2.ONE

	if progress_bg != null and progress_fill != null:
		progress_bg.visible = _inspect_progress_ratio > 0.001
		progress_fill.size.x = 36.0 * _inspect_progress_ratio

	if prompt_bg != null:
		prompt_bg.visible = is_focused

	if prompt_label != null:
		prompt_label.visible = is_focused
		if is_focused:
			prompt_label.text = get_interaction_prompt()
