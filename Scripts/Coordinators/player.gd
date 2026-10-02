extends CharacterBody2D
class_name Player

const Stance = ActionController.Stance

@export_category("UI Component")
@export var ui_component: PlayerUI ## Assigned in the level scene
@export_category("Gameplay Components")
@export var input_source: BaseInputSource
@export var movement_component: SimpleMovementComponent
@export var animation_component: CharacterAnimationComponent
@export var combat_component: CombatComponent
@export var hurtbox_component: HurtBoxComponent
@export var action_controller: ActionController
@export var interactor_component: InteractorComponent
@export_category("Tweeks")
@export var jump_buffer_duration: float = 0.12
@export var coyote_time_duration := 0.10
@export var post_dialogue_input_delay: float = 0.15
@export var moving_attack_threshold: float = 20.0


@onready var standing_collision: CollisionShape2D = $StandingCollision
@onready var low_collision: CollisionPolygon2D = $LowCollision
@onready var crouch_collision: CollisionShape2D = $CrouchCollision
@onready var head_clearance_check: ShapeCast2D = $HeadClearanceCheck
@onready var dialogue_marker: DialogueMarker2D = $VisualPivot2D/DialogueMarker2D

var current_stance: Stance = Stance.STANDING
var is_turning: bool = false
var facing_direction: float = 1.0

var turn_animation_min_speed: float: ## the minimum speed where the player must be at to play the turn animation.
	get:
		return movement_component.crouch_speed + 10.0 
var jump_buffer_time_remaining: float = 0.0
var coyote_time_remaining := 0.0
var input_lock_time_remaining: float = 0.0

# a copy of slide collision x,y points to select according to player's movement direction
var low_polygon_right: PackedVector2Array
var low_polygon_left: PackedVector2Array

var is_interacting: bool:
	get:
		return action_controller.is_interacting


func _ready() -> void:
	add_to_group("dialogue_player")
	if action_controller == null or interactor_component == null:
		push_error("Player needs an ActionController and InteractorComponent.")
		set_physics_process(false)
		return
	action_controller.actions_interrupted.connect(_on_actions_interrupted)
	action_controller.interaction_changed.connect(_on_interaction_changed)
	
	if movement_component != null:
		movement_component.initialize(self)
	if combat_component != null:
		combat_component.initialize(self)
	if hurtbox_component != null:
		hurtbox_component.initialize_collision_profiles(standing_collision, crouch_collision, low_collision)
	
	if ui_component == null:
		push_warning("Player has no UI assigned!")
	else:
		ui_component.bind_interactor(interactor_component, action_controller)
	
	if low_collision != null:
		low_polygon_right = low_collision.polygon.duplicate()
		low_polygon_left = _mirror_polygon_horizontally(low_polygon_right)
	
	animation_component.crouch_enter_finished.connect(_on_crouch_enter_finished)
	animation_component.turn_finished.connect(_on_turn_finished)
	animation_component.crouch_exit_finished.connect(_on_crouch_exit_finished)
	animation_component.slide_enter_finished.connect(_on_slide_enter_finished)
	animation_component.slide_exit_finished.connect(_on_slide_exit_finished)

func _mirror_polygon_horizontally(source: PackedVector2Array) -> PackedVector2Array:
	var mirrored := PackedVector2Array()
	
	# Read backwards to preserve the polygon's winding order.
	for index in range(source.size() - 1, -1, -1):
		var point := source[index]
		mirrored.append(Vector2(-point.x, point.y))
	
	return mirrored

func _set_low_collision_direction(direction: float) -> void:
	if direction < 0.0:
		low_collision.polygon = low_polygon_left
	else:
		low_collision.polygon = low_polygon_right

## Main Function
func request_crouch() -> bool:
	if not action_controller.can_crouch(current_stance):
		return false
	
	if not is_on_floor():
		return false
	
	var crouching := animation_component.try_play_crouch_enter()
	
	if crouching:
		current_stance = Stance.ENTERING_CROUCH
		_use_crouch_collision()
		movement_component.set_crouched(true)
		movement_component.set_crouching(true)
	
	return crouching

