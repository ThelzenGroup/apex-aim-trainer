class_name SettingsPanel
extends ScrollContainer
## Every setting the labs use, edited in place and saved as you go. Startup-only settings
## (renderer, swapchain, frame queue) apply after "Apply and restart".

var _grid: GridContainer
var _apex_result: Label


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

	_section(box, "Mouse (Apex values)")
	_spin("Apex sensitivity", "sensitivity", 0.05, 20.0, 0.001)
	_spin("Mouse DPI", "dpi", 100.0, 32000.0, 1.0)
	var fov := _spin_custom("Apex FOV slider", 70.0, 120.0, 0.01,
		func() -> float: return ApexSensitivity.slider_from_scale(Settings.fov_scale),
		func(v: float) -> void: Settings.fov_scale = ApexSensitivity.fov_from_slider(v) / ApexSensitivity.FOV_SCALE_BASE)
	fov.tooltip_text = "Apex's slider is approximate: 110 on the slider renders 108.5° (cl_fovScale 1.55)."
	_check("Invert Y", "invert_y")
	var import_button := Button.new()
	import_button.text = "Import from this PC's Apex settings"
	import_button.pressed.connect(func() -> void:
		_apex_result.text = Settings.import_from_apex()
		_refresh())
	box.add_child(import_button)
	_apex_result = Label.new()
	_apex_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_apex_result)

	_section(box, "Display (applies immediately)")
	_option("Window mode", "window_mode", Settings.WINDOW_MODES)
	_option("V-Sync", "vsync_mode", Settings.VSYNC_MODES)
	_spin("Frame cap (0 = none)", "max_fps", 0.0, 2000.0, 1.0)
	var vrr := Button.new()
	var cap := Settings.vrr_frame_cap()
	vrr.text = "Use VRR frame cap (%d FPS)" % cap if cap else "VRR frame cap (refresh rate unknown)"
	vrr.disabled = cap == 0
	vrr.pressed.connect(func() -> void:
		Settings.max_fps = Settings.vrr_frame_cap()
		Settings.save()
		_refresh())
	box.add_child(vrr)
	_check("Accumulated mouse input", "accumulated_input")

	_section(box, "Latency (applies after restart)")
	var drivers := {}
	for driver: String in Settings.DRIVERS:
		drivers[driver] = driver
	_option("Renderer (Windows)", "rendering_driver", drivers)
	_spin("Swapchain images", "swapchain_images", 2.0, 4.0, 1.0)
	_spin("Frame queue size", "frame_queue", 2.0, 4.0, 1.0)
	var restart := Button.new()
	restart.text = "Apply and restart"
	restart.pressed.connect(Settings.apply_startup_and_restart)
	box.add_child(restart)

	_section(box, "Controller look and aim assist (tuning values)")
	_spin("Stick deadzone", "stick_deadzone", 0.0, 0.5, 0.01)
	_spin("Outer threshold", "stick_outer", 0.5, 1.0, 0.01)
	_spin("Response exponent", "stick_exponent", 1.0, 4.0, 0.05)
	_spin("Yaw speed (°/s)", "yaw_speed", 10.0, 720.0, 1.0)
	_spin("Pitch speed (°/s)", "pitch_speed", 10.0, 720.0, 1.0)
	_spin("Extra yaw (°/s)", "extra_yaw", 0.0, 720.0, 1.0)
	_spin("Extra pitch (°/s)", "extra_pitch", 0.0, 720.0, 1.0)
	_spin("Ramp-up delay (s)", "ramp_delay", 0.0, 2.0, 0.01)
	_spin("Ramp-up time (s)", "ramp_time", 0.0, 2.0, 0.01)
	_check("Aim assist", "aim_assist")
	_spin("Aim-assist slowdown", "aim_assist_slowdown", 0.0, 1.0, 0.01)
	_spin("Aim-assist rotation", "aim_assist_strength", 0.0, 1.0, 0.01)
	_spin("Inner cone (°)", "aim_assist_inner", 0.0, 10.0, 0.1)
	_spin("Outer cone (°)", "aim_assist_outer", 0.5, 20.0, 0.1)


func _section(box: VBoxContainer, title: String) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 18)
	box.add_child(label)
	_grid = GridContainer.new()
	_grid.columns = 2
	box.add_child(_grid)


func _row(text: String, control: Control) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(190, 0)
	_grid.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_child(control)


func _spin(text: String, key: String, min_value: float, max_value: float, step: float) -> SpinBox:
	return _spin_custom(text, min_value, max_value, step,
		func() -> float: return Settings.get(key),
		func(v: float) -> void: Settings.set(key, int(v) if typeof(Settings.get(key)) == TYPE_INT else v))


func _spin_custom(text: String, min_value: float, max_value: float, step: float,
		getter: Callable, setter: Callable) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.value = getter.call()
	spin.set_meta("getter", getter)
	spin.value_changed.connect(func(v: float) -> void:
		setter.call(v)
		Settings.save())
	_row(text, spin)
	return spin


func _check(text: String, key: String) -> void:
	var box := CheckBox.new()
	box.button_pressed = Settings.get(key)
	box.set_meta("getter", func() -> bool: return Settings.get(key))
	box.toggled.connect(func(on: bool) -> void:
		Settings.set(key, on)
		Settings.save())
	_row(text, box)


func _option(text: String, key: String, choices: Dictionary) -> void:
	var option := OptionButton.new()
	for label: String in choices:
		option.add_item(label)
	option.selected = choices.values().find(Settings.get(key))
	option.set_meta("getter", func() -> int: return choices.values().find(Settings.get(key)))
	option.item_selected.connect(func(index: int) -> void:
		Settings.set(key, choices.values()[index])
		Settings.save())
	_row(text, option)


## Re-reads every control from Settings (after an import or a preset button).
func _refresh() -> void:
	for control in find_children("*", "Control", true, false):
		if not control.has_meta("getter"):
			continue
		var value: Variant = control.get_meta("getter").call()
		if control is SpinBox:
			control.set_value_no_signal(value)
		elif control is CheckBox:
			control.set_pressed_no_signal(value)
		elif control is OptionButton:
			control.selected = value
