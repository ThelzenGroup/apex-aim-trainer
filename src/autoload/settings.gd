extends Node
## Player and display settings, saved to user://settings.cfg.
##
## Renderer, swapchain and frame-queue settings are only read when Godot starts, so
## apply_startup_and_restart() writes them to override.cfg next to the executable and
## restarts the game.

signal changed

const PATH := "user://settings.cfg"
const SAVED := {
	"mouse": ["sensitivity", "dpi", "fov_scale", "invert_y"],
	"controller": ["stick_deadzone", "stick_outer", "stick_exponent", "yaw_speed", "pitch_speed",
		"extra_yaw", "extra_pitch", "ramp_delay", "ramp_time",
		"aim_assist", "aim_assist_slowdown", "aim_assist_strength", "aim_assist_inner", "aim_assist_outer"],
	"display": ["window_mode", "vsync_mode", "max_fps", "accumulated_input"],
	"startup": ["rendering_driver", "swapchain_images", "frame_queue"],
}
const WINDOW_MODES := {
	"Windowed": DisplayServer.WINDOW_MODE_WINDOWED,
	"Borderless fullscreen": DisplayServer.WINDOW_MODE_FULLSCREEN,
	"Exclusive fullscreen": DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
}
const VSYNC_MODES := {
	"Off": DisplayServer.VSYNC_DISABLED,
	"On": DisplayServer.VSYNC_ENABLED,
	"Adaptive": DisplayServer.VSYNC_ADAPTIVE,
	"Mailbox": DisplayServer.VSYNC_MAILBOX,
}
const DRIVERS := ["d3d12", "vulkan"]

# Mouse, in Apex's own units.
var sensitivity := 2.0
var dpi := 800.0
var fov_scale := ApexSensitivity.fov_from_slider(90.0) / ApexSensitivity.FOV_SCALE_BASE  ## cl_fovScale
var invert_y := false

# Controller look and aim assist. Starting points to tune against Apex, not Apex's values.
var stick_deadzone := 0.08
var stick_outer := 0.95
var stick_exponent := 1.8
var yaw_speed := 160.0  ## degrees per second at full deflection
var pitch_speed := 120.0
var extra_yaw := 200.0
var extra_pitch := 0.0
var ramp_delay := 0.25  ## seconds at full deflection before extra turn speed starts
var ramp_time := 0.3
var aim_assist := true
var aim_assist_slowdown := 0.4
var aim_assist_strength := 0.4
var aim_assist_inner := 1.5  ## degrees
var aim_assist_outer := 5.0

# Display, applied immediately.
var window_mode := DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
var vsync_mode := DisplayServer.VSYNC_DISABLED
var max_fps := 0
var accumulated_input := true

# Read only at startup.
var rendering_driver := "d3d12"
var swapchain_images := 2
var frame_queue := 2


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for section: String in SAVED:
			for key: String in SAVED[section]:
				set(key, cfg.get_value(section, key, get(key)))
	apply()


func save() -> void:
	var cfg := ConfigFile.new()
	for section: String in SAVED:
		for key: String in SAVED[section]:
			cfg.set_value(section, key, get(key))
	cfg.save(PATH)
	apply()
	changed.emit()


func apply() -> void:
	Engine.max_fps = max_fps
	Input.use_accumulated_input = accumulated_input
	if DisplayServer.window_get_vsync_mode() != vsync_mode:
		DisplayServer.window_set_vsync_mode(vsync_mode)
	if DisplayServer.window_get_mode() != window_mode:
		DisplayServer.window_set_mode(window_mode)


func degrees_per_count() -> float:
	return ApexSensitivity.degrees_per_count(sensitivity)


func fov_4_3() -> float:
	return ApexSensitivity.fov_from_scale(fov_scale)


func vertical_fov() -> float:
	return ApexSensitivity.vertical_fov(fov_4_3())


## The frame cap Godot's docs recommend for variable-refresh monitors: just under the
## refresh rate, so V-Sync never engages (224 at 240 Hz, 416 at 480 Hz).
func vrr_frame_cap() -> int:
	var hz := DisplayServer.screen_get_refresh_rate()
	if not hz > 0.0:  # -1 or NaN when the display doesn't report a rate
		return 0
	return floori(hz - hz * hz / 3600.0)


## Writes the startup-only settings to override.cfg and restarts so they take effect.
func apply_startup_and_restart() -> void:
	save()
	var cfg := ConfigFile.new()
	cfg.set_value("rendering", "rendering_device/driver.windows", rendering_driver)
	cfg.set_value("rendering", "rendering_device/vsync/swapchain_image_count", swapchain_images)
	cfg.set_value("rendering", "rendering_device/vsync/frame_queue_size", frame_queue)
	cfg.set_value("display", "window/size/mode", window_mode)
	cfg.set_value("display", "window/vsync/vsync_mode", vsync_mode)
	cfg.save(override_path())
	OS.set_restart_on_exit(true, OS.get_cmdline_args())
	get_tree().quit()


static func override_path() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://override.cfg")
	return OS.get_executable_path().get_base_dir().path_join("override.cfg")


## Copies sensitivity (local/settings.cfg) and FOV (profile/profile.cfg) from this PC's
## Apex install. Returns a one-line summary of what was found.
func import_from_apex() -> String:
	var base := OS.get_environment("USERPROFILE").path_join("Saved Games/Respawn/Apex")
	var found := PackedStringArray()
	var sens := _read_apex_value(base.path_join("local/settings.cfg"), "mouse_sensitivity")
	if sens.is_valid_float():
		sensitivity = sens.to_float()
		found.append("sensitivity %s" % sens)
	var scale := _read_apex_value(base.path_join("profile/profile.cfg"), "cl_fovScale")
	if scale.is_valid_float():
		fov_scale = scale.to_float()
		found.append("cl_fovScale %s (%.1f° at 4:3)" % [scale, fov_4_3()])
	if found.is_empty():
		return "No Apex settings found under %s" % base
	save()
	return "Imported " + ", ".join(found)


static func _read_apex_value(path: String, key: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var regex := RegEx.create_from_string('(?m)^\\s*"?%s"?\\s+"([^"]*)"' % key)
	var result := regex.search(FileAccess.get_file_as_string(path))
	return result.get_string(1) if result else ""
