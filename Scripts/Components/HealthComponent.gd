@icon("res://Scripts/Components/Component_Icons/health_component_icon.png")
extends Node
class_name HealthComponent

signal health_changed(current_health: float, max_health: float)
signal died
signal shield_changed(current_shield: float, max_shield: float)
signal shield_broken

@export_range(0.0, 1000.0) var max_health: float = 100.0
@export_range(0.0, 1000.0) var max_shield: float = 0.0

var current_health: float
var current_shield: float


func _ready() -> void:
	max_health = maxf(max_health, 0.0)
	max_shield = maxf(max_shield, 0.0)
	
	current_health = max_health
	current_shield = max_shield


func damage(damage_taken: AttackInfo) -> void:
	if damage_taken.data.damage <= 0.0 or current_health <= 0.0:
		return
	
	var remaining_damage := damage_taken.data.damage
	
	if current_shield > 0.0:
		var absorbed_damage := minf(current_shield, remaining_damage)
		
		current_shield -= absorbed_damage
		remaining_damage -= absorbed_damage
		
		if current_shield == 0.0:
			shield_broken.emit()
		else:
			shield_changed.emit(current_shield, max_shield)
	
	
	if remaining_damage > 0.0:
		current_health = maxf(current_health - remaining_damage, 0.0)
		health_changed.emit(current_health, max_health)
		
		if current_health <= 0.0:
			died.emit()
