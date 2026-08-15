@abstract
class_name Interaction
extends Node2D


@abstract
func _on_interaction_requested(player: Player) -> void
@abstract
func can_interact() -> bool
# return (progress_requirement == null or progress_requirement.is_satisfied())
