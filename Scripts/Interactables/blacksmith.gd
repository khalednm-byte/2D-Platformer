extends Interaction

enum Stance {
	SITTING, ## character is sitting
	STANDING ## character is standing
}

@export var stance: Stance = Stance.STANDING
@export var interaction_component: InteractableComponent
@export var animation_component: CharacterAnimationComponent
@export var dialogue_resource: DialogueResource

@onready var orignal_pivot_scale: float = $VisualPivot.scale.x
@onready var dialogue_marker: DialogueMarker2D = $VisualPivot/DialogueMarker2D

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
	if stance == Stance.SITTING:
		animation_component.animation_set.idle = &"Sitting_Idle"
	add_to_group("dialogue_blacksmith")
	interaction_component.interaction_requested.connect(_on_interaction_requested)
	interaction_component.flip_parent_sprite.connect(_on_flip_parent_sprite)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_flip_parent_sprite(interactor_position: Vector2) -> void:
	#if stance == Stance.SITTING: return ## if we ever made the offest.x 0.0 again instead of 1.5 then we bring back this line to action.
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
	update_interactor_interacting_state(interactor_reference)
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
	play_dialogue_animation()


func play_dialogue_animation() -> void:
	if stance == Stance.STANDING:
		if not animation_component.try_play_special(&"Fixing_Glasses"):
			push_error("No Standing Dialogue animation was found in ", self.name)
			return
	else:
		if not animation_component.try_play_special(&"Sitting_Dialogue"):
			push_error("No Sitting Dialogue animation was found in ", self.name)
			return

func update_interactor_interacting_state(interactor: Node2D) -> void:
	if interactor is Player:
		interactor.switch_is_interacting(is_interacting)
	if not is_interacting:
		interactor_reference = null

func _on_dialogue_ended(_dialogue: DialogueResource) -> void:
	is_interacting = false
	# the hidden line presents a coupling problem, maybe find another approach? | update-> (Commented out now after presented solution)
	#interaction_component.nearby_player.switch_is_interacting(is_interacting)
	# -----------------------------------------------------------------------
	
	# New possible solution
	update_interactor_interacting_state(interactor_reference)
	# -----------------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	animation_component.update_locomotion(false, true, false, 0.0)
