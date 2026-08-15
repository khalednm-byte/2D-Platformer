@icon("uid://d3mujbd2xds4g")
extends BaseInputSource
class_name PlayerInputSource

var _intent: CharacterIntent = CharacterIntent.new()


func get_intent() -> CharacterIntent:
	_intent.movement_direction = Input.get_axis("WalkL", "WalkR")
	_intent.jump_pressed = Input.is_action_just_pressed("Jump")
	_intent.attack_pressed = Input.is_action_just_pressed("Attack")
	_intent.crouch_pressed = Input.is_action_just_pressed("Crouch")
	_intent.slide_pressed = Input.is_action_just_pressed("Slide")
	_intent.interact_pressed = Input.is_action_just_pressed("Interact")
	
	return _intent
