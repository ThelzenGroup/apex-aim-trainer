extends Lab
## Test 5: click-to-photon latency.
##
## Every mouse click turns the screen white for a few frames. Film the mouse and screen
## with a phone in slow motion (240 FPS) and count video frames from the button going
## down to the flash; do the same with a gunshot in Apex's Firing Range. Clicks are
## marked "click" in the CSV log.

const FLASH_USEC := 50_000
const CAPS := ["uncapped", "vrr", "refresh"]

var _flash: ColorRect
var _flash_until := 0
var _clicks := 0
var _cap_index := 0


func lab_name() -> String:
	return "latency"


func _ready() -> void:
	super()
	LabWorld.build_range(self)
	var look := LookController.new()
	look.position = Vector3(0, 1.6, 0)
	add_child(look)
	LabWorld.add_crosshair(self)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_flash = ColorRect.new()
	_flash.color = Color.WHITE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.visible = false
	layer.add_child(_flash)


func _input(event: InputEvent) -> void:
	super(event)
	var button := event as InputEventMouseButton
	if button and button.pressed:
		_flash.visible = true
		_flash_until = Time.get_ticks_usec() + FLASH_USEC
		_clicks += 1
		Telemetry.note = "click"


func _on_key(keycode: Key) -> void:
	match keycode:
		KEY_V:
			var modes: Array = Settings.VSYNC_MODES.values()
			Settings.vsync_mode = modes[(modes.find(Settings.vsync_mode) + 1) % modes.size()]
			Settings.save()
		KEY_F:
			_cap_index = (_cap_index + 1) % CAPS.size()
			match CAPS[_cap_index]:
				"uncapped":
					Settings.max_fps = 0
				"vrr":
					Settings.max_fps = Settings.vrr_frame_cap()
				"refresh":
					var hz := DisplayServer.screen_get_refresh_rate()
					Settings.max_fps = roundi(hz) if hz > 0.0 else 0
			Settings.save()


func _process(_delta: float) -> void:
	if Telemetry.note == "click":
		Telemetry.note = ""  # Telemetry has already written this frame's row
	if _flash.visible and Time.get_ticks_usec() > _flash_until:
		_flash.visible = false
	hud.text = "\n".join([
		"LATENCY FLASH · test 5 · clicks %d" % _clicks,
		"%s · %s · V-Sync %s · frame cap %s" % [
			RenderingServer.get_current_rendering_driver_name(), Settings.WINDOW_MODES.find_key(DisplayServer.window_get_mode()),
			Settings.VSYNC_MODES.find_key(DisplayServer.window_get_vsync_mode()), Engine.max_fps if Engine.max_fps else "none"],
		"Swapchain %d images · frame queue %d · %.0f Hz display" % [
			ProjectSettings.get_setting("rendering/rendering_device/vsync/swapchain_image_count"),
			ProjectSettings.get_setting("rendering/rendering_device/vsync/frame_queue_size"),
			DisplayServer.screen_get_refresh_rate()],
		Telemetry.stats_line(),
		recording_line(),
		"[Click] flash   [V] cycle V-Sync   [F] cycle frame cap (none / VRR / refresh)   [Esc] menu",
		"Swapchain and frame queue are set in the menu's settings (needs a restart).",
	])
