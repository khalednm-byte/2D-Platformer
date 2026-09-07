extends Interaction


@export var interaction_component: InteractableComponent
@export var animation_component: CharacterAnimationComponent
@export var dialogue_resource: DialogueResource

@onready var orignal_pivot_scale: float = $VisualPivot.scale.x
@onready var dialogue_marker: DialogueMarker2D = $VisualPivot/DialogueMarker2D

var is_interacting: bool = false
var interactor_reference: Node2D = null

# emotions for dialogue
var is_angry: bool = false
var is_worried: bool = false
var is_happy: bool = false
# state
var has_met_player: bool = false
var talked_before: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("dialogue_blacksmith")
	interaction_component.interaction_requested.connect(_on_interaction_requested)
	interaction_component.flip_parent_sprite.connect(_on_flip_parent_sprite)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_flip_parent_sprite(interactor_position: Vector2) -> void:
	if interactor_position.x > global_position.x:
		$VisualPivot.scale.x =  orignal_pivot_scale
	elif interactor_position.x < global_position.x:
		$VisualPivot.scale.x =  -orignal_pivot_scale

func can_interact() -> bool:
	return true # always available for interaction

func _on_interaction_requested(player: Player) -> void:
	if is_interacting: return
	is_interacting = true
	interactor_reference = player # store a temporary reference of the interactor
	update_interactor_interacting_state(interactor_reference, is_interacting)
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
	request_dialogue_animation()


func request_dialogue_animation() -> void:
	if not animation_component.try_play_special(&"Fixing_Glasses"):
		push_error("No Dialogue animation was found in ", self.name)
		return

func update_interactor_interacting_state(interactor: Node2D, interacting: bool) -> void:
	if interactor is Player:
		interactor.switch_is_interacting(interacting)
	if not interacting:
		interactor_reference = null

func _on_dialogue_ended(_dialogue: DialogueResource) -> void:
	print("dialogue ended")
	is_interacting = false
	# the line hidden presents a coupling problem, maybe find another approach? | update-> (Commented out now after presented solution)
	#interaction_component.nearby_player.switch_is_interacting(is_interacting)
	# -----------------------------------------------------------------------
	
	# New possible solution
	update_interactor_interacting_state(interactor_reference, is_interacting)
	# -----------------------------------------------------------------------
	$VisualPivot/AnimatedSprite2D.play(&"Idle")

func _physics_process(_delta: float) -> void:
	animation_component.update_locomotion(false, true, false, 0.0)
