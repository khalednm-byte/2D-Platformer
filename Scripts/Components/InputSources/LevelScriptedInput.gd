@icon("res://addons/at-icons/node2d/balance.svg")
extends BaseInputSource
class_name LevelScriptedInput

var _intent: CharacterIntent = CharacterIntent.new()

func get_intent() -> CharacterIntent:
	return _intent

func move_right() -> void:
	_intent.movement_direction = 1.0

func move_left() -> void:
	_intent.movement_direction = -1.0

func stop() -> void:
	_intent.movement_direction = 0.0
