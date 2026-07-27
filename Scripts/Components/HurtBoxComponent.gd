extends Area2D
class_name HurtBoxComponent

signal knockback(force: float, direction: Vector2)

@export_category("Components")
@export var health_component: HealthComponent
@export var damage_owner: Node

@export_category("Debug")
@export var debug_mode: bool = false


func _ready() -> void:
	if health_component == null:
		push_error("%s has no HealthComponent assigned." % get_parent().name)
	if damage_owner == null:
		push_error("%s has no Damage_Owner assigned." % get_parent().name)


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
