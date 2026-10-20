class_name StaggerComponent
extends Node
## Componente modular que acumula dano de postura (Stagger / Break), aplica decaimento
## gradual fora de combate e gerencia a janela de vulnerabilidade (Staggered) (SPEC-002: RF-004, RF-009).

signal stagger_changed(current_stagger: float, max_stagger: float)
signal stagger_started(duration: float)
signal stagger_ended()

@export var defense_profile: DefenseProfileData

var current_stagger: float = 0.0
var _stagger_timer: float = 0.0
var _decay_delay_timer: float = 0.0
var _is_staggered: bool = false


func _ready() -> void:
	reset_stagger()


func _physics_process(delta: float) -> void:
	if _is_staggered:
		_stagger_timer = maxf(0.0, _stagger_timer - delta)
		if _stagger_timer <= 0.0:
			_is_staggered = false
			current_stagger = 0.0
			stagger_changed.emit(current_stagger, get_max_stagger())
			stagger_ended.emit()
		return

	if _decay_delay_timer > 0.0:
		_decay_delay_timer = maxf(0.0, _decay_delay_timer - delta)
		return

	if current_stagger > 0.0:
		var decay_rate: float = 8.0
		if defense_profile != null:
			decay_rate = defense_profile.stagger_decay_rate
		current_stagger = maxf(0.0, current_stagger - decay_rate * delta)
		stagger_changed.emit(current_stagger, get_max_stagger())


func get_max_stagger() -> float:
	if defense_profile != null:
		return maxf(defense_profile.max_stagger, 10.0)
	return 100.0


func is_staggered() -> bool:
	return _is_staggered


func get_stagger_time_remaining() -> float:
	return _stagger_timer


func reset_stagger() -> void:
	current_stagger = 0.0
	_stagger_timer = 0.0
	_decay_delay_timer = 0.0
	_is_staggered = false
	stagger_changed.emit(current_stagger, get_max_stagger())


## Adiciona dano de postura; se atingir max_stagger, dispara o estado Break / Staggered (RF-004).
func apply_stagger_damage(amount: float) -> bool:
	if _is_staggered or amount <= 0.0:
		return false

	var max_stg: float = get_max_stagger()
	current_stagger = clampf(current_stagger + amount, 0.0, max_stg)
	_decay_delay_timer = 1.2
	stagger_changed.emit(current_stagger, max_stg)

	if current_stagger >= max_stg:
		_is_staggered = true
		var duration: float = 3.0
		if defense_profile != null:
			duration = defense_profile.stagger_duration
		_stagger_timer = duration
		stagger_started.emit(duration)
		return true

	return false
