extends TestCase
## Test 1 of the first-week plan: every dummy imports with its clips and all hitboxes
## matching the art pipeline's JSON sidecar, and the analytic hitboxes line up with the
## nodes Godot attaches to the bones.

const SIZES := ["small", "medium", "large"]


func _sidecar(size: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/dummy_%s.hitboxes.json" % size))


func _dummy(size: String) -> Node3D:
	return load("res://assets/models/dummy_%s.glb" % size).instantiate()


func test_hitboxes_match_sidecar() -> void:
	for size in SIZES:
		var sidecar := _sidecar(size)
		var root := _dummy(size)
		var nodes := {}
		for node in root.find_children("HB_*", "MeshInstance3D", true, false):
			nodes[node.name] = node
		check_eq(nodes.size(), sidecar["hitboxes"].size(), "%s hitbox count" % size)
		for hb: Dictionary in sidecar["hitboxes"]:
			var node: MeshInstance3D = nodes.get(hb["name"])
			if node == null:
				check(false, "%s: %s was not imported" % [size, hb["name"]])
				continue
			var label: String = "%s %s" % [size, hb["name"]]
			var extras: Dictionary = node.get_meta("extras", {})
			check_eq(extras.get("hitbox_region"), hb["region"], label + " region")
			check_eq(extras.get("hitbox_shape"), hb["shape"], label + " shape")
			for key in ["radius", "height", "size"]:
				if hb.has(key):
					check_eq(extras.get(key), hb[key], "%s %s" % [label, key])
			var attachment := node.get_parent() as BoneAttachment3D
			check(attachment != null and attachment.bone_name == hb["bone"], label + " is attached to " + hb["bone"])
			var t: Array = hb["translation"]
			var r: Array = hb["rotation"]
			check_vec_near(node.position, Vector3(t[0], t[1], t[2]), 1e-5, label + " offset")
			check(node.quaternion.angle_to(Quaternion(r[0], r[1], r[2], r[3])) < 1e-4, label + " rotation")
		root.free()


func test_clips_import_with_godot_names() -> void:
	# Godot's importer strips a trailing "_Loop" from clip names (and loops those clips).
	for size in SIZES:
		var expected := PackedStringArray()
		for clip: String in _sidecar(size)["animations"]:
			expected.append(clip.trim_suffix("_Loop"))
		expected.sort()
		var root := _dummy(size)
		var player: AnimationPlayer = root.find_children("*", "AnimationPlayer", true, false)[0]
		var actual := player.get_animation_list()
		actual.sort()
		check_eq(actual, expected, size + " clips")
		root.free()


func test_analytic_hitboxes_follow_the_animation() -> void:
	# `root` gets DummyHitboxes (which removes the importer's bone attachments); `twin` keeps
	# them, so Godot's own attachment transforms are the reference.
	var root := _dummy("medium")
	var twin := _dummy("medium")
	for node: Node3D in [root, twin]:
		tree.root.add_child(node)
		node.position = Vector3(3, 0, -7)
		node.rotation.y = 0.6
		var player: AnimationPlayer = node.find_children("*", "AnimationPlayer", true, false)[0]
		player.play("Crouch_Strafe_Left")
		player.seek(0.37, true)
	var hitboxes := DummyHitboxes.new(root)
	check_eq(hitboxes.shapes.size(), 17, "hitbox count")
	check(root.find_children("*", "BoneAttachment3D", true, false).is_empty(), "the importer's attachments are removed")
	var reference := {}
	for mesh in twin.find_children("HB_*", "MeshInstance3D", true, false):
		reference[mesh.name] = mesh
	await tree.process_frame
	await tree.process_frame
	for i in hitboxes.shapes.size():
		var expected: Transform3D = reference[hitboxes.shapes[i].name].global_transform
		var actual := hitboxes.shape_transform(hitboxes.shapes[i])
		check_vec_near(actual.origin, expected.origin, 1e-4, hitboxes.shapes[i].name + " position")
		check(actual.basis.get_rotation_quaternion().angle_to(expected.basis.get_rotation_quaternion()) < 1e-3,
			hitboxes.shapes[i].name + " rotation")

	# A ray from 10 m in front of the head centre must hit the head first.
	hitboxes.update_pose()
	var head: DummyHitboxes.Shape = hitboxes.shapes.filter(func(s: DummyHitboxes.Shape) -> bool: return s.region == "head")[0]
	var head_center := hitboxes.shape_transform(head).origin
	var from := head_center + root.global_basis.z * 10.0
	var hit := hitboxes.intersect(from, (head_center - from).normalized(), 20.0)
	check(not hit.is_empty() and hit["shape"] == head, "head shot registers as head, got %s" % [hit])
	check(hitboxes.intersect(from + Vector3(0, 3, 0), (head_center - from).normalized(), 20.0).is_empty(),
		"a ray 3 m over the head misses")

	# The debug view follows the same math.
	hitboxes.set_debug_visible(true)
	check_vec_near(hitboxes.meshes[0].global_position, hitboxes.shape_transform(hitboxes.shapes[0]).origin, 1e-4, "debug mesh placed")
	root.queue_free()
	twin.queue_free()
