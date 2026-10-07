class_name LabWorld
## Shared pieces for the lab scenes: a lit range with a checkered floor (for motion
## reference), a HUD label and a crosshair.


static func build_range(parent: Node3D) -> void:
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = environment
	parent.add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.shadow_enabled = true
	parent.add_child(sun)

	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(400, 400)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_texture = _checker_texture()
	floor_material.uv1_triplanar = true
	floor_material.uv1_world_triplanar = true
	floor_material.uv1_scale = Vector3(0.5, 0.5, 0.5)  # one checker square per metre
	floor_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	floor_mesh.material = floor_material
	var floor_instance := MeshInstance3D.new()
	floor_instance.mesh = floor_mesh
	parent.add_child(floor_instance)


static func _checker_texture() -> ImageTexture:
	var image := Image.create(64, 64, true, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var light := (x / 32 + y / 32) % 2 == 0
			image.set_pixel(x, y, Color(0.32, 0.33, 0.36) if light else Color(0.24, 0.25, 0.28))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


## A top-left text panel; returns the Label to update.
static func add_hud(parent: Node) -> Label:
	var layer := CanvasLayer.new()
	parent.add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 15)
	panel.add_child(label)
	return label


## A centred crosshair dot; returns it so callers can recolour it as a hit marker.
static func add_crosshair(parent: Node) -> ColorRect:
	var layer := CanvasLayer.new()
	parent.add_child(layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(4, 4)
	dot.color = Color(0.2, 1.0, 0.4)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(dot)
	return dot
