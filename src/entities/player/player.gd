class_name Player
extends CharacterBody2D
## Entidade raiz da Caçadora (Player) montada por composição (RF-003, RF-008, DT-01, DT-02).
## Atua exclusivamente como container que injeta PlayerMovementConfig e conecta os componentes filhos.

@export var movement_config: PlayerMovementConfig

@onready var greybox_visual: PlayerGreyboxVisual = $PlayerGreyboxVisual as PlayerGreyboxVisual
@onready var input_component: PlayerInputComponent = $PlayerInputComponent as PlayerInputComponent
@onready var movement_component: MovementComponent = $MovementComponent as MovementComponent
@onready var state_machine: StateMachine = $StateMachine as StateMachine
@onready var idle_state: PlayerIdleState = $StateMachine/IdleState as PlayerIdleState
@onready var move_state: PlayerMoveState = $StateMachine/MoveState as PlayerMoveState
@onready var dodge_state: PlayerDodgeState = $StateMachine/DodgeState as PlayerDodgeState


func _ready() -> void:
	if movement_config == null:
		movement_config = load("res://src/data/default_player_movement.tres") as PlayerMovementConfig
	if movement_config != null:
		# Duplica o Resource em runtime conforme Cláusula 3.2 da Constituição (Imutabilidade de Catálogo)
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

	state_machine.initial_state = idle_state
	state_machine.initialize()

	if greybox_visual != null:
		greybox_visual.bind_components(state_machine, movement_component, dodge_state)
