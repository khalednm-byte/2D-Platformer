extends SceneTree

# Godot --headless --path . --script res://Tests/platformer_camera_test.gd
const CameraScript = preload("res://Scripts/Controllers/PlatformerCamera.gd")
var failures: int = 0
var body: CharacterBody2D
var camera: Camera2D

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func travel(speed: float, frames: int) -> void:
	for frame in range(frames):
		await physics_frame
		body.velocity = Vector2(speed, 0.0)
		body.move_and_slide()
		camera._physics_process(1.0 / Engine.physics_ticks_per_second)

func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320, 180)
	root.add_child(viewport)
	body = CharacterBody2D.new()
	body.position = Vector2(400, 200)
	camera = CameraScript.new()
	camera.position.y = -20.0
	camera.limit_left = 0
	camera.limit_right = 2000
	camera.limit_top = 0
	camera.limit_bottom = 500
	camera.position_smoothing_enabled = true
	body.add_child(camera)
	viewport.add_child(body)
	camera.set_physics_process(false)
	await travel(250.0, 45)
	check(camera.position.x > 65.0 and camera.position.x <= 80.0, "Running looks ahead within the configured maximum")
	check(camera.position.y == -20.0, "Vertical framing is preserved")
	var before_reversal := camera.position.x
	await travel(-250.0, 1)
	check(camera.position.x > 0.0 and camera.position.x < before_reversal, "Reversal eases rather than snapping")
	await travel(-250.0, 45)
	check(camera.position.x < -65.0, "Leftward travel leads left")
	# Reproduce the player's gradual braking, not just an instant velocity change.
	var braking_speed := -250.0
	while braking_speed < 0.0:
		braking_speed = move_toward(braking_speed, 0.0, 2000.0 / Engine.physics_ticks_per_second)
		await travel(braking_speed, 1)
	check(camera.position.x < -65.0, "Deceleration must not pull the look-ahead back toward center")
	await travel(0.0, int(1.9 * Engine.physics_ticks_per_second))
	check(camera.position.x < -65.0, "Camera retains look-ahead until the two-second delay elapses")
	await travel(-250.0, 2)
	await travel(0.0, int(1.9 * Engine.physics_ticks_per_second))
	check(camera.position.x < -65.0, "Resuming movement resets the full idle delay")
	await travel(0.0, int(1.6 * Engine.physics_ticks_per_second))
	check(absf(camera.position.x) < 2.0, "Stopping returns the camera to center")
	await travel(5.0, 20)
	check(absf(camera.position.x) < 1.0, "Tiny movement does not create camera jitter")
	await travel(1000.0, 40)
	check(camera.position.x <= 80.0, "High speed cannot exceed maximum lead")
	body.position.x = 1990.0
	camera.reset_smoothing()
	camera.force_update_scroll()
	check(camera.get_screen_center_position().x <= 1840.1, "Right limit includes half the viewport width")
	body.position.x = 10.0
	camera.reset_smoothing()
	camera.force_update_scroll()
	check(camera.get_screen_center_position().x >= 159.9, "Left limit remains respected")
	var dialogue_manager := Engine.get_singleton("DialogueManager")
	var normal_zoom := camera.zoom
	var dialogue := DialogueResource.new()
	var unrelated_dialogue := DialogueResource.new()
	camera.make_current()
	dialogue_manager.dialogue_started.emit(dialogue)
	await create_timer(0.55).timeout
	check(camera.zoom.is_equal_approx(normal_zoom * 1.15), "Dialogue smoothly zooms in")
	var top := camera.get_node("DialogueCinematics/TopBar") as ColorRect
	var bottom := camera.get_node("DialogueCinematics/BottomBar") as ColorRect
	check(is_equal_approx(top.size.y, 16.2) and is_equal_approx(bottom.size.y, 16.2), "Bars occupy nine percent of the viewport each")
	check(top.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Bars do not block dialogue input")
	dialogue_manager.dialogue_ended.emit(unrelated_dialogue)
	await create_timer(0.55).timeout
	check(camera.zoom.is_equal_approx(normal_zoom * 1.15), "Unrelated dialogue completion does not remove framing")
	viewport.size = Vector2i(640, 360)
	await process_frame
	check(is_equal_approx(top.size.y, 32.4) and is_equal_approx(bottom.size.y, 32.4), "Bars follow viewport resizing")
	dialogue_manager.dialogue_ended.emit(dialogue)
	await create_timer(0.15).timeout
	dialogue_manager.dialogue_started.emit(dialogue)
	await create_timer(0.55).timeout
	check(camera.zoom.is_equal_approx(normal_zoom * 1.15), "A new dialogue can reverse an unfinished exit transition")
	dialogue_manager.dialogue_ended.emit(dialogue)
	await create_timer(0.55).timeout
	check(camera.zoom.is_equal_approx(normal_zoom), "Dialogue closure restores original zoom")
	check(is_zero_approx(top.size.y) and is_zero_approx(bottom.size.y), "Dialogue closure retracts both bars")
	viewport.free()
	if failures == 0:
		print("PASS: camera movement, limits, dialogue zoom, letterboxing, resizing, and transition reversal")
	quit(1 if failures > 0 else 0)
