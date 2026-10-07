extends TestCase
## Opens every scene and runs it for a few frames. Script errors don't stop Godot, so
## tools/run_tests.sh also fails the run if any were printed.

const SCENES := [
	"res://scenes/main_menu.tscn",
	"res://scenes/lab/mouse_lab.tscn",
	"res://scenes/lab/latency_lab.tscn",
	"res://scenes/lab/load_lab.tscn",
	"res://scenes/lab/controller_lab.tscn",
]


func test_every_scene_runs() -> void:
	for path: String in SCENES:
		var scene: PackedScene = load(path)
		check(scene != null, path + " loads")
		if scene == null:
			continue
		var node := scene.instantiate()
		tree.root.add_child(node)
		for i in 10:
			await tree.physics_frame
			await tree.process_frame
		node.queue_free()
		await tree.process_frame


func test_load_lab_hits_bots() -> void:
	var lab: Node = load("res://scenes/lab/load_lab.tscn").instantiate()
	tree.root.add_child(lab)
	# The emitter starts at 500 bullets/s; after half a second of ticks some must have hit.
	for i in 60:
		await tree.physics_frame
	var total := 0
	for bot: Bot in lab.bots:
		total += bot.hits["head"] + bot.hits["body"] + bot.hits["limb"]
	check_eq(lab.bots.size(), 30, "bots spawned")
	check(total > 0, "emitter bullets hit bots (%d hits)" % total)
	lab.queue_free()
	await tree.process_frame
