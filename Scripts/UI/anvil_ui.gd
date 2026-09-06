extends CanvasLayer
class_name AnvilUI

signal ui_closed

@onready var forging_label: Label = $Forging
@onready var locked_label: Label = $LockedMessage
@onready var hide_message_timer: Timer = $LockedMessage/Timer
var ui_is_visible: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_message_timer.timeout.connect(_on_timout_finished)
	set_label_visiblity(forging_label, ui_is_visible)
	set_label_visiblity(locked_label, ui_is_visible)

func set_label_visiblity(intended_label: Label, label_visibility: bool) -> void:
	intended_label.visible = label_visibility

func show_forge_menu() -> void:
	if not forging_label.visible:
		ui_is_visible = true
		set_label_visiblity(forging_label, ui_is_visible)

func close_forge_menu() -> void:
	if forging_label.visible:
		ui_is_visible = false
		set_label_visiblity(forging_label, ui_is_visible)
		ui_closed.emit()

func show_locked_message() -> void:
	if not locked_label.visible:
		ui_is_visible = true
		set_label_visiblity(locked_label, ui_is_visible)
		hide_message_timer.start()

func _on_timout_finished() -> void:
	if locked_label.visible:
		ui_is_visible = false
		set_label_visiblity(locked_label, ui_is_visible)
