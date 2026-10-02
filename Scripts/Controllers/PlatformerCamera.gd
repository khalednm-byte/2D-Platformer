extends Camera2D

@export_category("Horizontal Look Ahead")
@export_range(0.0, 200.0, 1.0) var look_ahead_distance: float = 80.0 ## Maximum horizontal lead in world pixels, before zoom.
@export_range(0.0, 1.0, 0.05) var look_ahead_time: float = 0.3 ## Seconds of travel used to calculate the lead from speed.
@export_range(0.0, 100.0, 1.0) var minimum_speed: float = 15.0 ## Speeds at or below this magnitude count as idle (pixels/second).
@export_range(0.1, 20.0, 0.1) var look_ahead_response: float = 5.0 ## How quickly the lead approaches its target; higher is faster.
@export_range(0.1, 20.0, 0.1) var recenter_response: float = 6.0 ## How quickly the lead returns to zero after the delay; higher is faster.
@export_range(0.0, 100.0, 0.05) var recenter_delay: float = 2.0 ## Seconds of continuous idle before recentering begins.

var _body: CharacterBody2D # Parent character whose actual movement drives the camera.
var _home_position: Vector2 # Original local camera position, preserved when centering.
var _lead: float = 0.0 # Current smoothed horizontal lead; negative is left, positive is right.
var _desired_lead: float = 0.0 # Target lead, retained during braking and the idle delay.
var _idle_time: float = 0.0 # Seconds spent below the movement threshold; resets when movement resumes.

@export_category("Dialogue Cinematics")
@export_range(1.0, 2.0, 0.05) var dialogue_zoom_multiplier: float = 1.15 # Zoom relative to the camera's normal zoom.
@export_range(0.0, 0.25, 0.01) var dialogue_bar_height: float = 0.09 # Each black bar's height as a fraction of the viewport.
@export_range(0.05, 2.0, 0.05) var dialogue_transition_duration: float = 0.45 # Seconds to enter or leave the cinematic framing.

var _normal_zoom: Vector2 # Zoom to restore after dialogue.
var _dialogues: Array[DialogueResource] = [] # Conversations keeping the cinematic active.
var _cinematic_tween: Tween # Current transition, replaced if dialogue starts or ends mid-transition.
var _top_bar: ColorRect # Screen-space upper black bar; does not capture input.
var _bottom_bar: ColorRect # Screen-space lower black bar; does not capture input.
var _cinematic_blend: float = 0.0: # Zero is gameplay framing; one is full dialogue framing.
	set(value):
		_cinematic_blend = value
		zoom = _normal_zoom * lerpf(1.0, dialogue_zoom_multiplier, value)
		_top_bar.anchor_bottom = dialogue_bar_height * value
		_bottom_bar.anchor_top = 1.0 - dialogue_bar_height * value

func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	_home_position = position
	if _body == null:
		push_error("PlatformerCamera must be a child of a CharacterBody2D.")
		set_physics_process(false)
		return
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	# Read movement after the character has called move_and_slide().
	process_physics_priority = 1
	_normal_zoom = zoom
	var overlay := CanvasLayer.new() # Renders bars above the game and below dialogue (layer 100).
	overlay.name = "DialogueCinematics"
	overlay.layer = 90
	add_child(overlay)
	_top_bar = ColorRect.new()
	_bottom_bar = ColorRect.new()
	_top_bar.name = "TopBar"
	_bottom_bar.name = "BottomBar"
	for bar in [_top_bar, _bottom_bar]:
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(bar)
	_top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_bottom_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	var dialogue_manager := Engine.get_singleton("DialogueManager") # Dialogue Manager's registered runtime instance.
	dialogue_manager.dialogue_started.connect(_on_dialogue_started)
	dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)

func _on_dialogue_started(resource: DialogueResource) -> void:
	if not is_current():
		return
	if _dialogues.is_empty() and is_zero_approx(_cinematic_blend):
		_normal_zoom = zoom
	_dialogues.append(resource)
	_transition_cinematic(1.0)

func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource not in _dialogues:
		return
	_dialogues.erase(resource)
	if _dialogues.is_empty():
		_transition_cinematic(0.0)

func _transition_cinematic(target: float) -> void: # target is one to show the effect, zero to restore gameplay.
	if _cinematic_tween != null:
		_cinematic_tween.kill()
	_cinematic_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cinematic_tween.tween_property(self, "_cinematic_blend", target, dialogue_transition_duration)

func _physics_process(delta: float) -> void: # delta is the elapsed time for this physics tick, in seconds.
	var speed := _body.get_real_velocity().x # Actual horizontal speed after collisions, in pixels/second.
	var response := look_ahead_response # Smoothing rate for this tick; switches to recenter_response after the delay.
	if not _dialogues.is_empty():
		_idle_time = 0.0
		_desired_lead = 0.0
		response = recenter_response
	elif absf(speed) > minimum_speed:
		_idle_time = 0.0
		var predicted_lead := clampf(speed * look_ahead_time, -look_ahead_distance, look_ahead_distance) # Speed-based target, capped to the maximum lead.
		# Preserve the lead while slowing down; only the idle timer recenters it.
		if signf(predicted_lead) != signf(_desired_lead) or absf(predicted_lead) > absf(_desired_lead):
			_desired_lead = predicted_lead
	else:
		_idle_time += delta
		if _idle_time >= recenter_delay:
			_desired_lead = 0.0
			response = recenter_response
	_lead = lerpf(_lead, _desired_lead, 1.0 - exp(-response * delta))
	# Move the follow target, not Camera2D.offset, so native limits still apply.
	position = _home_position + Vector2(_lead, 0.0)
