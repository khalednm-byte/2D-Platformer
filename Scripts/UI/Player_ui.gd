extends CanvasLayer
class_name PlayerUI

@onready var panel: PanelContainer = %PanelContainer
@onready var interaction_label: Label = %InteractionLabel
@onready var action_label: Label = %ActionLabel

func _ready() -> void:
	hide_interaction_prompt()

func show_interaction_prompt(action_text: String, display_name: String) -> void:
	interaction_label.text = display_name
	action_label.text = action_text
	panel.show()

func hide_interaction_prompt() -> void:
	panel.hide()
