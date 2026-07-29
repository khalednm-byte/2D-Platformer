@icon("res://Scripts/Components/Component_Icons/MovementComponent.png")
extends Node
class_name SimpleMovementComponent

@export var body: CharacterBody2D

@export_category("Horizontal Movement")
@export var movement_speed: float = 300.0
@export var crouch_speed: float = 150.0
@export var ground_acceleration: float = 1500.0
@export var ground_deceleration: float = 2000.0
@export var air_acceleration: float = 400.0
@export var slide_speed: float = 500.0
@export var slide_duration: float = 0.5
@export var slide_deceleration: float = 600.0
@export var minimum_slide_entry_speed: float = 180.0

@export_category("Vertical Movement")
@export var jump_velocity: float = -400.0
@export var gravity: float = 1200.0

var current_movement_speed: float
var current_crouch_speed: float
var crouched: bool = false
var crouching: bool = false
var slide_direction: float = 1.0
var slide_time_remaining: float = 0.0

func _ready() -> void:
	current_movement_speed = movement_speed
	current_crouch_speed = crouch_speed


func initialize(body_reference: CharacterBody2D) -> void:
	body = body_reference
	if body == null:
		push_error("No Body is connected to movement component in parent: ", get_parent().name)

func set_crouched(is_crouched: bool) -> void:
	crouched = is_crouched

func set_crouching(is_crouching: bool) -> void:
	crouching = is_crouching

func update_horizontal_movement(direction: float, delta: float) -> void:
	var normalized_direction := clampf(direction, -1.0, 1.0)
	
	var active_speed := current_crouch_speed if crouched else current_movement_speed
	var target_speed := normalized_direction * active_speed
	
	
	
	if body.is_on_floor():
		var rate := ground_acceleration if direction != 0.0 else ground_deceleration
		
		if crouching:
			#print("Am I stuck?")
			body.velocity.x = move_toward(body.velocity.x, 0.0, 3000 * delta)
			return
		
		if is_zero_approx(normalized_direction):
			rate = ground_deceleration
		
		body.velocity.x = move_toward(body.velocity.x, target_speed, rate * delta)
		
	elif not is_zero_approx(normalized_direction):
		body.velocity.x = move_toward(
			body.velocity.x,
			target_speed,
			air_acceleration * delta
		)

func update_gravity(delta: float) -> void:
	if body == null:
		push_error("Cannot apply gravity on a null body. Check Movement component Script in parent: ", get_parent().name)
		return
	if not body.is_on_floor():
		body.velocity.y += gravity * delta

func can_start_slide() -> bool:
	if body == null:
		return false
	
	return (body.is_on_floor() and absf(body.velocity.x) >= minimum_slide_entry_speed)

func start_slide() -> bool:
	if not can_start_slide():
		#print("Start Sliding: ", can_start_slide())
		return false
	
	slide_direction = signf(body.velocity.x)
	slide_time_remaining = slide_duration
	
	return true

func update_slide(delta: float) -> bool:
	slide_time_remaining = maxf(slide_time_remaining - delta, 0.0)
	
	body.velocity.x = move_toward(body.velocity.x, 0.0, slide_deceleration * delta)
	
	return (slide_time_remaining <= 0.0 or absf(body.velocity.x) <= 20.0 or body.is_on_wall())

func perform_jump() -> bool:
	if body == null:
		return false
	
	body.velocity.y = jump_velocity
	return true
