class_name CombatStyleData
extends Resource
## Define um Estilo de Luta completo da Caçadora (ex.: Postura Rápida vs. Postura Pesada)
## incluindo atributos base e a sequência de golpes do combo (SPEC-002: RF-004, RF-006, RF-009).

@export var style_name: String = "Postura Rápida"
@export var style_type: CombatTypes.StyleType = CombatTypes.StyleType.FAST_STEEL
@export_range(1.0, 200.0, 1.0) var base_damage: float = 14.0
@export_range(1.0, 200.0, 1.0) var base_stagger_damage: float = 12.0
@export_range(0.0, 800.0, 10.0, "suffix:px/s") var base_knockback_force: float = 150.0
@export_range(0.0, 0.25, 0.01, "suffix:s") var hitstop_duration: float = 0.04
@export var slash_color: Color = Color("#FF3B30")
@export var combo_steps: Array[AttackStepData] = []


func get_step_count() -> int:
	if combo_steps.is_empty():
		return 1
	return combo_steps.size()


func get_step(index: int) -> AttackStepData:
	if combo_steps.is_empty():
		var fallback: AttackStepData = AttackStepData.new()
		fallback.sanitize()
		return fallback
	var clamped_idx: int = clampi(index, 0, combo_steps.size() - 1)
	var step: AttackStepData = combo_steps[clamped_idx]
	if step == null:
		step = AttackStepData.new()
	step.sanitize()
	return step
