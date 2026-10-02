extends SceneTree

# Run with: Godot --headless --path . --script res://Tests/action_controller_test.gd
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var player := load("res://Scenes/Player/player.tscn").instantiate() as Player
	root.add_child(player)
	player.set_physics_process(false)
	var controller := player.action_controller
	var combat := player.combat_component
	var animation := player.animation_component
	check(controller != null, "Player scene must wire its action controller")
	check(controller.can_attack(Player.Stance.STANDING), "Standing player can attack")
	check(controller.can_attack(Player.Stance.CROUCHED), "Crouched player can attack")
	check(not controller.can_attack(Player.Stance.SLIDING), "Sliding blocks attacks")
	check(not controller.can_interact(Player.Stance.ENTERING_CROUCH), "Transitions block interaction")

	check(player.request_attack(), "First attack starts")
	check(not controller.can_jump(player.current_stance), "Attack blocks jumping")
	check(not controller.can_turn(player.current_stance), "Attack blocks turning")
	check(player.request_attack(), "Second input queues a combo despite animation lock")
	animation._on_animation_finished()
	check(combat.is_attacking and combat.internal_combo_index == 1, "Natural completion advances queued combo")

	check(player.request_attack(), "A further combo can be queued")
	combat._activate_hitbox()
	check(combat.hitbox_component.current_attack_info != null, "Attack profile activates the generic hitbox")
	controller.begin_stagger()
	check(not combat.is_attacking and not combat.attack_queued, "Stagger clears attack and queue")
	check(combat.current_attack == null and combat.internal_combo_index == 0, "Stagger clears attack context")
	check(not combat.hitbox_active and combat.hitbox_component.current_attack_info == null, "Stagger disarms hitbox immediately")
	check(not animation.is_locked() and not animation.animated_sprite.is_playing(), "Stagger stops attack playback and unlocks it")
	check(not player.request_attack() and not controller.can_move(), "Stagger blocks gameplay")
	combat._on_attack_finished()
	check(not combat.is_attacking, "Late completion cannot restart canceled combo")
	controller.end_stagger()
	check(player.request_attack(), "Gameplay resumes after stagger")
	combat.cancel_attack()
	combat.cancel_attack()
	check(not combat.is_attacking, "Repeated cancellation is safe")
	await physics_frame
	await physics_frame
	check(combat.hitbox_component.hitbox_collision.disabled, "Canceled generic collider is disabled after deferred updates")

	check(player.request_attack(), "Attack before scripted dialogue starts")
	player.switch_is_interacting(true)
	check(player.is_interacting and not combat.is_attacking, "Dialogue entry cancels existing attack")
	check(not player.request_attack() and not controller.can_jump(player.current_stance), "Dialogue blocks attacks and jumps")
	check(controller.can_interact(player.current_stance), "Interaction button remains available to close forge")
	player.switch_is_interacting(false)
	check(not player.is_interacting and controller.can_move(), "Dialogue release restores control")
	check(player.input_lock_time_remaining > 0.0, "Dialogue release preserves input grace period")

	player.current_stance = Player.Stance.ENTERING_SLIDE
	player.is_turning = true
	controller.begin_stagger()
	check(player.current_stance in [Player.Stance.STANDING, Player.Stance.CROUCHED], "Interrupted slide returns to a stable stance")
	check(not player.is_turning, "Interrupted turn cannot leave facing stuck")
	controller.end_stagger()

	check(player.request_attack(), "Attack before death starts")
	var lethal := AttackInfo.new()
	lethal.data = AttackData.new()
	lethal.data.damage = 10000.0
	player.hurtbox_component.health_component.damage(lethal)
	check(controller.is_dead and not combat.is_attacking, "Health death signal cancels combat")
	check(not controller.can_move() and not controller.can_update_locomotion(), "Death blocks movement and idle playback")
	controller.end_stagger()
	player.switch_is_interacting(false)
	check(not controller.begin_interaction() and not player.request_attack(), "Late releases cannot undo death")
	player.free()

	var qaswar := load("res://Scenes/Player/qaswar.tscn").instantiate() as Player
	root.add_child(qaswar)
	qaswar.set_physics_process(false)
	check(qaswar.action_controller.disable_attack, "Qaswar attack setting is preserved")
	check(qaswar.action_controller.disable_slide, "Qaswar slide setting is preserved")
	check(qaswar.action_controller.disable_crouch, "Qaswar crouch setting is preserved")
	check(not qaswar.request_attack(), "Qaswar disabled attack is enforced")
	qaswar.free()
	if failures == 0:
		print("PASS: action permissions, combo progression, interruption, dialogue, death, and both scene configurations")
	quit(1 if failures > 0 else 0)
