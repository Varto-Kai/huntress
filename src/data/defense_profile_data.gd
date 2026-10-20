class_name DefenseProfileData
extends Resource
## Perfil de defesa, resistências, fraquezas e limiar de quebra de postura (Stagger) de um alvo (SPEC-002: RF-004, RF-009, EC-005).

@export var profile_name: String = "Couraça Padrão"

@export_group("Style Multipliers (Damage & Stagger)")
@export_range(0.1, 3.0, 0.05) var fast_steel_damage_mult: float = 1.0
@export_range(0.0, 3.0, 0.05) var fast_steel_stagger_mult: float = 1.0
@export_range(0.1, 3.0, 0.05) var heavy_impact_damage_mult: float = 1.0
@export_range(0.0, 3.0, 0.05) var heavy_impact_stagger_mult: float = 1.0

@export_group("Element / Oil Multipliers (Damage & Stagger)")
@export_range(0.1, 3.0, 0.05) var no_oil_damage_mult: float = 1.0
@export_range(0.0, 3.0, 0.05) var no_oil_stagger_mult: float = 1.0
@export_range(0.1, 3.0, 0.05) var ignis_oil_damage_mult: float = 1.0
@export_range(0.0, 3.0, 0.05) var ignis_oil_stagger_mult: float = 1.0
@export_range(0.1, 3.0, 0.05) var vitriol_acid_damage_mult: float = 1.0
@export_range(0.0, 3.0, 0.05) var vitriol_acid_stagger_mult: float = 1.0

@export_group("Stagger / Break Thresholds")
@export_range(10.0, 500.0, 5.0) var max_stagger: float = 100.0
@export_range(0.0, 50.0, 1.0, "suffix:/s") var stagger_decay_rate: float = 8.0
@export_range(0.5, 10.0, 0.1, "suffix:s") var stagger_duration: float = 3.0
@export_range(1.0, 4.0, 0.05) var staggered_damage_multiplier: float = 1.5


func get_style_damage_multiplier(style: CombatTypes.StyleType) -> float:
	match style:
		CombatTypes.StyleType.FAST_STEEL:
			return maxf(fast_steel_damage_mult, 0.05)
		CombatTypes.StyleType.HEAVY_IMPACT:
			return maxf(heavy_impact_damage_mult, 0.05)
	return 1.0


func get_style_stagger_multiplier(style: CombatTypes.StyleType) -> float:
	match style:
		CombatTypes.StyleType.FAST_STEEL:
			return maxf(fast_steel_stagger_mult, 0.0)
		CombatTypes.StyleType.HEAVY_IMPACT:
			return maxf(heavy_impact_stagger_mult, 0.0)
	return 1.0


func get_oil_damage_multiplier(oil: CombatTypes.ElementOil) -> float:
	match oil:
		CombatTypes.ElementOil.NONE:
			return maxf(no_oil_damage_mult, 0.05)
		CombatTypes.ElementOil.IGNIS_OIL:
			return maxf(ignis_oil_damage_mult, 0.05)
		CombatTypes.ElementOil.VITRIOL_ACID:
			return maxf(vitriol_acid_damage_mult, 0.05)
	return 1.0


func get_oil_stagger_multiplier(oil: CombatTypes.ElementOil) -> float:
	match oil:
		CombatTypes.ElementOil.NONE:
			return maxf(no_oil_stagger_mult, 0.0)
		CombatTypes.ElementOil.IGNIS_OIL:
			return maxf(ignis_oil_stagger_mult, 0.0)
		CombatTypes.ElementOil.VITRIOL_ACID:
			return maxf(vitriol_acid_stagger_mult, 0.0)
	return 1.0


func sanitize() -> void:
	max_stagger = maxf(max_stagger, 10.0)
	stagger_decay_rate = maxf(stagger_decay_rate, 0.0)
	stagger_duration = maxf(stagger_duration, 0.5)
	staggered_damage_multiplier = maxf(staggered_damage_multiplier, 1.0)
