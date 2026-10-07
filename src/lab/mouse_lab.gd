extends Lab
## Tests 3 and 4: sensitivity exactness and mouse polling-rate stress.
##
## Shows the raw counts received, the degrees turned and the cm/360 your settings imply,
## so a full turn can be measured against Apex's Firing Range. Tab switches to a visible
## cursor over a menu panel, the path where high-polling mice have caused stalls.

const PILLAR_DISTANCE := 20.0

var look: LookController
var _menu: Control


func lab_name() -> String:
	return "mouse"


func _ready() -> void:
	super()
	LabWorld.build_range(self)
	look = LookController.new()
	look.position = Vector3(0, 1.6, 0)
	add_child(look)
	_build_pillars()
	LabWorld.add_crosshair(self)
	_menu = _build_menu()


## Twelve pillars every 30 degrees, labelled with how far right you've turned to face
## them. The red one is straight ahead at the start.
func _build_pillars() -> void:
	for i in 12:
		var degrees := i * 30
		var direction := Vector3(sin(deg_to_rad(degrees)), 0.0, -cos(deg_to_rad(degrees)))
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.25
		mesh.bottom_radius = 0.25
		mesh.height = 3.2
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.9, 0.15, 0.1) if degrees == 0 else Color(0.75, 0.75, 0.8)
		mesh.material = material
		var pillar := MeshInstance3D.new()
		pillar.mesh = mesh
		pillar.position = direction * PILLAR_DISTANCE + Vector3(0, 1.6, 0)
		add_child(pillar)
		var label := Label3D.new()
		label.text = "%d°" % degrees
		label.font_size = 96
		label.pixel_size = 0.01
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = pillar.position + Vector3(0, 2.2, 0)
		add_child(label)


## A plain menu shown with the visible cursor, so moving the mouse over real controls is
## part of the visible-cursor test.
func _build_menu() -> Control:
	var layer := CanvasLayer.new()
	add_child(layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(360, 0)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Visible-cursor test: sweep the mouse over these controls"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(title)
	for i in 6:
		var button := Button.new()
		button.text = "Menu item %d" % (i + 1)
		box.add_child(button)
	var slider := HSlider.new()
	slider.max_value = 100
	box.add_child(slider)
	var list := ItemList.new()
	list.custom_minimum_size = Vector2(0, 160)
	for i in 30:
		list.add_item("List entry %d" % (i + 1))
	box.add_child(list)
	center.visible = false
	return center


func _on_key(keycode: Key) -> void:
	match keycode:
		KEY_R:
			look.reset_counters()
		KEY_HOME:
			look.face(0.0)
			look.reset_counters()
		KEY_TAB:
			var show_cursor := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if show_cursor else Input.MOUSE_MODE_CAPTURED
			_menu.visible = show_cursor


func _process(_delta: float) -> void:
	var dpc := Settings.degrees_per_count()
	var size := get_viewport().get_visible_rect().size
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	hud.text = "\n".join([
		"MOUSE LAB · tests 3 and 4",
		"Apex sensitivity %.3f at %d DPI → %.5f° per count → %.2f cm per 360°" % [
			Settings.sensitivity, Settings.dpi, dpc, ApexSensitivity.cm_per_360(Settings.sensitivity, Settings.dpi)],
		"FOV: cl_fovScale %.4f = %.2f° at 4:3, %.2f° horizontal on this screen" % [
			Settings.fov_scale, Settings.fov_4_3(), ApexSensitivity.horizontal_fov(Settings.fov_4_3(), size.x / size.y)],
		"",
		"Raw counts since reset: x %d, y %d" % [look.total_counts.x, look.total_counts.y],
		"Turned right: %.3f° (%.4f turns)" % [0.0 - look.yaw + 0.0, (0.0 - look.yaw + 0.0) / 360.0],
		"Mouse events per second: %d (accumulated input %s)" % [
			Telemetry.mouse_events_per_second(), "on" if Input.is_using_accumulated_input() else "off"],
		Telemetry.stats_line(),
		"Cursor: %s" % ("captured (raw input)" if captured else "VISIBLE (menu path)"),
		recording_line(),
		"",
		"[Home] face the red pillar and reset   [R] reset counters   [Tab] visible cursor   [Esc] menu",
	])
