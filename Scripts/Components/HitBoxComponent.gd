extends Area2D
class_name HitBoxComponent

@export var slash_collision_polygon: CollisionPolygon2D
@export var piercing_collision_polygon: CollisionPolygon2D
@export var crouch_collision_polygon: CollisionPolygon2D

var current_attack_info: AttackInfo
var hit_hurtboxes: Dictionary = {}

var slash_polygon_right: PackedVector2Array
var slash_polygon_left: PackedVector2Array
var piercing_polygon_right: PackedVector2Array
var piercing_polygon_left: PackedVector2Array
var crouch_polygon_right: PackedVector2Array
var crouch_polygon_left: PackedVector2Array

func _ready() -> void:
	if slash_collision_polygon == null:
		push_error("HitBoxComponent has no CollisionPolygon2D in parent: ", get_parent().name)
		return
	else:
		slash_polygon_right = slash_collision_polygon.polygon.duplicate()
		slash_polygon_left = _mirror_polygon_horizontally(slash_polygon_right)
	if piercing_collision_polygon == null:
		push_warning("HitBoxComponent has no CollisionPolygon2D in parent: ", get_parent().name)
	else:
		piercing_polygon_right = piercing_collision_polygon.polygon.duplicate()
		piercing_polygon_left = _mirror_polygon_horizontally(piercing_polygon_right)
	if crouch_collision_polygon == null: 
		push_warning("HitBoxComponent has no CollisionPolygon2D in parent: ", get_parent().name)
	else:
		crouch_polygon_right = crouch_collision_polygon.polygon.duplicate()
		crouch_polygon_left = _mirror_polygon_horizontally(crouch_polygon_right)
	# The polygon created in the editor is assumed to face right.
	
	area_entered.connect(_on_area_entered)
	# Hitbox begins inactive.
	deactivate()

func _mirror_polygon_horizontally(source: PackedVector2Array) -> PackedVector2Array:
	var mirrored := PackedVector2Array()
	
	# Reverse the order to preserve polygon winding.
	for index in range(source.size() - 1, -1, -1):
		var point := source[index]
		mirrored.append(Vector2(-point.x, point.y))
	
	return mirrored

## when calling this function it activates polygons depending on the attack type in AttackData
func activate(attack_info: AttackInfo) -> void:
	if attack_info == null:
		push_error("Cannot activate HitBoxComponent without AttackInfo.")
		return
	
	if attack_info.data == null:
		push_error("Cannot activate HitBoxComponent without AttackData.")
		return
	
	current_attack_info = attack_info
	hit_hurtboxes.clear()
	
	_set_facing_direction(attack_info.attack_direction.x)
	
	if attack_info.data.attack_type == AttackData.AttackType.SLASH:
		print("slash_enabled")
		slash_collision_polygon.set_deferred("disabled", false)
	elif attack_info.data.attack_type == AttackData.AttackType.PIERCE:
		print("piercing_enabled")
		piercing_collision_polygon.set_deferred("disabled", false)
	elif attack_info.data.attack_type == AttackData.AttackType.CROUCH:
		print("crouch_enabled")
		crouch_collision_polygon.set_deferred("disabled", false)

## when calling this function it deactivates all polygons
func deactivate() -> void:
	current_attack_info = null
	hit_hurtboxes.clear()
	
	if slash_collision_polygon != null:
		print("slash_disabled")
		slash_collision_polygon.set_deferred("disabled", true)
	if piercing_collision_polygon != null:
		print("piercing_disabled")
		piercing_collision_polygon.set_deferred("disabled", true)
	if crouch_collision_polygon != null:
		print("crouch_disabled")
		crouch_collision_polygon.set_deferred("disabled", true)

func _set_facing_direction(direction: float) -> void:
	if direction < 0.0:
		slash_collision_polygon.polygon = slash_polygon_left
		if piercing_collision_polygon != null:
			piercing_collision_polygon.polygon = piercing_polygon_left
		if crouch_collision_polygon != null:
			crouch_collision_polygon.polygon = crouch_polygon_left
	else:
		slash_collision_polygon.polygon = slash_polygon_right
		if piercing_collision_polygon != null:
			piercing_collision_polygon.polygon = piercing_polygon_left
		if crouch_collision_polygon != null:
			crouch_collision_polygon.polygon = crouch_polygon_left


func _on_area_entered(area: Area2D) -> void:
	if current_attack_info == null:
		return
	
	var hurtbox := area as HurtBoxComponent
	
	if hurtbox == null:
		return
	
	if current_attack_info.attacker == hurtbox.damage_owner:
		return
	
	var hurtbox_id := hurtbox.get_instance_id()
	
	# Prevent one attack window from damaging the same hurtbox
	# on multiple physics frames.
	if hit_hurtboxes.has(hurtbox_id):
		return
	
	hit_hurtboxes[hurtbox_id] = true
	hurtbox.receive_attack(current_attack_info)
