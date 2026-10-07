extends SceneTree
## Headless test runner: runs every tests/test_*.gd and exits non-zero on any failure.
##
##     godot --headless --path . -s tests/run_tests.gd [-- name_filter]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var filter := args[0] if not args.is_empty() else ""
	var files := Array(DirAccess.get_files_at("res://tests")).filter(
		func(f: String) -> bool:
			return f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd" \
				and (filter.is_empty() or f.contains(filter)))
	files.sort()

	var failed := 0
	var passed := 0
	for file: String in files:
		var case: TestCase = load("res://tests/" + file).new()
		case.tree = self
		for method in case.get_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			case.current_test = "%s::%s" % [file.get_basename(), name]
			var before := case.failures.size()
			await case.call(name)
			if case.failures.size() == before:
				passed += 1
			else:
				failed += 1
		for failure in case.failures:
			printerr("FAIL ", failure)

	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
