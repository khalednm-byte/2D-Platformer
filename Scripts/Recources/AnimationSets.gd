extends Resource
class_name CharacterAnimationSet

@export_category("Standing Locomotion")
@export var idle: StringName = &"Idle"
@export var run: StringName = &"Run"

@export_category("Airborne")
@export var jump: StringName = &"Jump"
@export var moving_jump: StringName = &"JumpFallInbetween"

@export_category("Crouching")
@export var crouch_enter: StringName = &"CrouchIn"
@export var crouch_idle: StringName = &"CrouchIdle"
@export var crouch_walk: StringName = &"CrouchWalk"
@export var crouch_exit: StringName = &"CrouchOut"

@export_category("Sliding")
@export var slide_enter: StringName = &"SlideIn"
@export var slide_loop: StringName = &"Slide"
@export var slide_exit: StringName = &"SlideOut"

@export_category("Other")
@export var turn: StringName = &"TurnAround"
@export var roll: StringName = &"Roll"
