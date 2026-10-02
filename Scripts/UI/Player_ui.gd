extends CanvasLayer
class_name PlayerUI

@onready var panel: PanelContainer = %PanelContainer
@onready var interaction_label: Label = %InteractionLabel
@onready var action_label: Label = %ActionLabel

var _interactor: InteractorComponent
var _action_controller: ActionController

func _ready() -> void:
	hide_interaction_prompt()

## Called by the owning player after its children are ready.
func bind_interactor(interactor: InteractorComponent, controller: ActionController) -> void:
	if is_instance_valid(_interactor) and _interactor.target_changed.is_connected(_on_target_changed):
		_interactor.target_changed.disconnect(_on_target_changed)
	if is_instance_valid(_action_controller) and _action_controller.mode_changed.is_connected(_refresh_prompt):
		_action_controller.mode_changed.disconnect(_refresh_prompt)
	_interactor = interactor
	_action_controller = controller
	_interactor.target_changed.connect(_on_target_changed)
	_action_controller.mode_changed.connect(_refresh_prompt)
	_refresh_prompt()

func _on_target_changed(_target: InteractableComponent) -> void:
	_refresh_prompt()

func _refresh_prompt() -> void:
	if not is_instance_valid(_interactor) or not is_instance_valid(_action_controller):
		hide_interaction_prompt()
		return
	var target := _interactor.current_target
	if not is_instance_valid(target) or not _action_controller.can_move() or _action_controller.disable_interactions:
		hide_interaction_prompt()
		return
	show_interaction_prompt(target.action_text, target.display_name)

func show_interaction_prompt(action_text: String, display_name: String) -> void:
	interaction_label.text = display_name
	action_label.text = action_text
	panel.show()

func hide_interaction_prompt() -> void:
	panel.hide()
