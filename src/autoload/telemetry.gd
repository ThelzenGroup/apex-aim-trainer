extends Node
## Frame-time and mouse telemetry.
##
## Keeps a rolling window of frame times for the on-screen stats. While recording, writes
## one CSV row per frame to user://logs/ plus a JSON file describing the PC and settings,
## so a session on the test PC can be sent back and analysed.

const WINDOW_FRAMES := 2000

var recording := false
var last_log_path := ""
## Free-form value for the CSV's last column (the load lab writes live projectile counts).
var note := ""

var _ring := PackedFloat32Array()
var _ring_next := 0
var _last_usec := 0
var _frame := 0
var _start_usec := 0
var _file: FileAccess
var _counts := Vector2.ZERO
var _events := 0
var _second_start := 0
var _second_events := 0
var _events_per_second := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ring.resize(WINDOW_FRAMES)


## Called by the look controller for every mouse motion event.
func add_mouse(counts: Vector2) -> void:
	_counts += counts
	_events += 1
	_second_events += 1


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if _last_usec != 0:
		var ms := (now - _last_usec) / 1000.0
		_ring[_ring_next % WINDOW_FRAMES] = ms
		_ring_next += 1
		if recording:
			_file.store_line("%d,%.6f,%.4f,%d,%d,%d,%s" % [
				_frame, (now - _start_usec) / 1e6, ms, _counts.x, _counts.y, _events, note])
	_last_usec = now
	_frame += 1
	_counts = Vector2.ZERO
	_events = 0
	if now - _second_start >= 1_000_000:
		_events_per_second = roundi(_second_events * 1e6 / (now - _second_start))
		_second_events = 0
		_second_start = now


## Mouse events received over the last full second. With accumulated input off this is
## close to the mouse's polling rate; with it on, Godot merges events to one per frame.
func mouse_events_per_second() -> int:
	return _events_per_second


## Average FPS, 1% low FPS (mean of the slowest 1% of frames) and the slowest frame in ms,
## over the last WINDOW_FRAMES frames.
func stats() -> Dictionary:
	var n := mini(_ring_next, WINDOW_FRAMES)
	if n == 0:
		return {"fps": 0.0, "low_1": 0.0, "worst_ms": 0.0}
	var frames := _ring.slice(0, n)
	frames.sort()
	var total := 0.0
	for ms in frames:
		total += ms
	var slowest := maxi(1, n / 100)
	var slow_total := 0.0
	for i in range(n - slowest, n):
		slow_total += frames[i]
	return {"fps": 1000.0 * n / total, "low_1": 1000.0 * slowest / slow_total, "worst_ms": frames[n - 1]}


func stats_line() -> String:
	var s := stats()
	return "FPS %d avg · 1%% low %d · worst frame %.2f ms" % [s["fps"], s["low_1"], s["worst_ms"]]


func toggle_recording(label: String) -> void:
	if recording:
		stop_recording()
	else:
		start_recording(label)


func start_recording(label: String) -> void:
	DirAccess.make_dir_recursive_absolute("user://logs")
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var base := "user://logs/%s_%s" % [label, stamp]
	var info := FileAccess.open(base + ".json", FileAccess.WRITE)
	info.store_string(JSON.stringify(system_info(), "  "))
	_file = FileAccess.open(base + ".csv", FileAccess.WRITE)
	_file.store_line("frame,time_s,frame_ms,mouse_counts_x,mouse_counts_y,mouse_events,note")
	_start_usec = Time.get_ticks_usec()
	last_log_path = ProjectSettings.globalize_path(base + ".csv")
	recording = true


func stop_recording() -> void:
	if not recording:
		return
	recording = false
	_file.close()
	_file = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		stop_recording()


func logs_folder() -> String:
	DirAccess.make_dir_recursive_absolute("user://logs")
	return ProjectSettings.globalize_path("user://logs")


func system_info() -> Dictionary:
	return {
		"build": ProjectSettings.get_setting("application/config/version", ""),
		"engine": Engine.get_version_info()["string"],
		"os": "%s %s" % [OS.get_name(), OS.get_version()],
		"cpu": "%s (%d threads)" % [OS.get_processor_name(), OS.get_processor_count()],
		"gpu": "%s (%s)" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor()],
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"refresh_rate_hz": DisplayServer.screen_get_refresh_rate(),
		"screen_size": str(DisplayServer.screen_get_size()),
		"window_size": str(DisplayServer.window_get_size()),
		"window_mode": Settings.WINDOW_MODES.find_key(DisplayServer.window_get_mode()),
		"vsync_mode": Settings.VSYNC_MODES.find_key(DisplayServer.window_get_vsync_mode()),
		"max_fps": Engine.max_fps,
		"physics_ticks_per_second": Engine.physics_ticks_per_second,
		"swapchain_images": ProjectSettings.get_setting("rendering/rendering_device/vsync/swapchain_image_count"),
		"frame_queue_size": ProjectSettings.get_setting("rendering/rendering_device/vsync/frame_queue_size"),
		"accumulated_input": Input.is_using_accumulated_input(),
		"apex_sensitivity": Settings.sensitivity,
		"dpi": Settings.dpi,
		"cl_fov_scale": Settings.fov_scale,
	}
