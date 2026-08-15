extends Node2D


@export var interaction_component: InteractableComponent
@onready var orignal_pivot_scale: float = $VisualPivot.scale.x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_component.flip_parent_sprite.connect(_on_flip_parent_sprite)
	$VisualPivot/AnimatedSprite2D.play("idle")

func _on_flip_parent_sprite(interactor_position: Vector2) -> void:
	if interactor_position.x > global_position.x:
		$VisualPivot.scale.x =  orignal_pivot_scale
	elif interactor_position.x < global_position.x:
		$VisualPivot.scale.x =  -orignal_pivot_scale
