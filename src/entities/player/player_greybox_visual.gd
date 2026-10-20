class_name PlayerGreyboxVisual
extends Node2D
## Representação visual Greybox da Caçadora utilizando formas geométricas puras (Polygon2D)
## e cores semânticas para estado ativo, janela de i-frames vs recovery e ponteiro de facing_direction (RF-004, RF-009, SC-004).

@export_group("Semantic Greybox Colors")
@export var idle_color: Color = Color("#2ECC71")
@export var move_color: Color = Color("#58D68D")
@export var dodge_iframes_color: Color = Color("#00D2FF")
@export var dodge_recovery_color: Color = Color("#F39C12")
@export var facing_indicator_color: Color = Color("#FFFFFF")

@export_group("Polygon References")
@export var body_polygon: Polygon2D
@export var facing_indicator: Polygon2D

var _current_state_name: StringName = &"IdleState"
var _is_invulnerable: bool = false


func _ready() -> void:
	_ensure_polygons()
	_refresh_body_color()


## Conecta os sinais da StateMachine, MovementComponent e PlayerDodgeState (*Call Down, Signal Up*).
func bind_components(
	state_machine: StateMachine,
	movement_component: MovementComponent,
	dodge_state: PlayerDodgeState
) -> void:
	_ensure_polygons()

	if state_machine != null:
		if not state_machine.state_changed.is_connected(_on_state_changed):
			state_machine.state_changed.connect(_on_state_changed)
		_current_state_name = state_machine.get_current_state_name()

	if movement_component != null:
		if not movement_component.facing_direction_changed.is_connected(_on_facing_direction_changed):
			movement_component.facing_direction_changed.connect(_on_facing_direction_changed)
		_on_facing_direction_changed(movement_component.facing_direction)

	if dodge_state != null:
		if not dodge_state.invulnerability_started.is_connected(_on_invulnerability_started):
			dodge_state.invulnerability_started.connect(_on_invulnerability_started)
		if not dodge_state.invulnerability_ended.is_connected(_on_invulnerability_ended):
			dodge_state.invulnerability_ended.connect(_on_invulnerability_ended)

	_refresh_body_color()


func _ensure_polygons() -> void:
	if body_polygon == null:
		body_polygon = get_node_or_null("BodyPolygon") as Polygon2D
	if facing_indicator == null:
		facing_indicator = get_node_or_null("FacingIndicator") as Polygon2D
	if facing_indicator != null:
		facing_indicator.color = facing_indicator_color


func _on_state_changed(_previous_state_name: StringName, new_state_name: StringName) -> void:
	_current_state_name = new_state_name
	_refresh_body_color()


func _on_invulnerability_started() -> void:
	_is_invulnerable = true
	_refresh_body_color()


func _on_invulnerability_ended() -> void:
	_is_invulnerable = false
	_refresh_body_color()


func _on_facing_direction_changed(new_direction: Vector2) -> void:
	if facing_indicator != null and new_direction.length_squared() > 0.0001:
		facing_indicator.rotation = new_direction.angle()


func _refresh_body_color() -> void:
	if body_polygon == null:
		return

	var state_lower: String = String(_current_state_name).to_lower()
	if state_lower.contains("dodge"):
		if _is_invulnerable:
			body_polygon.color = dodge_iframes_color
		else:
			body_polygon.color = dodge_recovery_color
	elif state_lower.contains("move"):
		body_polygon.color = move_color
	else:
		body_polygon.color = idle_color
