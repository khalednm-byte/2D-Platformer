extends Node2D

@export var animation_component: CharacterAnimationComponent

@onready var tween_barks_timer: Timer = $tween_barks
@onready var barks_audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tween_barks_timer.wait_time = randf_range(1.0, 10.0)
	tween_barks_timer.timeout.connect(_on_tween_barks_timer_timeout)


func _on_tween_barks_timer_timeout() -> void:
	barks_audio.play()
	if not animation_component.try_play_special(&"Barking"):
		push_error("Barking not found in dog.gd.")
	tween_barks_timer.wait_time = randf_range(2.0, 10.0)
	tween_barks_timer.start()

func _physics_process(_delta: float) -> void:
	animation_component.update_locomotion(false, true, false, 0.0)
