extends Node
class_name CharacterAnimationComponent

signal crouch_enter_finished
signal crouch_exit_finished
signal attack_finished
signal turn_finished(new_direction: float)
signal slide_enter_finished
signal slide_exit_finished
signal animation_frame_changed(animation_name: StringName, frame: int)

@export var animation_set: CharacterAnimationSet
@export var animated_sprite: AnimatedSprite2D
@export var visual_pivot: Node2D

## Locks for one_shot animations
enum AnimationLock {
	NONE,
	TURN,
	CROUCH_IN,
	CROUCH_OUT,
	ATTACK,
	SLIDE_IN,
	SLIDE_OUT,
}


var original_visual_scale_x: float
var animation_lock: AnimationLock = AnimationLock.NONE
var pending_turn_direction: float = 1.0
var locked_animation_name: StringName = &""

func _ready() -> void:
	if animated_sprite == null:
		push_error("CharacterAnimationComponent has no AnimatedSprite2D.")
		return
	
	if visual_pivot == null:
		push_error("CharacterAnimationComponent has no visual pivot.")
		return
	
	if animation_set == null:
		push_error("CharacterAnimationComponent has no animation set.")
		return
	
	original_visual_scale_x = absf(visual_pivot.scale.x)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)

## Checks if a lock is found in a one-shot animation before proceeding with the currently requested animation.
func is_locked() -> bool:
	return animation_lock != AnimationLock.NONE

## Helper Function
func _try_play_locked(lock_type: AnimationLock, animation_name: StringName) -> bool:
	if is_locked():
		return false
	
	animation_lock = lock_type
	locked_animation_name = animation_name
	
	if not _play(animation_name):
		reset_animation_lock()
		return false
	
	return true

func try_play_turn(from_direction: float, to_direction: float) -> bool:
	if is_locked():
		return false
	
	pending_turn_direction = to_direction
	set_facing_direction(from_direction)
	
	return _try_play_locked(AnimationLock.TURN, animation_set.turn)

func try_play_crouch_enter() -> bool:
	return _try_play_locked(AnimationLock.CROUCH_IN, animation_set.crouch_enter)


func try_play_crouch_exit() -> bool:
	return _try_play_locked(AnimationLock.CROUCH_OUT, animation_set.crouch_exit)


func try_play_attack(animation_name: StringName) -> bool:
	return _try_play_locked(AnimationLock.ATTACK, animation_name)

func try_play_slide_enter() -> bool:
	return _try_play_locked(AnimationLock.SLIDE_IN, animation_set.slide_enter)

func try_play_slide_exit() -> bool:
	return _try_play_locked(AnimationLock.SLIDE_OUT, animation_set.slide_exit)

func update_locomotion(is_crouched: bool, is_on_floor: bool, is_sliding: bool,horizontal_velocity: float) -> void:
	# Do not overwrite one-shot animations.
	if is_locked():
		return
	
	if not is_on_floor:
		if absf(horizontal_velocity) <= 1.0:
			_play(animation_set.jump)
		else:
			_play(animation_set.moving_jump)
		
		return
	
	if is_sliding:
		_play(animation_set.slide_loop)
		return
	
	if is_crouched:
		if absf(horizontal_velocity) > 1.0:
			_play(animation_set.crouch_walk)
		else:
			_play(animation_set.crouch_idle)
	else:
		if absf(horizontal_velocity) > 1.0:
			_play(animation_set.run)
		else:
			_play(animation_set.idle)

func _play(animation_name: StringName) -> bool:
	if animated_sprite.sprite_frames == null:
		push_error("AnimatedSprite2D has no SpriteFrames resource.")
		return false
	
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		push_error("Missing animation: %s" % animation_name)
		return false
	
	if (
		animated_sprite.animation == animation_name
		and animated_sprite.is_playing()
	):
		return true
	
	if animated_sprite.animation == animation_name:
		animated_sprite.stop()
	
	animated_sprite.play(animation_name)
	return true

func set_facing_direction(direction: float) -> void:
	if direction < 0.0:
		visual_pivot.scale.x = -original_visual_scale_x
	else:
		visual_pivot.scale.x = original_visual_scale_x

## Releases locks from one-shot animations.
func reset_animation_lock() -> void:
	animation_lock = AnimationLock.NONE
	locked_animation_name = &""

func _on_frame_changed() -> void:
	animation_frame_changed.emit(animated_sprite.animation, animated_sprite.frame)

func _on_animation_finished() -> void:
	if animation_lock == AnimationLock.NONE:
		return
	
	if animated_sprite.animation != locked_animation_name:
		return
	
	var finished_lock := animation_lock
	reset_animation_lock()
	
	match finished_lock:
		AnimationLock.CROUCH_IN:
			crouch_enter_finished.emit()
			
		AnimationLock.CROUCH_OUT:
			crouch_exit_finished.emit()
			
		AnimationLock.ATTACK:
			attack_finished.emit()
			
		AnimationLock.TURN:
			set_facing_direction(pending_turn_direction)
			turn_finished.emit(pending_turn_direction)
			
		AnimationLock.SLIDE_IN:
			slide_enter_finished.emit()
			
		AnimationLock.SLIDE_OUT:
			slide_exit_finished.emit()
