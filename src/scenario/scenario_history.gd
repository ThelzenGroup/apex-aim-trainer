class_name ScenarioHistory
## Session summaries per scenario, kept in user://history/<scenario id>.json so results
## can be compared over time.

## Tests point this somewhere else so they don't touch real history.
static var folder := "user://history"


static func path_for(scenario_id: String) -> String:
	return folder.path_join(scenario_id + ".json")


static func load_sessions(scenario_id: String) -> Array:
	var path := path_for(scenario_id)
	if not FileAccess.file_exists(path):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Array else []


## Adds a session (stamped with the date) and returns every session including it.
static func append(scenario_id: String, summary: Dictionary) -> Array:
	var sessions := load_sessions(scenario_id)
	var entry := summary.duplicate()
	entry["date"] = Time.get_datetime_string_from_system()
	sessions.append(entry)
	DirAccess.make_dir_recursive_absolute(folder)
	var file := FileAccess.open(path_for(scenario_id), FileAccess.WRITE)
	file.store_string(JSON.stringify(sessions, "  "))
	return sessions


## The lowest value of `key` among sessions with at least `min_targets` targets, or 0.
static func best(sessions: Array, key: String, min_targets: int) -> float:
	var values := []
	for session: Dictionary in sessions:
		if session.get("targets", 0) >= min_targets and session.get(key, 0.0) > 0.0:
			values.append(session[key])
	return values.min() if not values.is_empty() else 0.0