## Main Function
func request_attack() -> bool:
	if not action_controller.can_attack(current_stance):
		return false
	
	return combat_component.request_attack(facing_direction, is_moving(), current_stance == Stance.CROUCHED)

## Main Function
func request_slide() -> bool:
	if not action_controller.can_slide(current_stance):
		return false
	
	if not movement_component.can_start_slide():
		return false
	
	if not animation_component.try_play_slide_enter():
		return false
	
	var slide_direction := signf(velocity.x)
	
	# Make visual facing, gameplay facing, and collider agree.
	facing_direction = slide_direction
	
	animation_component.set_facing_direction(slide_direction)
	_set_low_collision_direction(slide_direction)
	
	current_stance = Stance.ENTERING_SLIDE
	_use_low_collision()
	
	return true

## Main Function
func request_jump() -> bool:
	if not action_controller.can_jump(current_stance):
		return false
	
	if jump_buffer_time_remaining <= 0.0:
		return false
	
	var can_jump := (is_on_floor() or coyote_time_remaining > 0.0)
	
	if not can_jump:
		return false
	
	if not movement_component.perform_jump():
		return false
	
	jump_buffer_time_remaining = 0.0
	coyote_time_remaining = 0.0
	return true

## Main Function
func request_interaction() -> bool:
	if not action_controller.can_interact(current_stance):
		return false
	if is_moving():
		return false
	
	return interactor_component.request_interaction()

## Main Function
func request_slide_exit() -> bool:
	if not action_controller.can_exit_slide(current_stance):
		return false
	
	if not animation_component.try_play_slide_exit():
		return false
	#print("Request Slide Exit is true")
	current_stance = Stance.EXITING_SLIDE
	return true

## Main Function
func request_stand() -> bool:
	if not action_controller.can_stand(current_stance):
		return false
	
	if not _can_stand():
		return false
	
	var standing := animation_component.try_play_crouch_exit()
	
	if standing:
		current_stance = Stance.EXITING_CROUCH
		movement_component.set_crouching(true)
	
	return standing

## Main Function
func update_facing_direction(movement_direction: float) -> void:
	if is_zero_approx(movement_direction):
		return
	
	var requested_direction := signf(movement_direction)
	
	if requested_direction == facing_direction:
		return
	
	if is_turning:
		return
	
	if absf(velocity.x) > turn_animation_min_speed and is_on_floor():
		if animation_component.try_play_turn(facing_direction, requested_direction):
			is_turning = true
	else:
		facing_direction = requested_direction
		animation_component.set_facing_direction(facing_direction)

func _can_change_facing_direction() -> bool:
	return action_controller.can_turn(current_stance)

## Helper Function
func _on_turn_finished(new_direction: float) -> void:
	facing_direction = new_direction
	is_turning = false

## Helper Function
func is_moving() -> bool:
	return absf(velocity.x) >= moving_attack_threshold

## Helper Function
func _can_stand() -> bool:
	if head_clearance_check == null:
		return true
	head_clearance_check.force_shapecast_update()
	return not head_clearance_check.is_colliding()

## Helper Function
func _on_crouch_enter_finished() -> void:
	if current_stance != Stance.ENTERING_CROUCH:
		return
	current_stance = Stance.CROUCHED
	movement_component.set_crouching(false)

## Helper Function
func _on_crouch_exit_finished() -> void:
	if current_stance != Stance.EXITING_CROUCH:
		return
	
	_use_standing_collision()
	current_stance = Stance.STANDING
	movement_component.set_crouched(false)
	movement_component.set_crouching(false)

func _on_slide_enter_finished() -> void:
	if current_stance != Stance.ENTERING_SLIDE:
		return
	
	current_stance = Stance.SLIDING
	
	if not movement_component.start_slide():
		request_slide_exit()

func _on_slide_exit_finished() -> void:
	#print("WE SHOULD GET CALLED EXITING")
	if current_stance != Stance.EXITING_SLIDE:
		return
	if not _can_stand():
		_use_crouch_collision()
		current_stance = Stance.CROUCHED
		movement_component.set_crouched(true)
	else:
		_use_standing_collision()
		current_stance = Stance.STANDING
		movement_component.set_crouched(false)
	
	movement_component.set_crouching(false)

