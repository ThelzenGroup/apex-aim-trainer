extends TestCase
## The CSV log keeps one well-formed row per frame, with the timing columns filled in.


func test_recording_writes_one_row_per_frame() -> void:
	Telemetry.start_recording("test_telemetry")
	var path := Telemetry.last_log_path
	for i in 10:
		await tree.process_frame
	Telemetry.stop_recording()

	var lines := FileAccess.get_file_as_string(path).strip_edges().split("\n")
	var header := lines[0].split(",")
	check_eq(header[header.size() - 1], "note", "note stays the last column")
	check(header.has("gpu_ms") and header.has("process_ms"), "timing columns present: %s" % [header])
	check(lines.size() >= 9, "about one row per frame, got %d" % lines.size())
	for row in lines.slice(1):
		check_eq(row.split(",").size(), header.size(), "row has every column: " + row)
	var first := lines[1].split(",")
	check(first[header.find("frame_ms")].to_float() > 0.0, "frame time recorded")

	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path.get_basename() + ".json")
