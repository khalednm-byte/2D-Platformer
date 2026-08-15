extends Interaction
class_name AnvilInteractable


@export var progress_requirement: ProgressRequirementComponent
@export var ui_component: AnvilUI

const REQUIRED_HAMMER: StringName = &"Recovered_Forging_Hammer"

func _ready() -> void:
	$InteractionComponent.interaction_requested.connect(_on_interaction_requested)
	progress_requirement.required_flags.append(REQUIRED_HAMMER)

func can_interact() -> bool:
	return (progress_requirement == null or progress_requirement.is_satisfied())


func _on_interaction_requested(_player: Player) -> void:
	if not can_interact():
		show_locked_message()
		return
	
	open_forging_menu()

func show_locked_message() -> void:
	ui_component.show_locked_message()


func open_forging_menu() -> void:
	ui_component.show_forge_menu()
