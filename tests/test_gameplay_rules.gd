extends TestCase
## Health and shields, weapon timing, and session scoring.


func test_shields_absorb_then_overflow_into_health() -> void:
	check_vec_near(ApexDamage.apply(100.0, 100.0, 30.0), Vector2(70, 100), 1e-6)
	check_vec_near(ApexDamage.apply(10.0, 100.0, 30.0), Vector2(0, 80), 1e-6, "the rest of a breaking shot hits health")
	check_vec_near(ApexDamage.apply(0.0, 15.0, 30.0), Vector2(0, 0), 1e-6, "health stops at zero")


func test_multipliers_and_shots_to_knock() -> void:
	check_eq(ApexDamage.multiplier("head", 1.75, 0.8), 1.75)
	check_eq(ApexDamage.multiplier("limb", 1.75, 0.8), 0.8)
	check_eq(ApexDamage.multiplier("body", 1.75, 0.8), 1.0)
	check_eq(ApexDamage.shots_to_knock(14.0, ApexDamage.SHIELDS["purple"]), 15, "200 effective health at 14 per shot")
	check_eq(ApexDamage.shots_to_knock(20.0, ApexDamage.SHIELDS["none"]), 5)


func test_fire_rate_is_frame_rate_independent() -> void:
	for fps in [60.0, 144.0, 500.0]:
		var weapon := WeaponState.new(10.0, 100, 2.0)
		var shots := 0
		for i in roundi(0.95 * fps):
			shots += weapon.trigger(true, 1.0 / fps)
		check_eq(shots, 10, "10 shots in 0.95 s at 10 rounds/s and %d FPS" % fps)


func test_slow_frames_still_fire_at_the_full_rate() -> void:
	var weapon := WeaponState.new(10.0, 100, 2.0)
	var shots := 0
	for i in 10:
		shots += weapon.trigger(true, 0.237)  # about 4 FPS for 2.37 s: shots at 0.0 ... 2.3 s
	check_eq(shots, 24)


func test_magazine_and_reload() -> void:
	var weapon := WeaponState.new(20.0, 5, 1.0)
	var shots := 0
	for i in 100:
		shots += weapon.trigger(true, 0.01)
		if weapon.ammo == 0:
			break
	check_eq(shots, 5, "the magazine runs dry")
	check(not weapon.is_reloading(), "no reload until you fire on empty")
	check_eq(weapon.trigger(true, 0.01), 0, "an empty magazine doesn't fire")
	check(weapon.is_reloading(), "firing on empty starts a reload")
	weapon.trigger(false, 0.99)
	check(weapon.is_reloading(), "still reloading just before the reload time")
	weapon.trigger(false, 0.02)
	check_eq(weapon.ammo, 5, "full after the reload time")
	check_eq(weapon.trigger(true, 0.01), 1, "fires again straight after reloading")


func test_session_stats() -> void:
	var stats := SessionStats.new(20)
	stats.record_shots(40)
	stats.record_hit("head", 24.5)
	stats.record_hit("body", 14.0)
	stats.record_hit("body", 14.0)
	stats.record_hit("limb", 11.2)
	stats.record_knock(2.0)
	stats.record_knock(3.0)
	check_near(stats.accuracy(), 0.1, 1e-9)
	check_near(stats.headshot_rate(), 0.25, 1e-9)
	check_near(stats.damage_per_magazine(), 63.7 * 20 / 40, 1e-6)
	var summary := stats.summary()
	check_near(summary["avg_time_to_knock"], 2.5, 1e-6)
	check_near(summary["best_time_to_knock"], 2.0, 1e-6)
	check_eq(summary["targets"], 2)
	check_eq(SessionStats.new(20).summary()["accuracy"], 0.0, "no shots means no division by zero")
