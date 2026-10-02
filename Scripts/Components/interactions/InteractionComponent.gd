@icon("uid://b5fhj45ihf2fx")
extends Area2D
class_name InteractableComponent

signal interaction_requested(interactor: Node)
signal flip_parent_sprite(facing_direction: Vector2)


@export var parent: Interaction
@export var display_name: String = "Object"
@export var action_text: String = "Interact"
@export var interaction_priority: int = 0
@export var allow_sprite_flip: bool = false ## Allow flipping the parent sprit to match the interactor facing direction
## Minimum horizontal separation in world pixels. Set on NPCs to keep dialogue clear; 0 disables it.
@export_range(0.0, 200.0, 1.0, "or_greater") var minimum_horizontal_distance: float = 0.0
@export var enabled: bool = true:
	set(value):
		if enabled == value:
			return
		enabled = value
		_refresh_availability()

var _nearby_interactors: Array[InteractorComponent] = []

func _ready() -> void:
	if parent == null:
		push_error("Interaction component has no parent assigned on ", self.name, " at ", get_parent().name, ". Trying to find it's parent now..")
		parent = get_parent() as Interaction
	
	if not has_node("CollisionShape2D"):
		push_error("Interaction Component on: ", get_parent().name, " has no collision bounds as child.")
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	for child in body.get_children():
		if child is InteractorComponent and child.actor == body:
			if child not in _nearby_interactors:
				_nearby_interactors.append(child)
			if enabled:
				child.register_interactable(self)

func _on_body_exited(body: Node2D) -> void:
	for index in range(_nearby_interactors.size() - 1, -1, -1):
		var interactor := _nearby_interactors[index]
		if not is_instance_valid(interactor):
			_nearby_interactors.remove_at(index)
		elif interactor.actor == body:
			interactor.unregister_interactable(self)
			_nearby_interactors.remove_at(index)

func _exit_tree() -> void:
	for interactor in _nearby_interactors:
		if is_instance_valid(interactor):
			interactor.unregister_interactable(self)
	_nearby_interactors.clear()

func sprite_flip_logic_check(interactor: Node) -> void:
	if allow_sprite_flip:
		if interactor is Node2D:
			flip_parent_sprite.emit(interactor.global_position)

func interact(interactor: Node) -> bool:
	if not enabled:
		return false
	
	if interactor is Node2D and minimum_horizontal_distance > 0.0:
		# Use the NPC origin, since the interaction area may be offset from it.
		var origin := global_position
		if is_instance_valid(parent):
			origin = parent.global_position
		if absf(interactor.global_position.x - origin.x) < minimum_horizontal_distance:
			return false
	
	sprite_flip_logic_check(interactor)
	
	interaction_requested.emit(interactor)
	return true

func _refresh_availability() -> void:
	for index in range(_nearby_interactors.size() - 1, -1, -1):
		var interactor := _nearby_interactors[index]
		if not is_instance_valid(interactor):
			_nearby_interactors.remove_at(index)
		elif enabled:
			interactor.register_interactable(self)
		else:
			interactor.unregister_interactable(self)
