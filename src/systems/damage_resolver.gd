class_name DamageResolver
extends RefCounted
## Resolvedor matemático puro e determinístico para confrontar um AttackData contra um DefenseProfileData (SPEC-002: RF-004, EC-005, SC-002).


static func resolve_attack(
	attack: AttackData,
	defense: DefenseProfileData,
	is_target_staggered: bool = false
) -> Dictionary:
	var safe_attack: AttackData = attack
	if safe_attack == null:
		safe_attack = AttackData.new()
		safe_attack.base_damage = 10.0
		safe_attack.stagger_damage = 10.0
		safe_attack.knockback_force = 120.0
	safe_attack.sanitize()

	var style_dmg_mult: float = 1.0
	var style_stg_mult: float = 1.0
	var oil_dmg_mult: float = 1.0
	var oil_stg_mult: float = 1.0
	var stagger_bonus_mult: float = 1.0

	if defense != null:
		defense.sanitize()
		style_dmg_mult = defense.get_style_damage_multiplier(safe_attack.style_type)
		style_stg_mult = defense.get_style_stagger_multiplier(safe_attack.style_type)
		oil_dmg_mult = defense.get_oil_damage_multiplier(safe_attack.element_oil)
		oil_stg_mult = defense.get_oil_stagger_multiplier(safe_attack.element_oil)
		if is_target_staggered:
			stagger_bonus_mult = defense.staggered_damage_multiplier

	var combined_dmg_mult: float = style_dmg_mult * oil_dmg_mult
	var combined_stg_mult: float = style_stg_mult * oil_stg_mult

	var final_damage: float = safe_attack.base_damage * combined_dmg_mult * stagger_bonus_mult
	var final_stagger_damage: float = safe_attack.stagger_damage * combined_stg_mult
	var knockback_vector: Vector2 = safe_attack.direction.normalized() * safe_attack.knockback_force

	var matchup: CombatTypes.MatchupResult = CombatTypes.MatchupResult.NEUTRAL
	if combined_dmg_mult > 1.15 or combined_stg_mult > 1.25:
		matchup = CombatTypes.MatchupResult.WEAKNESS
	elif combined_dmg_mult < 0.90:
		matchup = CombatTypes.MatchupResult.RESISTED

	return {
		"final_damage": final_damage,
		"final_stagger_damage": final_stagger_damage,
		"damage_multiplier": combined_dmg_mult * stagger_bonus_mult,
		"stagger_multiplier": combined_stg_mult,
		"knockback_vector": knockback_vector,
		"hitstop_duration": safe_attack.hitstop_duration,
		"matchup": matchup,
	}
