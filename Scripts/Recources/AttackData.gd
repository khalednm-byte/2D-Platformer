extends Resource
class_name AttackData

enum AttackType {
	SLASH,
	PIERCE,
	CROUCH
}

enum MovementMode {
	STOP,
	FORWARD_ONLY,
	FREE
}


@export var animation_name: StringName
@export var damage: float = 10.0
@export var knockback_force: float = 100.0
@export var attack_type: AttackType = AttackType.SLASH

@export_category("Active Frames")
@export var active_windows: Array[Vector2i] = []
@export_category("Movement")
@export var movement_mode: MovementMode = MovementMode.STOP
@export_range(0.0, 1.0, 0.05) var movement_multiplier: float = 1.0 ## Moving attack: 1.0 Stationary attack: 0.0 Heavy attack: 0.25
