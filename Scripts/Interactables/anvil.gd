extends Interaction
class_name AnvilInteractable

@export var progress_requirement: ProgressRequirementComponent
@export var ui_component: AnvilUI
@export var interaction_component: InteractableComponent

const TALK_TO_FATHER: StringName = &"talked_to_father"

var is_interacting: bool

func _ready() -> void:
	interaction_component.interaction_requested.connect(_on_interaction_requested)
	interaction_component.body_exited.connect(_on_interaction_component_body_exited)
	progress_requirement.required_flags.append(TALK_TO_FATHER)
	ui_component.ui_closed.connect(_on_ui_closed)

func can_interact() -> bool:
	return (progress_requirement == null or progress_requirement.is_satisfied())


func _on_interaction_requested(_player: Player) -> void:
	if not can_interact():
		show_locked_message()
		return
	if not ui_component.ui_is_visible:
		open_forging_menu()
	else:
		close_forging_menu()

func _on_interaction_component_body_exited(_body: Node2D) -> void:
	if not interaction_component.currently_interacting:
		close_forging_menu()

func show_locked_message() -> void:
	ui_component.show_locked_message()


func open_forging_menu() -> void:
	ui_component.show_forge_menu()

func close_forging_menu() -> void:
	ui_component.close_forge_menu()

func _on_ui_closed() -> void:
	print("ui has been closed!")
