class_name Lab
extends Node3D
## Base for the 3D lab scenes: captures the mouse, shows a HUD, and handles the keys every
## lab shares (Esc back to the menu, L to start or stop a CSV log).

const MENU := "res://scenes/main_menu.tscn"

var hud: Label


## Short name used for log files.
func lab_name() -> String:
	return "lab"


func _ready() -> void:
	hud = LabWorld.add_hud(self)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _exit_tree() -> void:
	Telemetry.stop_recording()
	Telemetry.note = ""
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# Keys are read in _input, before GUI controls, so a focused menu button can't swallow
# Tab or Esc.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	get_viewport().set_input_as_handled()
	match key.keycode:
		KEY_ESCAPE:
			get_tree().change_scene_to_file(MENU)
		KEY_L:
			Telemetry.toggle_recording(lab_name())
		_:
			_on_key(key.keycode)


## Lab-specific keys.
func _on_key(_keycode: Key) -> void:
	pass


func recording_line() -> String:
	if Telemetry.recording:
		return "● Recording to %s   [L] stop" % Telemetry.last_log_path
	return "Not recording   [L] start CSV log"
