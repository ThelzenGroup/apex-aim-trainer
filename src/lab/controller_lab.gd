extends Control
## Test 7: controller check.
##
## Shows raw stick values (Godot's SDL3 driver applies no deadzone at this level), the
## right stick after this build's response curve, triggers, held buttons and the motion
## sensors, and fires rumble on demand. Compare a pad over USB and Bluetooth, with Steam
## Input on and off.

const MENU := "res://scenes/main_menu.tscn"
const BUTTON_NAMES := ["A/Cross", "B/Circle", "X/Square", "Y/Triangle", "Back", "Guide", "Start",
	"L3", "R3", "LB/L1", "RB/R1", "Up", "Down", "Left", "Right", "Misc", "Paddle1", "Paddle2",
	"Paddle3", "Paddle4", "Touchpad"]

var _pad_index := 0
var _label: Label
var _left: StickView
var _right: StickView
var _max_left := 0.0
var _max_right := 0.0
var _status := ""


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	margin.add_child(row)
	_label = Label.new()
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_label)
	var sticks := VBoxContainer.new()
	row.add_child(sticks)
	_left = _add_stick(sticks, "Left stick (raw)")
	_right = _add_stick(sticks, "Right stick: raw (white) and after the curve (green)")


func _add_stick(parent: Control, title: String) -> StickView:
	var label := Label.new()
	label.text = title
	parent.add_child(label)
	var view := StickView.new()
	parent.add_child(view)
	return view


func _pad() -> int:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return -1
	return pads[clampi(_pad_index, 0, pads.size() - 1)]


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var pad := _pad()
	match key.keycode:
		KEY_ESCAPE:
			get_tree().change_scene_to_file(MENU)
		KEY_1, KEY_2, KEY_3, KEY_4:
			_pad_index = key.keycode - KEY_1
		KEY_R:
			_max_left = 0.0
			_max_right = 0.0
		KEY_Q when pad >= 0:
			Input.start_joy_vibration(pad, 0.6, 0.0, 0.5)
			_status = "Weak rumble sent"
		KEY_E when pad >= 0:
			Input.start_joy_vibration(pad, 0.0, 1.0, 0.5)
			_status = "Strong rumble sent"
		KEY_G when pad >= 0:
			Input.set_joy_motion_sensors_enabled(pad, not Input.is_joy_motion_sensors_enabled(pad))
		KEY_C when pad >= 0:
			if Input.is_joy_motion_sensors_calibrating(pad):
				Input.stop_joy_motion_sensors_calibration(pad)
				_status = "Calibration stopped"
			else:
				Input.start_joy_motion_sensors_calibration(pad)
				_status = "Calibrating: keep the controller still, then press C again"


func _process(_delta: float) -> void:
	var pads := Input.get_connected_joypads()
	var lines := PackedStringArray(["CONTROLLERS · test 7", ""])
	if pads.is_empty():
		lines.append("No controller connected. Plug one in or pair it over Bluetooth.")
	else:
		var names := PackedStringArray()
		for i in pads.size():
			names.append("[%d] %s" % [i + 1, Input.get_joy_name(pads[i])])
		lines.append("Connected: " + ",  ".join(names))
		lines.append_array(_pad_lines(_pad()))
	lines.append_array(["", _status, "",
		"[1-4] select pad   [Q] weak rumble   [E] strong rumble   [G] motion sensors on/off",
		"[C] start/stop gyro calibration   [R] reset maxima   [Esc] menu"])
	_label.text = "\n".join(lines)


func _pad_lines(pad: int) -> PackedStringArray:
	var left := Vector2(Input.get_joy_axis(pad, JOY_AXIS_LEFT_X), Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y))
	var right := Vector2(Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X), Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y))
	var shaped := StickCurves.shape(right, Settings.stick_deadzone, Settings.stick_outer, Settings.stick_exponent)
	_max_left = maxf(_max_left, left.length())
	_max_right = maxf(_max_right, right.length())
	for view: StickView in [_left, _right]:
		view.deadzone = Settings.stick_deadzone
		view.outer = Settings.stick_outer
	_left.raw = left
	_left.shaped = StickCurves.shape(left, Settings.stick_deadzone, Settings.stick_outer, 1.0)
	_right.raw = right
	_right.shaped = shaped
	_left.queue_redraw()
	_right.queue_redraw()

	var held := PackedStringArray()
	for button in BUTTON_NAMES.size():
		if Input.is_joy_button_pressed(pad, button):
			held.append(BUTTON_NAMES[button])
	var lines := PackedStringArray([
		"",
		"%s   GUID %s   known mapping: %s" % [Input.get_joy_name(pad), Input.get_joy_guid(pad), Input.is_joy_known(pad)],
		"Info: %s" % Input.get_joy_info(pad),
		"",
		"Left stick   raw (%+.3f, %+.3f)   length %.3f   max %.3f" % [left.x, left.y, left.length(), _max_left],
		"Right stick  raw (%+.3f, %+.3f)   length %.3f   max %.3f" % [right.x, right.y, right.length(), _max_right],
		"Right stick after curve (%+.3f, %+.3f)   deadzone %.2f, outer %.2f, exponent %.1f" % [
			shaped.x, shaped.y, Settings.stick_deadzone, Settings.stick_outer, Settings.stick_exponent],
		"Triggers  L %.3f   R %.3f" % [Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_LEFT), Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT)],
		"Buttons held: %s" % (", ".join(held) if not held.is_empty() else "none"),
		"",
	])
	if Input.has_joy_motion_sensors(pad):
		lines.append("Motion sensors: %s at %.0f Hz, %s" % [
			"ON" if Input.is_joy_motion_sensors_enabled(pad) else "off", Input.get_joy_motion_sensors_rate(pad),
			"calibrating" if Input.is_joy_motion_sensors_calibrating(pad)
				else ("calibrated" if Input.is_joy_motion_sensors_calibrated(pad) else "not calibrated")])
		lines.append("Gyro %s   Accelerometer %s   Gravity %s" % [
			_vec(Input.get_joy_gyroscope(pad)), _vec(Input.get_joy_accelerometer(pad)), _vec(Input.get_joy_gravity(pad))])
	else:
		lines.append("Motion sensors: not reported for this controller")
	lines.append("Rumble: %s   Light bar: %s" % [
		"supported" if Input.has_joy_vibration(pad) else "not reported",
		"supported" if Input.has_joy_light(pad) else "not reported"])
	return lines


static func _vec(v: Vector3) -> String:
	return "(%+.3f, %+.3f, %+.3f)" % [v.x, v.y, v.z]
