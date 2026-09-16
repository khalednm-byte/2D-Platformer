@abstract
class_name Interaction
extends Node2D


var is_interacting: bool

@abstract
func _on_interaction_requested(player: Player) -> void
@abstract
func can_interact() -> bool
# return (progress_requirement == null or progress_requirement.is_satisfied())
@abstract
func update_interactor_interacting_state(interactor: Node2D) -> void
