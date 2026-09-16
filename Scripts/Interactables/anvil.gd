extends Interaction
class_name AnvilInteractable

@export var progress_requirement: ProgressRequirementComponent
@export var ui_component: AnvilUI
@export var interaction_component: InteractableComponent
@export var dialogue_resource: DialogueResource

var interactor_reference: Node2D = null

func _ready() -> void:
	interaction_component.interaction_requested.connect(_on_interaction_requested)
	ui_component.ui_closed.connect(_on_ui_closed)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func can_interact() -> bool:
	return (progress_requirement == null or progress_requirement.is_satisfied())


func _on_interaction_requested(player: Player) -> void:
	interactor_reference = player
	if not can_interact():
		show_locked_message()
		return
	
	
	if not ui_component.ui_is_visible:
		open_forging_menu()
	else:
		close_forging_menu()


func show_locked_message() -> void:
	if is_interacting: return
	is_interacting = true
	update_interactor_interacting_state(interactor_reference)
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
	#ui_component.show_locked_message()

func open_forging_menu() -> void:
	if is_interacting: return
	is_interacting = true
	update_interactor_interacting_state(interactor_reference)
	ui_component.show_forge_menu()

func close_forging_menu() -> void:
	ui_component.close_forge_menu()

func _on_ui_closed() -> void:
	is_interacting = false
	update_interactor_interacting_state(interactor_reference)

func _on_dialogue_ended(_dialogue: DialogueResource) -> void:
	is_interacting = false
	update_interactor_interacting_state(interactor_reference)

func update_interactor_interacting_state(interactor: Node2D) -> void:
	if interactor is Player:
		interactor.switch_is_interacting(is_interacting)
	if not is_interacting and interactor_reference != null:
		interactor_reference = null
