class_name HazardPulseEmitter
extends Node2D
## Emissor periódico de pulsos de ataque inimigo em Greybox para validar i-frames da esquiva,
## i-frames pós-dano e transição para PlayerHurtState (SPEC-002: RF-003, RF-008, SC-003).

@export_range(0.5, 5.0, 0.1, "suffix:s") var idle_interval: float = 1.4
@export_range(0.2, 2.0, 0.05, "suffix:s") var telegraph_duration: float = 0.55
@export_range(0.05, 0.6, 0.02, "suffix:s") var active_pulse_duration: float = 0.16
@export_range(5.0, 100.0, 5.0) var pulse_damage: float = 15.0
@export_range(50.0, 600.0, 10.0) var pulse_knockback: float = 240.0

@onready var hitbox_component: HitboxComponent = $HitboxComponent as HitboxComponent
@onready var telegraph_ring: Polygon2D = $TelegraphRing as Polygon2D
@onready var core_polygon: Polygon2D = $CorePolygon as Polygon2D

enum EmitterPhase {
	COOLDOWN = 0,
	TELEGRAPH = 1,
	ACTIVE = 2,
}

var _phase: EmitterPhase = EmitterPhase.COOLDOWN
var _timer: float = 1.0


func _ready() -> void:
	_timer = idle_interval
	if hitbox_component != null:
		hitbox_component.deactivate()
	_refresh_visuals()


func _physics_process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	if _timer > 0.0:
		return

	match _phase:
		EmitterPhase.COOLDOWN:
			_phase = EmitterPhase.TELEGRAPH
			_timer = telegraph_duration
			_refresh_visuals()
		EmitterPhase.TELEGRAPH:
			_phase = EmitterPhase.ACTIVE
			_timer = active_pulse_duration
			_fire_pulse()
			_refresh_visuals()
		EmitterPhase.ACTIVE:
			if hitbox_component != null:
				hitbox_component.deactivate()
			_phase = EmitterPhase.COOLDOWN
			_timer = idle_interval
			_refresh_visuals()


func _fire_pulse() -> void:
	if hitbox_component == null:
		return
	var atk: AttackData = AttackData.new()
	atk.base_damage = pulse_damage
	atk.stagger_damage = 25.0
	atk.knockback_force = pulse_knockback
	atk.team = CombatTypes.Team.ENEMY
	atk.direction = Vector2.UP
	atk.sanitize()
	hitbox_component.activate(atk)


func _refresh_visuals() -> void:
	if telegraph_ring == null or core_polygon == null:
		return
	match _phase:
		EmitterPhase.COOLDOWN:
			telegraph_ring.visible = false
			core_polygon.color = Color("#7F8C8D")
		EmitterPhase.TELEGRAPH:
			telegraph_ring.visible = true
			telegraph_ring.color = Color(1.0, 0.75, 0.0, 0.35)
			core_polygon.color = Color("#F39C12")
		EmitterPhase.ACTIVE:
			telegraph_ring.visible = true
			telegraph_ring.color = Color(1.0, 0.15, 0.2, 0.75)
			core_polygon.color = Color("#FF2D55")
