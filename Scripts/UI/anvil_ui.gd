extends CanvasLayer
class_name AnvilUI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$LockedMessage/Timer.timeout.connect(_on_timout_finished)
	set_visiblity(false)

func set_visiblity(is_ui_visible: bool) -> void:
	visible = is_ui_visible

func show_forge_menu() -> void:
	set_visiblity(true)
	if $LockedMessage.visible:
		$LockedMessage.visible = false
	if not $Forging.visible:
		$Forging.visible = true
	else:
		$Forging.visible = false
	print("Forging: " ,$Forging.visible)

func show_locked_message() -> void:
	set_visiblity(true)
	if $Forging.visible:
		$Forging.visible = false
	if not $LockedMessage.visible:
		$LockedMessage/Timer.start()
		$LockedMessage.visible = true
	print("locked: " ,$LockedMessage.visible)

func _on_timout_finished() -> void:
	$LockedMessage.visible = false
