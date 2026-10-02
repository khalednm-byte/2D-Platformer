@icon("res://addons/at-icons/node/list_checkboxes.svg")
extends Node
class_name InteractorComponent

signal target_changed(target: InteractableComponent)

@export var actor: Node2D

var _nearby_interactables: Array[InteractableComponent] = []
var _current_target: InteractableComponent
var current_target: InteractableComponent:
	get:
		return _current_target

func register_interactable(interactable: InteractableComponent) -> void:
	if not is_instance_valid(interactable) or not interactable.enabled:
		return
	if interactable not in _nearby_interactables:
		_nearby_interactables.append(interactable)
	refresh_target()

func unregister_interactable(interactable: InteractableComponent) -> void:
	_nearby_interactables.erase(interactable)
	refresh_target()

func refresh_target() -> void:
	var best: InteractableComponent = null
	for index in range(_nearby_interactables.size() - 1, -1, -1):
		if not is_instance_valid(_nearby_interactables[index]):
			_nearby_interactables.remove_at(index)
	if is_instance_valid(actor):
		for candidate in _nearby_interactables:
			if not candidate.enabled or not candidate.is_inside_tree() or candidate.is_queued_for_deletion():
				continue
			if best == null or candidate.interaction_priority > best.interaction_priority:
				best = candidate
			elif candidate.interaction_priority == best.interaction_priority:
				if actor.global_position.distance_squared_to(candidate.global_position) < actor.global_position.distance_squared_to(best.global_position):
					best = candidate
	if _current_target != best:
		_current_target = best
		target_changed.emit(best)

## Caller checks action permissions; this component owns target selection only.
func request_interaction() -> bool:
	refresh_target()
	if not is_instance_valid(actor) or not is_instance_valid(_current_target):
		return false
	return _current_target.interact(actor)

func _physics_process(_delta: float) -> void:
	# Targets may move, change priority, or disappear even while the actor stands still.
	if not _nearby_interactables.is_empty() or _current_target != null:
		refresh_target()
