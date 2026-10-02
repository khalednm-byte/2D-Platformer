extends Node2D

@onready var player_found := get_node_or_null("Qaswar") as Player
@onready var level_script := $LevelScriptedInput
@onready var entrance_marker := $EntranceMarker2D
var player_input: PlayerInputSource

enum control_stage {
	MOVING_LEFT,
	MOVING_RIGHT,
	STOPPING,
	FINISHED
	}

var stage: control_stage

func _ready() -> void:
	if get_player_input(player_found):
		move_to_entrance_marker()
	else:
		set_physics_process(false)


func get_player_input(player: Player) -> bool:
	if player:
		player_input = player.input_source
		return true
	else:
		push_error("Player node not found in scene.")
	return false

func take_control() -> bool:
	if player_found and player_input:
		player_found.input_source = level_script
		return true
	else:
		push_error("Could not take control; either player or player's input is null.")
	return false

func return_control() -> void:
	player_found.input_source = player_input

func move_to_entrance_marker() -> void:
	if not level_script:
		set_physics_process(false)
		return
	
	if not take_control():
		set_physics_process(false)
		return
	
	if entrance_marker.global_position.x < player_found.global_position.x:
		level_script.move_left()
		stage = control_stage.MOVING_LEFT
	elif entrance_marker.global_position.x > player_found.global_position.x:
		level_script.move_right()
		stage = control_stage.MOVING_RIGHT

func _physics_process(_delta: float) -> void:
	if stage == control_stage.MOVING_LEFT and entrance_marker.global_position.x >= player_found.global_position.x:
		level_script.stop()
		stage = control_stage.STOPPING
	elif stage == control_stage.MOVING_RIGHT and entrance_marker.global_position.x <= player_found.global_position.x:
		level_script.stop()
		stage = control_stage.STOPPING
	
	if absf(player_found.velocity.x) < 1.0 and stage == control_stage.STOPPING:
		return_control()
		stage = control_stage.FINISHED
	
	if stage == control_stage.FINISHED:
		set_physics_process(false)
