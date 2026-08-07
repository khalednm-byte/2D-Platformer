extends Area2D

signal anvil_interact_ui(showing_ui: bool)

@export var progress_requirement: ProgressRequirementComponent

var show_ui: bool = false

const FLAG: StringName = &"FLAG"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		show_ui = true
		anvil_interact_ui.emit(show_ui)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		show_ui = false
		anvil_interact_ui.emit(show_ui)

func can_interact() -> bool:
	return (progress_requirement == null or progress_requirement.is_satisfied())

func interact() -> void:
	if not can_interact():
		#show_locked_message()
		print("Function Fire: show_locked_message()")
		return
	
	#open_forging_menu()
	print("Function Fire: open_forging_menu()")
