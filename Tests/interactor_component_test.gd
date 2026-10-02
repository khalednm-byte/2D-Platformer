extends SceneTree

class TestInteraction extends Interaction:
	func _on_interaction_requested(_player: Player) -> void:
		pass
	func can_interact() -> bool:
		return true
	func update_interactor_interacting_state(_interactor: Node2D) -> void:
		pass

var failures: int = 0
var requests: Array[Node] = []

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func make_target(label: String, x: float) -> InteractableComponent:
	var prop := TestInteraction.new()
	prop.position.x = x
	var target := InteractableComponent.new()
	target.parent = prop
	target.display_name = label
	target.collision_layer = 0
	target.collision_mask = 0
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	shape.shape = CircleShape2D.new()
	target.add_child(shape)
	prop.add_child(target)
	root.add_child(prop)
	target.interaction_requested.connect(func(actor: Node) -> void: requests.append(actor))
	return target

func _run() -> void:
	var player := load("res://Scenes/Player/player.tscn").instantiate() as Player
	var ui := load("res://Scenes/UI/player_ui.tscn").instantiate() as PlayerUI
	player.add_child(ui)
	player.ui_component = ui
	root.add_child(player)
	player.set_physics_process(false)
	var interactor := player.interactor_component
	var controller := player.action_controller
	var near_target := make_target("Nearby anvil", 10.0)
	var far_target := make_target("Distant smith", 100.0)
	check(not ui.panel.visible, "No target means no prompt")
	near_target._on_body_entered(player)
	near_target._on_body_entered(player)
	far_target._on_body_entered(player)
	check(interactor.current_target == near_target, "Closest equal-priority target wins")
	check(ui.panel.visible and ui.interaction_label.text == "Nearby anvil", "Target signal populates prompt")
	far_target.interaction_priority = 1
	await physics_frame
	await physics_frame
	check(interactor.current_target == far_target, "Priority changes are reevaluated without actor movement")
	far_target.enabled = false
	check(interactor.current_target == near_target, "Disabling target selects an alternative")
	far_target.enabled = true
	check(interactor.current_target == far_target, "Re-enabling overlapping target restores registration")
	far_target.interaction_priority = 0
	player.position.x = 90.0
	interactor.refresh_target()
	check(interactor.current_target == far_target, "Distance is measured from actor position")
	check(player.request_interaction(), "Player forwards allowed request")
	check(requests.size() == 1 and requests[0] == player, "Interactable receives the actor, not the component")
	player.velocity.x = 100.0
	check(not player.request_interaction(), "Moving player still cannot interact")
	player.velocity.x = 0.0
	controller.begin_stagger()
	check(not player.request_interaction() and not ui.panel.visible, "Stagger blocks requests and hides prompt")
	controller.end_stagger()
	check(ui.panel.visible, "Prompt returns after stagger without changing targets")
	player.switch_is_interacting(true)
	near_target.interaction_priority = 2
	interactor.refresh_target()
	check(not ui.panel.visible, "Target changes cannot reveal prompt during dialogue")
	player.switch_is_interacting(false)
	check(ui.panel.visible and ui.interaction_label.text == "Nearby anvil", "Dialogue release displays current target")
	near_target._on_body_exited(player)
	check(interactor.current_target == far_target, "Exiting a duplicated registration removes it fully")
	far_target.minimum_horizontal_distance = 20.0
	check(not player.request_interaction(), "Minimum separation remains enforced")
	far_target.minimum_horizontal_distance = 0.0
	far_target.get_parent().queue_free()
	await process_frame
	await process_frame
	check(interactor.current_target == null and not ui.panel.visible, "Deleting the final target clears the prompt")
	check(not player.request_interaction(), "Missing target is safe")

	# The area discovers a capability component, without requiring Player methods.
	var other_actor := Node2D.new()
	var other_interactor := InteractorComponent.new()
	other_interactor.actor = other_actor
	other_actor.add_child(other_interactor)
	root.add_child(other_actor)
	near_target._on_body_entered(player)
	near_target._on_body_entered(other_actor)
	near_target._on_body_exited(player)
	check(interactor.current_target == null, "One actor leaving unregisters only that actor")
	check(other_interactor.current_target == near_target, "Other overlapping actor retains its target")
	other_actor.free()
	near_target.enabled = false
	near_target.enabled = true
	near_target.get_parent().free()
	player.free()
	if failures == 0:
		print("PASS: targeting, registration, removal, UI signals, control locks, and generic actors")
	quit(1 if failures > 0 else 0)
