@icon("uid://b5fhj45ihf2fx")
extends Area2D
class_name InteractableComponent

signal interaction_requested(interactor: Node)
signal flip_parent_sprite(facing_direction: Vector2)

@export var display_name: String = "Object"
@export var action_text: String = "Interact"
@export var interaction_priority: int = 0
@export var allow_sprite_flip: bool = false ## Allow flipping the parent sprit to match the interactor facing direction
@export var enabled: bool = true:
	set(value):
		if enabled == value:
			return
		enabled = value
		_refresh_availability()

var nearby_player: Player


func _ready() -> void:
	if not has_node("CollisionShape2D"):
		push_error("Interaction Component on: ", get_parent().name, " has no collision bounds as child.")
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		nearby_player = body
		if enabled:
			nearby_player.register_interactable(self)

func _on_body_exited(body: Node2D) -> void:
	if body != nearby_player:
		return
	
	nearby_player.unregister_interactable(self)
	nearby_player = null

func interact(interactor: Node) -> bool:
	if not enabled:
		return false
	
	if allow_sprite_flip:
		if interactor is Player:
			flip_parent_sprite.emit(interactor.global_position)
	
	interaction_requested.emit(interactor)
	return true

func _refresh_availability() -> void:
	if not is_instance_valid(nearby_player):
		return
	
	if enabled:
		nearby_player.register_interactable(self)
	else:
		nearby_player.unregister_interactable(self)
