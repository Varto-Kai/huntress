class_name HealthComponent
extends Node
## Componente modular responsável por gerenciar HP máximo/atual, sistema de leases de invulnerabilidade
## com tags (SPEC-002: RF-001, RF-008 e Architectural Deepening) e sinais de vida/morte.

signal damaged(amount: float, knockback_vector: Vector2, matchup: int)
signal healed(amount: float)
signal health_changed(current_health: float, max_health: float)
signal invulnerability_changed(is_invulnerable: bool)
signal invulnerability_granted(duration: float, tag: StringName)
signal invulnerability_expired(tag: StringName)
signal health_depleted()

@export_range(1.0, 5000.0, 5.0) var max_health: float = 100.0
@export_range(0.0, 3.0, 0.05, "suffix:s") var post_hit_invulnerability_duration: float = 0.60

var current_health: float = 100.0
var _invulnerable_leases: Dictionary[StringName, float] = {}
var _is_dead: bool = false


func _ready() -> void:
	set_process(false)
	reset_health()


func _process(delta: float) -> void:
	_update_leases(delta)


func _physics_process(delta: float) -> void:
	_update_leases(delta)


func reset_health() -> void:
	max_health = maxf(max_health, 1.0)
	current_health = max_health
	revoke_invulnerability(&"")
	_is_dead = false
	health_changed.emit(current_health, max_health)


func is_invulnerable(tag: StringName = &"") -> bool:
	if tag != &"":
		return _invulnerable_leases.has(tag) and _invulnerable_leases[tag] > 0.0
	return not _invulnerable_leases.is_empty()


func is_dead() -> bool:
	return _is_dead


func get_invulnerability_remaining(tag: StringName = &"") -> float:
	if tag != &"":
		return float(_invulnerable_leases.get(tag, 0.0))
	var max_remaining: float = 0.0
	for remaining: float in _invulnerable_leases.values():
		if remaining > max_remaining:
			max_remaining = remaining
	return max_remaining


func is_invulnerable_against(pierces_tags: Array[StringName]) -> bool:
	if _invulnerable_leases.is_empty():
		return false
	for tag: StringName in _invulnerable_leases.keys():
		if not tag in pierces_tags:
			return true
	return false


## Concede um lease temporário de invulnerabilidade identificado por tag.
func grant_invulnerability(tag: StringName, duration: float) -> void:
	if duration <= 0.0:
		return

	var was_invulnerable: bool = is_invulnerable()
	if _invulnerable_leases.has(tag):
		_invulnerable_leases[tag] = maxf(_invulnerable_leases[tag], duration)
	else:
		_invulnerable_leases[tag] = duration

	invulnerability_granted.emit(duration, tag)
	if not was_invulnerable:
		invulnerability_changed.emit(true)


func revoke_invulnerability(tag: StringName = &"") -> void:
	var had_leases: bool = not _invulnerable_leases.is_empty()
	if tag == &"":
		var expired_tags: Array[StringName] = _invulnerable_leases.keys()
		_invulnerable_leases.clear()
		for expired_tag: StringName in expired_tags:
			invulnerability_expired.emit(expired_tag)
	elif _invulnerable_leases.has(tag):
		_invulnerable_leases.erase(tag)
		invulnerability_expired.emit(tag)

	if had_leases and _invulnerable_leases.is_empty():
		invulnerability_changed.emit(false)


## Aplica dano caso a entidade não esteja morta nem em i-frames.
func apply_damage(
	amount: float,
	knockback_vector: Vector2 = Vector2.ZERO,
	matchup: int = CombatTypes.MatchupResult.NEUTRAL
) -> bool:
	if _is_dead or is_invulnerable() or amount <= 0.0:
		return false

	current_health = clampf(current_health - amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	damaged.emit(amount, knockback_vector, matchup)

	if current_health <= 0.0:
		_is_dead = true
		health_depleted.emit()
	elif post_hit_invulnerability_duration > 0.0:
		grant_invulnerability(&"post_hit", post_hit_invulnerability_duration)

	return true


func heal(amount: float) -> void:
	if _is_dead or amount <= 0.0:
		return
	var previous: float = current_health
	current_health = clampf(current_health + amount, 0.0, max_health)
	var actual_healed: float = current_health - previous
	if actual_healed > 0.0:
		health_changed.emit(current_health, max_health)
		healed.emit(actual_healed)


func _update_leases(delta: float) -> void:
	if _invulnerable_leases.is_empty():
		return

	var expired_tags: Array[StringName] = []
	for tag: StringName in _invulnerable_leases.keys():
		var remaining: float = _invulnerable_leases[tag] - delta
		if remaining <= 0.0:
			expired_tags.append(tag)
		else:
			_invulnerable_leases[tag] = remaining

	for tag: StringName in expired_tags:
		_invulnerable_leases.erase(tag)
		invulnerability_expired.emit(tag)

	if _invulnerable_leases.is_empty():
		invulnerability_changed.emit(false)
