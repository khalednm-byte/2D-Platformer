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
# -------------------------------------
var counter: int = 0

func debug_print(message: String):
	counter += 1
	print(message, " ", counter)
# -------------------------------------
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
	
	_set_polygon_direction(slash_collision_polygon, slash_polygon_right, slash_polygon_left, attack_info.attack_direction.x)
	_set_polygon_direction(piercing_collision_polygon, piercing_polygon_right, piercing_polygon_left, attack_info.attack_direction.x)
	_set_polygon_direction(crouch_collision_polygon, crouch_polygon_right, crouch_polygon_left, attack_info.attack_direction.x)
	
	
	if attack_info.data.attack_type == AttackData.AttackType.SLASH:
		slash_collision_polygon.set_deferred("disabled", false)
		slash_collision_polygon.visible = true
	elif attack_info.data.attack_type == AttackData.AttackType.PIERCE:
		#debug_print("enabled")
		piercing_collision_polygon.set_deferred("disabled", false)
		piercing_collision_polygon.visible = true
	elif attack_info.data.attack_type == AttackData.AttackType.CROUCH:
		crouch_collision_polygon.set_deferred("disabled", false)
		crouch_collision_polygon.visible = true

## when calling this function it deactivates all polygons
func deactivate() -> void:
	current_attack_info = null
	hit_hurtboxes.clear()
	_disable_all_polygons()


func _disable_all_polygons() -> void:
	if slash_collision_polygon != null:
		slash_collision_polygon.set_deferred("disabled", true)
		slash_collision_polygon.visible = false
	
	if piercing_collision_polygon != null:
		#debug_print("disabled")
		piercing_collision_polygon.set_deferred("disabled", true)
		piercing_collision_polygon.visible = false
	
	if crouch_collision_polygon != null:
		crouch_collision_polygon.set_deferred("disabled", true)
		crouch_collision_polygon.visible = false

func _set_polygon_direction(collision_polygon: CollisionPolygon2D, right_polygon: PackedVector2Array, left_polygon: PackedVector2Array, direction: float) -> void:
	if collision_polygon == null:
		return
	
	collision_polygon.polygon = (left_polygon if direction < 0.0 else right_polygon)


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
