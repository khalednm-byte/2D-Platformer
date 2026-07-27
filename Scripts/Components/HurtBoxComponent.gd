extends Area2D
class_name HurtBoxComponent

signal knockback(force: float, direction: Vector2)

@export_category("Debug")
@export var debug_mode: bool = false
@export_category("Components")
@export var health_component: HealthComponent
@export var damage_owner: Node
@export_category("Collision Profiles")
@export var standing_collision: CollisionShape2D
@export var crouch_collision: CollisionShape2D
@export var low_collision: CollisionPolygon2D

var low_polygon_right: PackedVector2Array
var low_polygon_left: PackedVector2Array


func _ready() -> void:
	if health_component == null:
		push_error("%s has no HealthComponent assigned." % get_parent().name)
	if damage_owner == null:
		push_error("%s has no Damage_Owner assigned." % get_parent().name)
	if standing_collision == null:
		push_error("%s has no Standing Collision assigned." % get_parent().name)
	if crouch_collision == null:
		push_error("%s has no Crouch Collision assigned." % get_parent().name)
	else:
		if not crouch_collision.disabled:
			crouch_collision.set_deferred("disabled", true)
	if low_collision == null:
		push_error("%s has no Low Collision assigned." % get_parent().name)
	else:
		if not low_collision.disabled:
			low_collision.set_deferred("disabled", true)


func _mirror_polygon_horizontally(source: PackedVector2Array) -> PackedVector2Array:
	var mirrored := PackedVector2Array()
	
	for index in range(source.size() - 1, -1, -1):
		var point := source[index]
		mirrored.append(Vector2(-point.x, point.y))
	
	return mirrored

func use_standing_profile() -> void:
	low_collision.set_deferred("disabled", true)
	crouch_collision.set_deferred("disabled", true)
	standing_collision.set_deferred("disabled", false)


func use_crouch_profile() -> void:
	low_collision.set_deferred("disabled", true)
	standing_collision.set_deferred("disabled", true)
	crouch_collision.set_deferred("disabled", false)


func use_low_profile(direction: float) -> void:
	if direction < 0.0:
		low_collision.polygon = low_polygon_left
	else:
		low_collision.polygon = low_polygon_right
	
	standing_collision.set_deferred("disabled", true)
	crouch_collision.set_deferred("disabled", true)
	low_collision.set_deferred("disabled", false)

func initialize_collision_profiles(standing_source: CollisionShape2D, crouch_source: CollisionShape2D, low_source: CollisionPolygon2D) -> void:
	if (standing_collision == null or crouch_collision == null or low_collision == null):
		push_error("HurtBox collision profiles are not assigned.")
		return
	
	# Sharing a Shape2D resource is fine as long as you do not
	# mutate the resource independently during gameplay.
	standing_collision.shape = standing_source.shape
	standing_collision.transform = standing_source.transform
	
	crouch_collision.shape = crouch_source.shape
	crouch_collision.transform = crouch_source.transform
	
	low_collision.transform = low_source.transform
	
	low_polygon_right = low_source.polygon.duplicate()
	low_polygon_left = _mirror_polygon_horizontally(low_polygon_right)
	
	low_collision.polygon = low_polygon_right
	use_standing_profile()

func receive_attack(attack_info: AttackInfo) -> void:
	if attack_info == null:
		push_warning("HurtBox received a null AttackInfo.")
		return
	
	if attack_info.data == null:
		push_warning("AttackInfo contains no AttackData.")
		return
	
	if health_component == null:
		push_error("%s cannot receive damage without a HealthComponent." % get_parent().name)
		return
	
	health_component.damage(attack_info)
	
	var knockback_force := attack_info.data.knockback_force
	
	if knockback_force > 0.0:
		knockback.emit(attack_info.data.knockback_force, attack_info.attack_direction)
	
	if debug_mode:
		print(get_parent().name, " received ", attack_info.data.damage, " damage.")
