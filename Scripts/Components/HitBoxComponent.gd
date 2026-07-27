extends Area2D
class_name HitBoxComponent

@export var collision_polygon: CollisionPolygon2D

var current_attack_info: AttackInfo
var hit_hurtboxes: Dictionary = {}

var polygon_right: PackedVector2Array
var polygon_left: PackedVector2Array

func _ready() -> void:
	if collision_polygon == null:
		push_error("HitBoxComponent has no CollisionPolygon2D.")
		return
	else:
		if not collision_polygon.disabled:
			deactivate() 
	# The polygon created in the editor is assumed to face right.
	polygon_right = collision_polygon.polygon.duplicate()
	polygon_left = _mirror_polygon_horizontally(polygon_right)
	
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

func activate(attack_info: AttackInfo) -> void:
	if attack_info == null:
		push_error("Cannot activate HitBoxComponent without AttackInfo.")
		return
	
	current_attack_info = attack_info
	hit_hurtboxes.clear()
	
	_set_facing_direction(attack_info.attack_direction.x)
	
	collision_polygon.set_deferred("disabled", false)


func deactivate() -> void:
	current_attack_info = null
	hit_hurtboxes.clear()
	
	if collision_polygon != null:
		collision_polygon.set_deferred("disabled", true)

func _set_facing_direction(direction: float) -> void:
	if direction < 0.0:
		collision_polygon.polygon = polygon_left
	else:
		collision_polygon.polygon = polygon_right

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
