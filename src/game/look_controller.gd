class_name LookController
extends Node3D
## First-person view driven by raw mouse counts at Apex sensitivity and by the right stick
## with Apex-style look controls and aim assist.
##
## Mouse look reads InputEventMouseMotion.screen_relative, which carries raw counts while
## the mouse is captured (`relative` is scaled by the window's stretch factor). Yaw and
## pitch are kept as 64-bit degrees so long measurement sessions don't drift.

## Nodes in this group are aim-assist candidates; they provide aim_point() and `velocity`.
const TARGET_GROUP := "aim_assist_targets"
const PITCH_LIMIT := 89.0

var camera: Camera3D
var pillarbox: Pillarbox
var yaw := 0.0  ## Degrees, unwrapped, so it also counts full turns.
var pitch := 0.0
var total_counts := Vector2.ZERO  ## Raw mouse counts since reset_counters().
## Last frame's aim-assist state, for overlays: {"falloff", "angle"} or empty.
var assist_info := {}

var _time_at_full := 0.0


func _ready() -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	pillarbox = Pillarbox.new()
	add_child(pillarbox)
	_update_fov()
	Settings.changed.connect(_update_fov)
	_apply()


func _update_fov() -> void:
	camera.fov = Settings.vertical_fov()


func reset_counters() -> void:
	total_counts = Vector2.ZERO


func face(yaw_degrees: float, pitch_degrees: float = 0.0) -> void:
	yaw = yaw_degrees
	pitch = pitch_degrees
	_apply()


## Adds a view kick in degrees (x = yaw to the right, y = pitch up), e.g. recoil.
func kick(degrees: Vector2) -> void:
	yaw -= degrees.x
	pitch = clampf(pitch + degrees.y, -PITCH_LIMIT, PITCH_LIMIT)
	_apply()


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var counts := motion.screen_relative
	var dpc := Settings.degrees_per_count()
	yaw -= counts.x * dpc
	pitch = clampf(pitch - counts.y * dpc * (-1.0 if Settings.invert_y else 1.0), -PITCH_LIMIT, PITCH_LIMIT)
	total_counts += counts
	Telemetry.add_mouse(counts)
	_apply()


func _process(delta: float) -> void:
	var target := _best_target() if Settings.aim_assist else {}
	assist_info = target
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		_stick_look(pads[0], target, delta)
	_apply()


func _stick_look(pad: int, target: Dictionary, delta: float) -> void:
	var raw := Vector2(Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X), Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y))
	var shaped := StickCurves.shape(raw, Settings.stick_deadzone, Settings.stick_outer, Settings.stick_exponent)
	_time_at_full = _time_at_full + delta if shaped.length() >= 0.99 else 0.0
	var ramp := StickCurves.extra_turn_ramp(_time_at_full, Settings.ramp_delay, Settings.ramp_time)
	var rate := StickCurves.look_rate(shaped, Settings.yaw_speed, Settings.pitch_speed,
		Settings.extra_yaw, Settings.extra_pitch, ramp)
	var assist := Vector2.ZERO
	if not target.is_empty():
		rate = AimAssist.slowdown(rate, target["falloff"], Settings.aim_assist_slowdown)
		var move := Vector2(Input.get_joy_axis(pad, JOY_AXIS_LEFT_X), Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y))
		if shaped != Vector2.ZERO or move.length() > Settings.stick_deadzone:
			assist = AimAssist.rotational(target["angular_velocity"], target["falloff"], Settings.aim_assist_strength)
	yaw += (assist.x - rate.x) * delta
	pitch = clampf(pitch + (assist.y - rate.y) * delta, -PITCH_LIMIT, PITCH_LIMIT)


## The aim-assist target nearest the crosshair inside the outer cone, or {}.
func _best_target() -> Dictionary:
	var origin := camera.global_position
	var forward := -camera.global_basis.z
	var best: Node = null
	var best_angle := Settings.aim_assist_outer
	var best_point := Vector3.ZERO
	for node in get_tree().get_nodes_in_group(TARGET_GROUP):
		var point: Vector3 = node.call("aim_point")
		var angle := AimAssist.angle_to(origin, forward, point)
		if angle < best_angle:
			best = node
			best_angle = angle
			best_point = point
	if best == null:
		return {}
	return {
		"angle": best_angle,
		"falloff": AimAssist.falloff(best_angle, Settings.aim_assist_inner, Settings.aim_assist_outer),
		"angular_velocity": AimAssist.angular_velocity(origin, camera.global_basis, best_point, best.get("velocity")),
	}


func _apply() -> void:
	rotation = Vector3(deg_to_rad(pitch), deg_to_rad(fposmod(yaw, 360.0)), 0.0)
