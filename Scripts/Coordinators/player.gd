extends CharacterBody2D
class_name Player

enum Stance {
	STANDING, ## STANDING
	ENTERING_CROUCH,
	CROUCHED,
	EXITING_CROUCH,
	ENTERING_SLIDE,
	SLIDING,
	EXITING_SLIDE
}
@export_category("UI Component")
@export var ui_component: PlayerUI
@export_category("Gameplay Components")
@export var input_source: BaseInputSource
@export var movement_component: SimpleMovementComponent
@export var animation_component: CharacterAnimationComponent
@export var combat_component: CombatComponent
@export var hurtbox_component: HurtBoxComponent
@export_category("Tweeks")
@export var jump_buffer_duration: float = 0.12
@export var coyote_time_duration := 0.10
@export var moving_attack_threshold: float = 20.0

@onready var standing_collision: CollisionShape2D = $StandingCollision
@onready var low_collision: CollisionPolygon2D = $LowCollision
@onready var crouch_collision: CollisionShape2D = $CrouchCollision
@onready var head_clearance_check: ShapeCast2D = $HeadClearanceCheck

var current_stance: Stance = Stance.STANDING
var is_turning: bool = false
var facing_direction: float = 1.0

var turn_animation_min_speed: float: ## the minimum speed where the player must be at to play the turn animation.
	get:
		return movement_component.crouch_speed + 10.0 
var jump_buffer_time_remaining: float = 0.0
var coyote_time_remaining := 0.0
# a copy of slide collision x,y points to select according to player's movement direction
var low_polygon_right: PackedVector2Array
var low_polygon_left: PackedVector2Array

var nearby_interactables: Array[InteractableComponent]
var current_interactable: InteractableComponent

func _ready() -> void:
	movement_component.initialize(self)
	combat_component.initialize(self)
	hurtbox_component.initialize_collision_profiles(standing_collision, crouch_collision, low_collision)
	if ui_component == null:
		push_warning("Player has no UI assigned!")
	low_polygon_right = low_collision.polygon.duplicate()
	low_polygon_left = _mirror_polygon_horizontally(low_polygon_right)
	
	animation_component.crouch_enter_finished.connect(_on_crouch_enter_finished)
	animation_component.turn_finished.connect(_on_turn_finished)
	animation_component.crouch_exit_finished.connect(_on_crouch_exit_finished)
	animation_component.slide_enter_finished.connect(_on_slide_enter_finished)
	animation_component.slide_exit_finished.connect(_on_slide_exit_finished)

func register_interactable(interactable: InteractableComponent) -> void:
	if not is_instance_valid(interactable):
		return
	
	if interactable not in nearby_interactables:
		nearby_interactables.append(interactable)
	
	_update_current_interactable()

func unregister_interactable(interactable: InteractableComponent) -> void:
	nearby_interactables.erase(interactable)
	_update_current_interactable()

func _find_best_interactable() -> InteractableComponent:
	var best: InteractableComponent = null
	
	for candidate in nearby_interactables:
		if not is_instance_valid(candidate):
			continue
			
		if not candidate.enabled:
			continue
			
		if best == null:
			best = candidate
			continue
			
		if candidate.interaction_priority > best.interaction_priority:
			best = candidate
			continue
			
		if candidate.interaction_priority == best.interaction_priority:
			var candidate_distance := global_position.distance_squared_to(candidate.global_position)
			var best_distance := global_position.distance_squared_to(best.global_position)
			
			if candidate_distance < best_distance:
				best = candidate
	
	return best

func _update_current_interactable() -> void:
	var previous := current_interactable
	_remove_invalid_interactables()
	current_interactable = _find_best_interactable()
	
	if current_interactable == previous:
		return
	
	if current_interactable == null:
		if ui_component != null:
			ui_component.hide_interaction_prompt()
		return
	
	if ui_component != null:
		ui_component.show_interaction_prompt(current_interactable.action_text, current_interactable.display_name)

func _remove_invalid_interactables() -> void:
	for index in range(nearby_interactables.size() - 1, -1, -1):
		if not is_instance_valid(nearby_interactables[index]):
			nearby_interactables.remove_at(index)

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
	if current_stance != Stance.STANDING:
		return false
	
	if not is_on_floor():
		return false
	
	if combat_component.is_busy_attacking():
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
	if current_stance in [
		Stance.ENTERING_CROUCH,
		Stance.EXITING_CROUCH,
		Stance.ENTERING_SLIDE,
		Stance.SLIDING,
		Stance.EXITING_SLIDE
	]:
		return false
	
	return combat_component.request_attack(facing_direction, is_moving(), current_stance == Stance.CROUCHED)

## Main Function
func request_slide() -> bool:
	if current_stance != Stance.STANDING:
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
	if current_stance != Stance.STANDING:
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
	_update_current_interactable()
	
	if not is_instance_valid(current_interactable):
		return false
	
	return current_interactable.interact(self)

## Main Function
func request_slide_exit() -> bool:
	if current_stance != Stance.SLIDING:
		return false
	
	if not animation_component.try_play_slide_exit():
		return false
	#print("Request Slide Exit is true")
	current_stance = Stance.EXITING_SLIDE
	return true

## Main Function
func request_stand() -> bool:
	if current_stance != Stance.CROUCHED:
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
	if combat_component.is_busy_attacking():
		return false
	
	return current_stance not in [Stance.ENTERING_SLIDE, Stance.SLIDING, Stance.EXITING_SLIDE]

## Helper Function
func _on_turn_finished(new_direction: float) -> void:
	facing_direction = new_direction
	is_turning = false

## Helper Function
func is_moving() -> bool:
	return absf(velocity.x) >= moving_attack_threshold

## Helper Function
func _can_stand() -> bool:
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
	
	if animation_component.is_locked():
		return false
	
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

func _physics_process(delta: float) -> void:
	#print("Current Stance: ", current_stance)
	
	var intent := input_source.get_intent()
	
	jump_buffer_time_remaining = maxf(jump_buffer_time_remaining - delta, 0.0)
	
	coyote_time_remaining = maxf(coyote_time_remaining - delta, 0.0)
	
	if intent.jump_pressed:
		jump_buffer_time_remaining = jump_buffer_duration
	
	if is_on_floor():
		coyote_time_remaining = coyote_time_duration
	
	var action_started := resolve_action_input(intent)
	if not action_started and not animation_component.is_locked() and _can_change_facing_direction():
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
			movement_component.update_horizontal_movement(adjusted_movement_direction, delta)
	
	movement_component.update_gravity(delta)
	
	
	move_and_slide()
	
	if nearby_interactables.size() > 1:
		_update_current_interactable()
	
	animation_component.update_locomotion(current_stance == Stance.CROUCHED, is_on_floor(), current_stance == Stance.SLIDING, velocity.x)
