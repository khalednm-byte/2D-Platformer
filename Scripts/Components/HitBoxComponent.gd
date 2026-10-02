@icon("uid://c2hpfoprhaqmb")
extends Area2D
class_name HitBoxComponent

@export var hitbox_collision: CollisionPolygon2D

var current_attack_info: AttackInfo
var hit_hurtboxes: Dictionary = {}

var hitbox_collision_right: PackedVector2Array
var hitbox_collision_left: PackedVector2Array
# -------------------------------------
var counter: int = 0

func debug_print(message: String):
	counter += 1
	print(message, " ", counter)
# -------------------------------------
func _ready() -> void:
	if hitbox_collision == null:
		push_error("HitBoxComponent has no CollisionPolygon2D in parent: ", get_parent().name)
		return
	else:
		hitbox_collision_right = hitbox_collision.polygon.duplicate()
		hitbox_collision_left = _mirror_polygon_horizontally(hitbox_collision_right)
	
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
func activate(attack_info: AttackInfo) -> bool:
	if attack_info == null:
		push_error("Cannot activate HitBoxComponent without AttackInfo.")
		return false
	
	if attack_info.data == null:
		push_error("Cannot activate HitBoxComponent without AttackData.")
		return false
	
	current_attack_info = attack_info
	hit_hurtboxes.clear()
	
	if attack_info.data.hitbox_profile == null:
		deactivate()
		push_error("in ", attack_info.attacker," Attack has no hitbox profile.")
		return false
	
	hitbox_collision.polygon = attack_info.data.hitbox_profile.points
	hitbox_collision_right = hitbox_collision.polygon.duplicate()
	hitbox_collision_left = _mirror_polygon_horizontally(hitbox_collision_right)
	_set_polygon_direction(hitbox_collision, hitbox_collision_right, hitbox_collision_left, attack_info.attack_direction.x)
	
	
	hitbox_collision.set_deferred("disabled", false)
	hitbox_collision.visible = true
	return true


## when calling this function it deactivates all polygons
func deactivate() -> void:
	current_attack_info = null
	hit_hurtboxes.clear()
	disable_hitbox_polygon()


func disable_hitbox_polygon() -> void:
	if hitbox_collision != null:
		hitbox_collision.set_deferred("disabled", true)
		hitbox_collision.visible = false

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
