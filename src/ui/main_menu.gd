extends Control
## Start screen. The system summary at the top is test 2 (launch check): it should name
## your GPU, the renderer you picked and your monitor's real refresh rate.

const LABS := [
	["Mouse lab: sensitivity and polling rate (tests 3 and 4)", "res://scenes/lab/mouse_lab.tscn"],
	["Latency flash: click-to-photon (test 5)", "res://scenes/lab/latency_lab.tscn"],
	["Bot load: bots, bullets and hit tests (test 6)", "res://scenes/lab/load_lab.tscn"],
	["Controllers: sticks, gyro and rumble (test 7)", "res://scenes/lab/controller_lab.tscn"],
]

var _info: Label
var _logs_folder := Telemetry.logs_folder()


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 40)
	margin.add_child(columns)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	columns.add_child(left)
	var title := Label.new()
	title.text = "Apex Aim Lab · first-week engine tests"
	title.add_theme_font_size_override("font_size", 28)
	left.add_child(title)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_info)
	for lab: Array in LABS:
		var button := Button.new()
		button.text = lab[0]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var path: String = lab[1]
		button.pressed.connect(func() -> void: get_tree().change_scene_to_file(path))
		left.add_child(button)
	var logs := Button.new()
	logs.text = "Open the logs folder"
	logs.alignment = HORIZONTAL_ALIGNMENT_LEFT
	logs.pressed.connect(func() -> void: OS.shell_open(Telemetry.logs_folder()))
	left.add_child(logs)
	var quit := Button.new()
	quit.text = "Quit"
	quit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	quit.pressed.connect(get_tree().quit)
	left.add_child(quit)

	var settings := SettingsPanel.new()
	settings.custom_minimum_size = Vector2(460, 0)
	columns.add_child(settings)


func _process(_delta: float) -> void:
	var info := Telemetry.system_info()
	_info.text = "\n".join([
		"%s on %s" % [info["engine"], info["os"]],
		"GPU: %s · renderer %s (%s)" % [info["gpu"], info["rendering_driver"], info["rendering_method"]],
		"CPU: %s" % info["cpu"],
		"Display: %s at %s · %s · V-Sync %s · frame cap %s" % [
			info["screen_size"], "%.0f Hz" % info["refresh_rate_hz"] if info["refresh_rate_hz"] > 0.0 else "unknown refresh rate",
			info["window_mode"], info["vsync_mode"],
			info["max_fps"] if info["max_fps"] else "none"],
		"Latency settings: swapchain %d images · frame queue %d · physics %d ticks/s" % [
			info["swapchain_images"], info["frame_queue_size"], info["physics_ticks_per_second"]],
		Telemetry.stats_line(),
		"Logs: %s" % _logs_folder,
	])
