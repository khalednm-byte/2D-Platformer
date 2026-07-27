extends BaseInputSource
class_name PlayerInputSource

var _intent: CharacterIntent = CharacterIntent.new()


func get_intent() -> CharacterIntent:
	_intent.movement_direction = Input.get_axis("WalkL", "WalkR")
	_intent.jump_pressed = Input.is_action_just_pressed("Jump")
	_intent.attackCOMBO_pressed = Input.is_action_pressed("Attack")
	_intent.attack_pressed = Input.is_action_just_pressed("Attack")
	_intent.crouch_pressed = Input.is_action_just_pressed("Crouch")
	_intent.slide_pressed = Input.is_action_just_pressed("Slide")
	
	return _intent

#func _process(_delta: float) -> void:
	#print(str("attackCOMBO_pressed : ", _intent.attackCOMBO_pressed))
	#print(str("attack_pressed : ", _intent.attack_pressed))
