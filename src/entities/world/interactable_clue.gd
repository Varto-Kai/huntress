class_name InteractableClue
extends Area2D
## Entidade física de pista posicionada no mapa em Greybox (SPEC-003: RF-002, RF-008).
## Suporta estados visuais para Não Inspecionada, Em Alcance (Focada), Em Inspeção e Já Inspecionada.

signal clue_inspected(clue_data: ClueData)

@export var clue_data: ClueData
@export_range(0.0, 3.0, 0.05, "suffix:s") var inspect_duration: float = 0.5
@export var uninspected_color: Color = Color("#F39C12")
@export var focused_color: Color = Color("#00FFFF")
@export var inspected_color: Color = Color("#7F8C8D")

@onready var visual_polygon: Polygon2D = get_node_or_null("ClueVisual") as Polygon2D
@onready var progress_bg: ColorRect = get_node_or_null("InspectProgressBarBg") as ColorRect
@onready var progress_fill: ColorRect = get_node_or_null("InspectProgressBarBg/InspectProgressBarFill") as ColorRect
@onready var prompt_label: Label = get_node_or_null("PromptLabel") as Label

var is_inspected: bool = false
var is_focused: bool = false
var _inspect_progress_ratio: float = 0.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	monitorable = true

	if clue_data != null:
		clue_data.sanitize()
		uninspected_color = clue_data.greybox_color
		_apply_shape_geometry(clue_data.visual_shape)

	_refresh_visuals()


func set_focused(focused: bool) -> void:
	is_focused = focused
	if not focused:
		_inspect_progress_ratio = 0.0
	_refresh_visuals()


func set_inspection_progress(ratio: float) -> void:
	_inspect_progress_ratio = clampf(ratio, 0.0, 1.0)
	_refresh_visuals()


func complete_inspection() -> ClueData:
	is_inspected = true
	_inspect_progress_ratio = 0.0
	_refresh_visuals()
	if clue_data != null:
		clue_inspected.emit(clue_data)
	return clue_data


func _apply_shape_geometry(shape_kind: GrimoireTypes.ClueVisualShape) -> void:
	if visual_polygon == null:
		return
	match shape_kind:
		GrimoireTypes.ClueVisualShape.FOOTPRINT:
			visual_polygon.polygon = PackedVector2Array([
				Vector2(-10, -8), Vector2(10, -8), Vector2(12, 8), Vector2(-12, 8)
			])
		GrimoireTypes.ClueVisualShape.RESIDUE:
			visual_polygon.polygon = PackedVector2Array([
				Vector2(0, -12), Vector2(11, -4), Vector2(8, 10), Vector2(-8, 10), Vector2(-11, -4)
			])
		GrimoireTypes.ClueVisualShape.CLAW_MARK:
			visual_polygon.polygon = PackedVector2Array([
				Vector2(-12, -10), Vector2(0, -14), Vector2(12, -10), Vector2(6, 12), Vector2(-6, 12)
			])


func _refresh_visuals() -> void:
	if visual_polygon != null:
		if is_focused:
			visual_polygon.color = focused_color
		elif is_inspected:
			visual_polygon.color = inspected_color
		else:
			visual_polygon.color = uninspected_color

	if progress_bg != null and progress_fill != null:
		progress_bg.visible = _inspect_progress_ratio > 0.001
		progress_fill.size.x = 32.0 * _inspect_progress_ratio

	if prompt_label != null:
		var title_str: String = clue_data.title if clue_data != null else "Vestígio"
		if is_focused:
			var action_tag: String = "[E] Reler" if is_inspected else "[E] Inspecionar"
			prompt_label.text = "%s\n%s" % [action_tag, title_str]
			prompt_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			var status_tag: String = "(Analisado)" if is_inspected else "(Vestígio)"
			prompt_label.text = "%s\n%s" % [title_str, status_tag]
			prompt_label.modulate = Color(0.85, 0.85, 0.85, 0.8)
