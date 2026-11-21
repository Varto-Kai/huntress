class_name AttackData
extends Resource
## Payload imutável transportado por uma HitboxComponent até uma HurtboxComponent (SPEC-002: RF-002, RF-004, EC-005).

@export var base_damage: float = 15.0
@export var stagger_damage: float = 20.0
@export var knockback_force: float = 180.0
@export var hitstop_duration: float = 0.04
@export var style_type: CombatTypes.StyleType = CombatTypes.StyleType.FAST_STEEL
@export var element_oil: CombatTypes.ElementOil = CombatTypes.ElementOil.NONE
@export var team: CombatTypes.Team = CombatTypes.Team.PLAYER
@export var direction: Vector2 = Vector2.DOWN
@export var pierces_invulnerability_tags: Array[StringName] = []


func sanitize() -> void:
	base_damage = maxf(base_damage, 0.0)
	stagger_damage = maxf(stagger_damage, 0.0)
	knockback_force = maxf(knockback_force, 0.0)
	hitstop_duration = clampf(hitstop_duration, 0.0, 0.3)
	if pierces_invulnerability_tags == null:
		pierces_invulnerability_tags = []
	if direction.length_squared() <= 0.0001:
		direction = Vector2.DOWN
	else:
		direction = direction.normalized()
