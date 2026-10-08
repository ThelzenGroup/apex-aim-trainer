extends TestCase
## Plays a short scenario end to end: aim at each target, hold the trigger, and check that
## bullets travel, hit, knock targets, spawn the next one and finish with saved results.

const HISTORY := "user://test_history"


func _config(target_count: int, shield_tier: String, path := "res://data/scenarios/close_range_r99.tres") -> ScenarioConfig:
	var config: ScenarioConfig = load(path).duplicate()
	config.id = "test_run"
	config.target_count = target_count
	config.shield_tier = shield_tier
	if config.distance_max < 16.0:
		config.distance_min = 8.0
		config.distance_max = 9.0
	return config


## Runs `scenario` with perfect aim until it shows results or `ticks` physics ticks pass.
func _play(scenario: Scenario, ticks: int) -> void:
	scenario.skip_countdown()
	scenario.force_trigger = true
	for i in ticks:
		_aim(scenario)
		await tree.physics_frame
		if scenario.state == Scenario.State.RESULTS:
			return


func _aim(scenario: Scenario) -> void:
	if scenario.target == null:
		return
	var direction := scenario.target.aim_point() - scenario.look.camera.global_position
	var yaw := rad_to_deg(atan2(-direction.x, -direction.z))
	var pitch := rad_to_deg(atan2(direction.y, Vector2(direction.x, direction.z).length()))
	scenario.look.face(yaw, pitch)


func test_full_run_knocks_every_target_and_saves_results() -> void:
	ScenarioHistory.folder = HISTORY
	DirAccess.remove_absolute(ScenarioHistory.path_for("test_run"))
	Scenario.selected = _config(2, "blue")
	var scenario: Scenario = load("res://scenes/scenario.tscn").instantiate()
	tree.root.add_child(scenario)
	scenario.skip_countdown()
	scenario.force_trigger = true
	var shield_broke := false
	for i in 1200:  # 10 s of physics ticks at most
		_aim(scenario)
		await tree.physics_frame
		if scenario.target != null and scenario.target.shield_tier == "blue" and scenario.target.shield <= 0.0:
			shield_broke = true
		if scenario.state == Scenario.State.RESULTS:
			break

	check_eq(scenario.state, Scenario.State.RESULTS, "the run finishes")
	var summary := scenario.stats.summary()
	check_eq(summary["targets"], 2, "both targets knocked")
	check(shield_broke, "a target's blue shield broke before it went down")
	var best_hit := scenario.config.weapon.head_damage
	check(summary["hits"] >= ApexDamage.shots_to_knock(best_hit, 75.0) * 2, "enough hits to knock two blue-shield targets")
	check(summary["damage"] >= 2 * (ApexDamage.HEALTH + 75.0) - 0.01, "damage covers both targets' shields and health")
	check(summary["shots"] >= summary["hits"], "never more hits than shots")
	check(summary["avg_time_to_knock"] > 0.0, "time to knock recorded")
	check_eq(ScenarioHistory.load_sessions("test_run").size(), 1, "the session was saved")

	scenario.queue_free()
	await tree.process_frame
	DirAccess.remove_absolute(ScenarioHistory.path_for("test_run"))
	ScenarioHistory.folder = "user://history"
	Scenario.selected = null


func test_every_menu_scenario_knocks_a_target() -> void:
	ScenarioHistory.folder = HISTORY
	var menu: GDScript = load("res://src/ui/main_menu.gd")
	var paths: Array = menu.get_script_constant_map()["SCENARIOS"]
	var ids := {}
	for path: String in paths:
		var loaded: ScenarioConfig = load(path)
		check(loaded != null and loaded.weapon != null, path + " loads with a weapon")
		if loaded == null or loaded.weapon == null:
			continue
		check(not ids.has(loaded.id), path + " has its own id")
		ids[loaded.id] = true
		check(loaded.distance_min <= loaded.distance_max, path + " distance range")
		DirAccess.remove_absolute(ScenarioHistory.path_for("test_run"))
		Scenario.selected = _config(1, loaded.shield_tier, path)
		var scenario: Scenario = load("res://scenes/scenario.tscn").instantiate()
		tree.root.add_child(scenario)
		await _play(scenario, 1200)
		check_eq(scenario.state, Scenario.State.RESULTS, path + " knocks its target with perfect aim")
		scenario.queue_free()
		await tree.process_frame
	DirAccess.remove_absolute(ScenarioHistory.path_for("test_run"))
	ScenarioHistory.folder = "user://history"
	Scenario.selected = null
