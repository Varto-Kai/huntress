class_name HurtboxComponent
extends Area2D
## Componente Area2D que detecta HitboxComponent, delega invulnerabilidade ao HealthComponent,
## resolve Fraqueza/Resistência e aplica dano (SPEC-002: RF-002, RF-003, RF-004, SC-003 e Architectural Deepening).

signal hit_received(attack_data: AttackData, resolution: Dictionary)
signal hit_ignored(attack_data: AttackData)

@export var team: CombatTypes.Team = CombatTypes.Team.PLAYER
@export var health_component: HealthComponent
@export var stagger_component: StaggerComponent
@export var defense_profile: DefenseProfileData


## Verifica se a entidade está invulnerável via HealthComponent centralizado.
func is_invulnerable(tag: StringName = &"") -> bool:
	if health_component != null:
		return health_component.is_invulnerable(tag)
	return false


## Recebe um AttackData vindo de uma HitboxComponent e retorna o dicionário de resolução.
func receive_attack(attack_data: AttackData) -> Dictionary:
	if attack_data == null:
		attack_data = AttackData.new()

	if attack_data.team == team:
		return {"applied": false, "reason": "same_team"}

	if health_component != null and health_component.is_dead():
		return {"applied": false, "reason": "dead"}

	var invulnerable: bool = false
	if health_component != null:
		if not attack_data.pierces_invulnerability_tags.is_empty():
			invulnerable = health_component.is_invulnerable_against(attack_data.pierces_invulnerability_tags)
		else:
			invulnerable = health_component.is_invulnerable()

	if invulnerable:
		hit_ignored.emit(attack_data)
		return {"applied": false, "reason": "invulnerable"}

	var target_staggered: bool = false
	if stagger_component != null:
		target_staggered = stagger_component.is_staggered()

	var active_defense: DefenseProfileData = defense_profile
	if active_defense == null and stagger_component != null:
		active_defense = stagger_component.defense_profile

	var resolution: Dictionary = DamageResolver.resolve_attack(attack_data, active_defense, target_staggered)
	var final_damage: float = float(resolution["final_damage"])
	var final_stagger: float = float(resolution["final_stagger_damage"])
	var knockback_vec: Vector2 = resolution["knockback_vector"] as Vector2
	var matchup: int = int(resolution["matchup"])

	var damage_applied: bool = true
	if health_component != null:
		damage_applied = health_component.apply_damage(final_damage, knockback_vec, matchup)

	if not damage_applied:
		hit_ignored.emit(attack_data)
		return {"applied": false, "reason": "health_rejected"}

	var triggered_stagger: bool = false
	if stagger_component != null:
		triggered_stagger = stagger_component.apply_stagger_damage(final_stagger)

	resolution["applied"] = true
	resolution["triggered_stagger"] = triggered_stagger
	hit_received.emit(attack_data, resolution)
	return resolution
