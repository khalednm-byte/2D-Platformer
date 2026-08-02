extends CharacterBody2D
class_name Enemy

@export var movement_component: SimpleMovementComponent

func _ready() -> void:
	movement_component.initialize(self)


func _physics_process(delta: float) -> void:
	movement_component.update_gravity(delta)
	move_and_slide()
