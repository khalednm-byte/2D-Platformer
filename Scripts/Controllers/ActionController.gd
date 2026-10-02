@icon("res://addons/at-icons/node/footsteps.svg")
extends Node
class_name ActionController

## Owns action permissions and forced interruptions, not physics or combo execution.
signal actions_interrupted
signal interaction_changed(interacting: bool)
signal mode_changed

enum Stance {
	STANDING,
	ENTERING_CROUCH,
	CROUCHED,
	EXITING_CROUCH,
	ENTERING_SLIDE,
	SLIDING,
	EXITING_SLIDE
}

enum Mode { FREE, INTERACTING, STAGGERED, DEAD }

@export var combat_component: CombatComponent
@export var animation_component: CharacterAnimationComponent
@export_category("Permissions")
@export var disable_crouch: bool = false
@export var disable_slide: bool = false
@export var disable_jump: bool = false
@export var disable_attack: bool = false
@export var disable_interactions: bool = false
@export var disable_stand: bool = false

var _mode: Mode = Mode.FREE
var is_interacting: bool:
	get:
		return _mode == Mode.INTERACTING
var is_dead: bool:
	get:
		return _mode == Mode.DEAD

func can_move() -> bool:
	return _mode == Mode.FREE

func can_update_locomotion() -> bool:
	return _mode in [Mode.FREE, Mode.INTERACTING]

func _is_available() -> bool:
	return (_mode == Mode.FREE
		and not combat_component.is_busy_attacking()
		and not animation_component.is_locked())

func can_attack(stance: Stance) -> bool:
	if disable_attack or _mode != Mode.FREE:
		return false
	if stance not in [Stance.STANDING, Stance.CROUCHED]:
		return false
	# Combat decides whether a follow-up can be queued during an attack.
	return combat_component.is_busy_attacking() or not animation_component.is_locked()

func can_crouch(stance: Stance) -> bool:
	return not disable_crouch and stance == Stance.STANDING and _is_available()

func can_stand(stance: Stance) -> bool:
	return not disable_stand and stance == Stance.CROUCHED and _is_available()

func can_slide(stance: Stance) -> bool:
	return not disable_slide and stance == Stance.STANDING and _is_available()

func can_exit_slide(stance: Stance) -> bool:
	return stance == Stance.SLIDING and _is_available()

func can_jump(stance: Stance) -> bool:
	return not disable_jump and stance == Stance.STANDING and _is_available()

func can_interact(stance: Stance) -> bool:
	if disable_interactions or stance not in [Stance.STANDING, Stance.CROUCHED]:
		return false
	# Allow the interaction button to close an already-open forge menu.
	return is_interacting or _is_available()

func can_turn(stance: Stance) -> bool:
	return stance in [Stance.STANDING, Stance.CROUCHED] and _is_available()

func begin_interaction() -> bool:
	if disable_interactions or _mode in [Mode.STAGGERED, Mode.DEAD]:
		return false
	_set_mode(Mode.INTERACTING)
	return true

func end_interaction() -> void:
	if is_interacting:
		_set_mode(Mode.FREE)

## Call from a hit-reaction system only for hits that should stagger.
func begin_stagger() -> void:
	if not is_dead:
		_set_mode(Mode.STAGGERED)

func end_stagger() -> void:
	if _mode == Mode.STAGGERED:
		_set_mode(Mode.FREE)

## Connect HealthComponent.died to this method in the owning scene.
func die() -> void:
	_set_mode(Mode.DEAD)

func _set_mode(next_mode: Mode) -> void:
	if _mode == next_mode or is_dead:
		return
	var was_interacting := is_interacting
	_mode = next_mode
	if next_mode != Mode.FREE:
		combat_component.cancel_attack()
		animation_component.cancel_current_animation()
		actions_interrupted.emit()
	if was_interacting != is_interacting:
		interaction_changed.emit(is_interacting)
	mode_changed.emit()
