extends TestCase
## The CSV log keeps one well-formed row per frame, with the timing columns filled in.


## Burns 2 ms of CPU every frame, so the log has a known amount of script time to find.
class _Busy:
	extends Node

	func _process(_delta: float) -> void:
		var until := Time.get_ticks_usec() + 2000
		while Time.get_ticks_usec() < until:
			pass


func test_recording_writes_one_row_per_frame() -> void:
	var busy := _Busy.new()
	tree.root.add_child(busy)
	await tree.process_frame
	Telemetry.start_recording("test_telemetry")
	var path := Telemetry.last_log_path
	for i in 10:
		await tree.process_frame
	Telemetry.stop_recording()
	busy.queue_free()

	var lines := FileAccess.get_file_as_string(path).strip_edges().split("\n")
	var header := lines[0].split(",")
	check_eq(header[header.size() - 1], "note", "note stays the last column")
	check(header.has("gpu_ms") and header.has("process_ms"), "timing columns present: %s" % [header])
	check(lines.size() >= 9, "about one row per frame, got %d" % lines.size())
	for row in lines.slice(1):
		check_eq(row.split(",").size(), header.size(), "row has every column: " + row)
	var first := lines[1].split(",")
	check(first[header.find("frame_ms")].to_float() > 0.0, "frame time recorded")
	# Script time is per frame, so it always fits inside the frame it belongs to.
	for row in lines.slice(2):
		var cells := row.split(",")
		var work := cells[header.find("process_ms")].to_float() + cells[header.find("physics_ms")].to_float()
		check(work <= cells[header.find("frame_ms")].to_float() + 0.01, "script time fits in its frame: " + row)
		check(cells[header.find("process_ms")].to_float() >= 1.9, "the busy script's 2 ms shows up in its frame: " + row)

	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path.get_basename() + ".json")
