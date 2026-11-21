class_name Player
extends CharacterBody2D
## Entidade raiz da Caçadora (Player) montada por composição (SPEC-001, SPEC-002, SPEC-003 & SPEC-004).
## Conecta Locomoção, Esquiva, Combate, Investigação, Grimório e Inventário/Alquimia.

@export var movement_config: PlayerMovementConfig

@onready var greybox_visual: PlayerGreyboxVisual = $PlayerGreyboxVisual as PlayerGreyboxVisual
@onready var weapon_pivot: Node2D = get_node_or_null("WeaponPivot") as Node2D
@onready var hitbox_component: HitboxComponent = get_node_or_null("WeaponPivot/HitboxComponent") as HitboxComponent
@onready var hurtbox_component: HurtboxComponent = get_node_or_null("HurtboxComponent") as HurtboxComponent
@onready var interaction_component: PlayerInteractionComponent = get_node_or_null("PlayerInteractionComponent") as PlayerInteractionComponent
@onready var grimoire_component: GrimoireComponent = get_node_or_null("GrimoireComponent") as GrimoireComponent
@onready var inventory_component: InventoryComponent = get_node_or_null("InventoryComponent") as InventoryComponent
@onready var health_component: HealthComponent = get_node_or_null("HealthComponent") as HealthComponent
@onready var combat_style_component: CombatStyleComponent = get_node_or_null("CombatStyleComponent") as CombatStyleComponent

var preparation_data: PreparationData:
	get:
		return inventory_component.preparation_data if inventory_component != null else null
@onready var input_component: PlayerInputComponent = $PlayerInputComponent as PlayerInputComponent
@onready var movement_component: MovementComponent = $MovementComponent as MovementComponent
@onready var state_machine: StateMachine = $StateMachine as StateMachine
@onready var idle_state: PlayerIdleState = $StateMachine/IdleState as PlayerIdleState
@onready var move_state: PlayerMoveState = $StateMachine/MoveState as PlayerMoveState
@onready var dodge_state: PlayerDodgeState = $StateMachine/DodgeState as PlayerDodgeState
@onready var attack_state: PlayerAttackState = get_node_or_null("StateMachine/AttackState") as PlayerAttackState
@onready var hurt_state: PlayerHurtState = get_node_or_null("StateMachine/HurtState") as PlayerHurtState


func _ready() -> void:
	if movement_config == null:
		movement_config = load("res://src/data/default_player_movement.tres") as PlayerMovementConfig
	if movement_config != null:
		movement_config = movement_config.duplicate() as PlayerMovementConfig
		movement_config.sanitize()

	input_component.config = movement_config
	movement_component.setup(self, movement_config)

	idle_state.movement_component = movement_component
	idle_state.input_component = input_component
	idle_state.dodge_state = dodge_state

	move_state.movement_component = movement_component
	move_state.input_component = input_component
	move_state.dodge_state = dodge_state

	dodge_state.movement_component = movement_component
	dodge_state.input_component = input_component
	dodge_state.config = movement_config

	if attack_state != null:
		attack_state.movement_component = movement_component
		attack_state.input_component = input_component
		attack_state.combat_style_component = combat_style_component
		attack_state.hitbox_component = hitbox_component
		attack_state.weapon_pivot = weapon_pivot
		attack_state.dodge_state = dodge_state

	if hurt_state != null:
		hurt_state.movement_component = movement_component
		hurt_state.input_component = input_component
		hurt_state.config = movement_config

	if hurtbox_component != null:
		hurtbox_component.team = CombatTypes.Team.PLAYER
		hurtbox_component.health_component = health_component
		hurtbox_component.dodge_state = dodge_state

	if interaction_component != null:
		interaction_component.state_machine = state_machine
		interaction_component.input_component = input_component
		if not input_component.interact_pressed.is_connected(_on_interact_pressed):
			input_component.interact_pressed.connect(_on_interact_pressed)
		if grimoire_component != null and not interaction_component.clue_inspection_completed.is_connected(grimoire_component.register_clue_from_world):
			interaction_component.clue_inspection_completed.connect(grimoire_component.register_clue_from_world)
		if inventory_component != null and not interaction_component.reagent_collected_from_world.is_connected(inventory_component.collect_reagent_from_world):
			interaction_component.reagent_collected_from_world.connect(inventory_component.collect_reagent_from_world)

	if health_component != null:
		if not health_component.damaged.is_connected(_on_player_damaged):
			health_component.damaged.connect(_on_player_damaged)
		if not health_component.health_depleted.is_connected(_on_player_health_depleted):
			health_component.health_depleted.connect(_on_player_health_depleted)

	if combat_style_component != null:
		if inventory_component != null:
			combat_style_component.bind_inventory(inventory_component)
		if input_component != null:
			if not input_component.style_switch_requested.is_connected(_on_style_switch_requested):
				input_component.style_switch_requested.connect(_on_style_switch_requested)
			if not input_component.oil_switch_requested.is_connected(_on_oil_switch_requested):
				input_component.oil_switch_requested.connect(_on_oil_switch_requested)

	if hitbox_component != null and not hitbox_component.hit_landed.is_connected(_on_attack_hit_landed):
		hitbox_component.hit_landed.connect(_on_attack_hit_landed)

	state_machine.initial_state = idle_state
	state_machine.initialize()

	if greybox_visual != null:
		greybox_visual.bind_components(state_machine, movement_component, dodge_state, attack_state, health_component)


func _on_interact_pressed() -> void:
	if interaction_component != null:
		interaction_component.try_start_interaction()


func _on_player_damaged(_amount: float, knockback_vector: Vector2, _matchup: int) -> void:
	if interaction_component != null:
		interaction_component.cancel_active_inspection()
	if hurt_state != null:
		hurt_state.setup_knockback(knockback_vector)
		state_machine.transition_to(&"HurtState")


func _on_player_health_depleted() -> void:
	if health_component != null:
		health_component.reset_health()


func _on_style_switch_requested() -> void:
	if combat_style_component != null:
		combat_style_component.cycle_style()


func _on_oil_switch_requested() -> void:
	if combat_style_component != null:
		combat_style_component.cycle_oil()


func _on_attack_hit_landed(_hurtbox: HurtboxComponent, _resolution: Dictionary) -> void:
	if combat_style_component != null:
		combat_style_component.notify_hit_landed()
