extends Interaction


@export var interaction_component: InteractableComponent
@export var animation_component: CharacterAnimationComponent
@export var dialogue_resource: DialogueResource

@onready var orignal_pivot_scale: float = $VisualPivot.scale.x
@onready var dialogue_marker: DialogueMarker2D = $VisualPivot/DialogueMarker2D

var is_interacting: bool = false

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
	return true

func _on_interaction_requested(player: Player) -> void:
	if is_interacting: return
	is_interacting = true
	player.switch_is_interacting(is_interacting)
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
	animation_component.try_play_special(&"Fixing_Glasses")


func _on_dialogue_ended(_dialogue: DialogueResource) -> void:
	print("dialogue ended")
	is_interacting = false
	interaction_component.nearby_player.switch_is_interacting(is_interacting)
	$VisualPivot/AnimatedSprite2D.play(&"Idle")

func _physics_process(delta: float) -> void:
	animation_component.update_locomotion(false, true, false, 0.0)
