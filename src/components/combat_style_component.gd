class_name CombatStyleComponent
extends Node
## Componente que gerencia os Estilos de Luta da Caçadora (Postura Rápida vs. Postura Pesada)
## e o Óleo elemental ativo, suportando modo Híbrido Tático (Q1) e Cargas por Golpe (Q2) (SPEC-002 & SPEC-004).

signal style_changed(new_style: CombatStyleData)
signal oil_changed(new_oil: CombatTypes.ElementOil)

@export var available_styles: Array[CombatStyleData] = []
@export var active_style_index: int = 0
@export var active_oil: CombatTypes.ElementOil = CombatTypes.ElementOil.NONE
@export var allow_free_debug_switching: bool = true

var inventory_component: InventoryComponent = null


func _ready() -> void:
	ensure_default_styles()


func bind_inventory(p_inventory: InventoryComponent) -> void:
	inventory_component = p_inventory
	if inventory_component != null and not inventory_component.active_oil_depleted.is_connected(_on_active_oil_depleted):
		inventory_component.active_oil_depleted.connect(_on_active_oil_depleted)


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


func equip_oil(oil: CombatTypes.ElementOil) -> bool:
	if not allow_free_debug_switching and oil != CombatTypes.ElementOil.NONE:
		if inventory_component == null or not inventory_component.has_oil_charges(oil):
			return false
	active_oil = oil
	oil_changed.emit(active_oil)
	return true


func cycle_oil() -> CombatTypes.ElementOil:
	if allow_free_debug_switching or inventory_component == null:
		var next_val: int = (int(active_oil) + 1) % 3
		active_oil = next_val as CombatTypes.ElementOil
		oil_changed.emit(active_oil)
		return active_oil

	var candidates: Array[CombatTypes.ElementOil] = [
		CombatTypes.ElementOil.NONE,
		CombatTypes.ElementOil.IGNIS_OIL,
		CombatTypes.ElementOil.VITRIOL_ACID,
	]
	var cur_idx: int = candidates.find(active_oil)
	for step: int in range(1, candidates.size() + 1):
		var candidate: CombatTypes.ElementOil = candidates[(cur_idx + step) % candidates.size()]
		if candidate == CombatTypes.ElementOil.NONE or inventory_component.has_oil_charges(candidate):
			active_oil = candidate
			oil_changed.emit(active_oil)
			return active_oil
	return active_oil


func notify_hit_landed() -> void:
	if allow_free_debug_switching or inventory_component == null:
		return
	if active_oil != CombatTypes.ElementOil.NONE:
		inventory_component.consume_charge_for_oil(active_oil)


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


func _on_active_oil_depleted(depleted_oil: CombatTypes.ElementOil) -> void:
	if active_oil == depleted_oil:
		active_oil = CombatTypes.ElementOil.NONE
		oil_changed.emit(active_oil)
