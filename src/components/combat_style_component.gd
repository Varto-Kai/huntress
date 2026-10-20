class_name CombatStyleComponent
extends Node
## Componente que gerencia os Estilos de Luta disponíveis da Caçadora (Postura Rápida vs. Postura Pesada)
## e o Óleo elemental ativo, construindo o AttackData correspondente para cada passo do combo (SPEC-002: RF-004, RF-006).

signal style_changed(new_style: CombatStyleData)
signal oil_changed(new_oil: CombatTypes.ElementOil)

@export var available_styles: Array[CombatStyleData] = []
@export var active_style_index: int = 0
@export var active_oil: CombatTypes.ElementOil = CombatTypes.ElementOil.NONE


func _ready() -> void:
	ensure_default_styles()


func ensure_default_styles() -> void:
	if available_styles.is_empty():
		var fast_style: CombatStyleData = load("res://src/data/style_fast_steel.tres") as CombatStyleData
		var heavy_style: CombatStyleData = load("res://src/data/style_heavy_impact.tres") as CombatStyleData
		if fast_style != null:
			available_styles.append(fast_style.duplicate(true) as CombatStyleData)
		if heavy_style != null:
			available_styles.append(heavy_style.duplicate(true) as CombatStyleData)
	active_style_index = clampi(active_style_index, 0, maxi(0, available_styles.size() - 1))


func get_active_style() -> CombatStyleData:
	ensure_default_styles()
	if available_styles.is_empty():
		var fallback: CombatStyleData = CombatStyleData.new()
		return fallback
	return available_styles[active_style_index]


func cycle_style() -> CombatStyleData:
	ensure_default_styles()
	if available_styles.size() > 1:
		active_style_index = (active_style_index + 1) % available_styles.size()
	var current: CombatStyleData = get_active_style()
	style_changed.emit(current)
	return current


func cycle_oil() -> CombatTypes.ElementOil:
	var next_val: int = (int(active_oil) + 1) % 3
	active_oil = next_val as CombatTypes.ElementOil
	oil_changed.emit(active_oil)
	return active_oil


func build_attack_data(step_index: int, direction: Vector2, team: CombatTypes.Team = CombatTypes.Team.PLAYER) -> AttackData:
	var style: CombatStyleData = get_active_style()
	var step: AttackStepData = style.get_step(step_index)

	var atk: AttackData = AttackData.new()
	atk.base_damage = style.base_damage * step.damage_multiplier
	atk.stagger_damage = style.base_stagger_damage * step.stagger_multiplier
	atk.knockback_force = style.base_knockback_force * step.knockback_multiplier
	atk.hitstop_duration = style.hitstop_duration
	atk.style_type = style.style_type
	atk.element_oil = active_oil
	atk.team = team
	atk.direction = direction
	atk.sanitize()
	return atk