## Helper Function
func _use_standing_collision() -> void:
	low_collision.set_deferred("disabled", true)
	crouch_collision.set_deferred("disabled", true)
	standing_collision.set_deferred("disabled", false) 
	hurtbox_component.use_standing_profile() # Sync

## Helper Function
func _use_low_collision() -> void:
	standing_collision.set_deferred("disabled", true)
	crouch_collision.set_deferred("disabled", true)
	low_collision.set_deferred("disabled", false)
	hurtbox_component.use_low_profile(facing_direction) # Sync

## Helper Function
func _use_crouch_collision() -> void:
	low_collision.set_deferred("disabled", true)
	standing_collision.set_deferred("disabled", true)
	crouch_collision.set_deferred("disabled", false)
	hurtbox_component.use_crouch_profile() # Sync

func resolve_action_input(intent: CharacterIntent) -> bool:
	if intent.attack_pressed and request_attack():
		return true
	
	if intent.interact_pressed and request_interaction():
		return true
	
	if intent.slide_pressed and request_slide():
		return true
	
	if intent.crouch_pressed:
		if current_stance == Stance.STANDING:
			if request_crouch():
				return true
		elif current_stance == Stance.CROUCHED:
			if request_stand():
				return true
	
	if request_jump():
		return true
	
	return false

func switch_is_interacting(interacting: bool) -> void:
	if interacting:
		action_controller.begin_interaction()
	else:
		action_controller.end_interaction()

func _on_interaction_changed(interacting: bool) -> void:
	if interacting:
		return
	
	# Dialogue/UI just released control. Do not consume that same input as gameplay.
	input_lock_time_remaining = post_dialogue_input_delay
	jump_buffer_time_remaining = 0.0

func _on_actions_interrupted() -> void:
	# An interrupted transition will not emit its normal animation-finished signal.
	is_turning = false
	jump_buffer_time_remaining = 0.0
	coyote_time_remaining = 0.0
	velocity.x = 0.0
	movement_component.set_crouching(false)
	if current_stance != Stance.STANDING:
		var remain_crouched := current_stance == Stance.CROUCHED or not _can_stand()
		current_stance = Stance.CROUCHED if remain_crouched else Stance.STANDING
		movement_component.set_crouched(remain_crouched)
		if remain_crouched:
			_use_crouch_collision()
		else:
			_use_standing_collision()

func _physics_process(delta: float) -> void:
	#print("velocity: ", velocity.x)
	
	var intent := input_source.get_intent()
	input_lock_time_remaining = maxf(input_lock_time_remaining - delta, 0.0)
	
	jump_buffer_time_remaining = maxf(jump_buffer_time_remaining - delta, 0.0)
	
	coyote_time_remaining = maxf(coyote_time_remaining - delta, 0.0)
	
	
	if action_controller.can_move() and input_lock_time_remaining <= 0.0 and intent.jump_pressed:
		jump_buffer_time_remaining = jump_buffer_duration
	
	if is_on_floor():
		coyote_time_remaining = coyote_time_duration
	
	var action_started := false
	if input_lock_time_remaining <= 0.0:
		action_started = resolve_action_input(intent)
	
	if not action_started and _can_change_facing_direction():
		update_facing_direction(intent.movement_direction)
	
	var adjusted_movement_direction := combat_component.get_movement_input(intent.movement_direction)
	
	if is_turning:
		adjusted_movement_direction = 0.0
	
	match current_stance:
		Stance.SLIDING:
			if movement_component.update_slide(delta):
				request_slide_exit()
		Stance.ENTERING_SLIDE, Stance.EXITING_SLIDE:
			# Do not let directional input accelerate, decelerate,
			# or reverse the player during slide transitions.
			pass
		_:
			movement_component.update_horizontal_movement(adjusted_movement_direction, delta, not action_controller.can_move())
	
	movement_component.update_gravity(delta)
	
	
	move_and_slide()
	
	if action_controller.can_update_locomotion():
		animation_component.update_locomotion(current_stance == Stance.CROUCHED, is_on_floor(), current_stance == Stance.SLIDING, velocity.x)
