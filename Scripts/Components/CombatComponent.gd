extends Node
class_name CombatComponent

@export var animation_component: CharacterAnimationComponent
@export var hitbox_component: HitBoxComponent
@export_category("Standing Combos")
@export var moving_combo: Array[AttackData]
@export var stationary_combo: Array[AttackData]
@export_category("Crouched Attacks")
@export var crouch_attack: AttackData

var attacker: Node2D
var current_attack: AttackData
var current_facing_direction: float = 1.0

var is_attacking: bool = false
var hitbox_active: bool = false

var internal_combo_index: int = 0
var attack_queued: bool = false
var queued_is_moving: bool = false
var current_attack_is_crouched: bool = false

func _ready() -> void:
	if animation_component == null:
		push_error("No Animation Component is found in Combat Component.")
		return
	
	if hitbox_component == null:
		push_error("No HitBox Component is found in Combat Component.")
		return
	
	if moving_combo.is_empty():
		push_error("CombatComponent moving_combo is empty.")
	
	if stationary_combo.is_empty():
		push_error("CombatComponent stationary_combo is empty.")

	if moving_combo.size() != stationary_combo.size():
		push_error("Moving and stationary combos have different sizes.")
	
	animation_component.attack_finished.connect(_on_attack_finished)
	animation_component.animation_frame_changed.connect(_on_animation_frame_changed)


func initialize(attacker_reference: Node2D) -> void:
	attacker = attacker_reference

func _get_attack(requested_combo_index: int, is_moving: bool, is_crouched: bool) -> AttackData:
	if is_crouched:
		if requested_combo_index != 0:
			return null
	
		return crouch_attack
	
	var combo := moving_combo if is_moving else stationary_combo
	
	if requested_combo_index < 0:
		return null
	
	if requested_combo_index >= combo.size():
		return null
	
	return combo[requested_combo_index]

func get_movement_multiplier() -> float:
	if current_attack == null:
		return 1.0
	
	return current_attack.movement_multiplier

func _start_attack(new_combo_index: int, facing_direction: float, is_moving: bool, is_crouched: bool) -> bool:
	var selected_attack := _get_attack(new_combo_index, is_moving, is_crouched)
	
	if selected_attack == null:
		return false
	
	current_attack = selected_attack
	current_attack_is_crouched = is_crouched
	internal_combo_index = new_combo_index
	current_facing_direction = signf(facing_direction)
	is_attacking = true
	hitbox_active = false
	
	if not animation_component.try_play_attack(selected_attack.animation_name):
		current_attack = null
		current_attack_is_crouched = false
		is_attacking = false
		internal_combo_index = 0
		return false
	
	return true

func request_attack(facing_direction: float, is_moving: bool, is_crouched: bool) -> bool:
	if is_attacking:
		# Current crouched attack has no combo.
		if current_attack_is_crouched:
			return false
		
		if attack_queued:
			return false
		
		var next_combo_index := internal_combo_index + 1
		
		if _get_attack(next_combo_index, is_moving, false) == null:
			return false
		
		attack_queued = true
		queued_is_moving = is_moving
		return true
	
	return _start_attack(0, facing_direction, is_moving, is_crouched)


func is_busy_attacking() -> bool:
	return is_attacking

func _activate_hitbox() -> void:
	var attack_info := AttackInfo.new()
	
	attack_info.data = current_attack
	attack_info.attacker = attacker
	attack_info.attack_location = attacker.global_position
	attack_info.attack_direction = Vector2(current_facing_direction, 0.0)
	
	hitbox_component.activate(attack_info)
	hitbox_active = true

func _is_active_frame(frame: int) -> bool:
	for window in current_attack.active_windows:
		if frame >= window.x and frame <= window.y:
			return true
	
	return false

func _on_animation_frame_changed(animation_name: StringName, frame: int) -> void:
	if not is_attacking or current_attack == null:
		return
	
	if animation_name != current_attack.animation_name:
		return
	
	var should_be_active := _is_active_frame(frame)
	
	if should_be_active and not hitbox_active:
		_activate_hitbox()
	
	elif not should_be_active and hitbox_active:
		_deactivate_hitbox()

func _deactivate_hitbox() -> void:
	hitbox_component.deactivate()
	hitbox_active = false

func _on_attack_finished() -> void:
	if hitbox_active:
		_deactivate_hitbox()
	
	var should_continue_combo := (attack_queued and not current_attack_is_crouched)
	
	var next_combo_index := internal_combo_index + 1
	var next_is_moving := queued_is_moving
	
	attack_queued = false
	queued_is_moving = false
	is_attacking = false
	current_attack = null
	current_attack_is_crouched = false
	
	if should_continue_combo:
		if _start_attack(next_combo_index, current_facing_direction, next_is_moving, false):
			return
	
	internal_combo_index = 0
