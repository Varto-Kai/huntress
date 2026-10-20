class_name HealthComponent
extends Node
## Componente modular responsável por gerenciar HP máximo/atual, janela de invulnerabilidade
## pós-dano (post_hit_invulnerability_duration) e sinais de vida/morte (SPEC-002: RF-001, RF-008).

signal damaged(amount: float, knockback_vector: Vector2, matchup: int)
signal healed(amount: float)
signal health_changed(current_health: float, max_health: float)
signal invulnerability_changed(is_invulnerable: bool)
signal health_depleted()

@export_range(1.0, 5000.0, 5.0) var max_health: float = 100.0
@export_range(0.0, 3.0, 0.05, "suffix:s") var post_hit_invulnerability_duration: float = 0.60

var current_health: float = 100.0
var _invulnerability_timer: float = 0.0
var _is_invulnerable: bool = false
var _is_dead: bool = false


func _ready() -> void:
	reset_health()


func _physics_process(delta: float) -> void:
	if _invulnerability_timer > 0.0:
		_invulnerability_timer = maxf(0.0, _invulnerability_timer - delta)
		if _invulnerability_timer <= 0.0 and _is_invulnerable:
			_is_invulnerable = false
			invulnerability_changed.emit(false)


func reset_health() -> void:
	max_health = maxf(max_health, 1.0)
	current_health = max_health
	_invulnerability_timer = 0.0
	_is_invulnerable = false
	_is_dead = false
	health_changed.emit(current_health, max_health)


func is_invulnerable() -> bool:
	return _is_invulnerable


func is_dead() -> bool:
	return _is_dead


func get_invulnerability_remaining() -> float:
	return _invulnerability_timer


## Aplica dano caso a entidade não esteja morta nem em i-frames pós-dano.
func apply_damage(
	amount: float,
	knockback_vector: Vector2 = Vector2.ZERO,
	matchup: int = CombatTypes.MatchupResult.NEUTRAL
) -> bool:
	if _is_dead or _is_invulnerable or amount <= 0.0:
		return false

	current_health = clampf(current_health - amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	damaged.emit(amount, knockback_vector, matchup)

	if current_health <= 0.0:
		_is_dead = true
		health_depleted.emit()
	elif post_hit_invulnerability_duration > 0.0:
		_invulnerability_timer = post_hit_invulnerability_duration
		_is_invulnerable = true
		invulnerability_changed.emit(true)

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
