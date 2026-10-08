extends TestCase
## Pure math shared by every lab scene: sensitivity, ballistics, recoil, sticks, aim assist.


func test_degrees_per_count_matches_source_yaw() -> void:
	check_near(ApexSensitivity.degrees_per_count(1.0), 0.022, 1e-12)
	check_near(ApexSensitivity.degrees_per_count(2.5, 0.8), 0.022 * 2.5 * 0.8, 1e-12)


func test_cm_per_360() -> void:
	# 360 / 0.022 = 16363.64 counts; at 800 DPI that is 20.45 inches = 51.95 cm.
	check_near(ApexSensitivity.cm_per_360(1.0, 800.0), 51.9545, 1e-3)
	check_near(ApexSensitivity.cm_per_360(2.0, 1600.0), 51.9545 / 4.0, 1e-3)


func test_fov_slider_maps_to_cl_fov_scale() -> void:
	# Slider 110 writes cl_fovScale 1.55, which renders 108.5 degrees.
	check_near(ApexSensitivity.fov_from_slider(110.0), 108.5, 1e-9)
	check_near(ApexSensitivity.fov_from_slider(70.0), 70.0, 1e-9)
	check_near(ApexSensitivity.fov_from_scale(1.55), 108.5, 1e-9)
	check_near(ApexSensitivity.slider_from_scale(1.55), 110.0, 1e-9)


func test_fov_conversion_is_hor_plus() -> void:
	check_near(ApexSensitivity.horizontal_fov(90.0, 4.0 / 3.0), 90.0, 1e-9)
	check_near(ApexSensitivity.horizontal_fov(90.0, 16.0 / 9.0), 106.2602, 1e-3)
	check_near(ApexSensitivity.vertical_fov(90.0), 73.7398, 1e-3)


func test_pillarbox_to_21_9() -> void:
	check_near(ApexSensitivity.pillarbox_width(Vector2(3840, 1080), ApexSensitivity.ASPECT_21_9), 640.0, 1e-3,
		"32:9 at 1080p keeps the middle 2560 pixels")
	check_eq(ApexSensitivity.pillarbox_width(Vector2(2560, 1080), ApexSensitivity.ASPECT_21_9), 0.0, "21:9 needs no bars")
	check_eq(ApexSensitivity.pillarbox_width(Vector2(1920, 1080), ApexSensitivity.ASPECT_21_9), 0.0, "16:9 needs no bars")


func test_player_movement_directions() -> void:
	check_vec_near(PlayerMovement.wish_direction(0.0, Vector2(0, 1)), Vector3(0, 0, -1), 1e-6, "forward looks down -Z")
	check_vec_near(PlayerMovement.wish_direction(0.0, Vector2(1, 0)), Vector3(1, 0, 0), 1e-6, "D strafes right")
	check_vec_near(PlayerMovement.wish_direction(90.0, Vector2(0, 1)), Vector3(-1, 0, 0), 1e-6, "yaw 90 faces left")
	check_near(PlayerMovement.wish_direction(37.0, Vector2(1, 1)).length(), 1.0, 1e-6, "diagonals are no faster")


func test_player_movement_is_frame_rate_independent() -> void:
	# From standing, 28 m/s² reaches 4.41 m/s in 0.1575 s; after 1 s the player has
	# covered 4.41 - 4.41 * 0.1575 / 2 = 4.0627 m.
	for fps in [60.0, 144.0, 500.0]:
		var velocity := Vector3.ZERO
		var position := Vector3.ZERO
		for i in roundi(fps):
			velocity = PlayerMovement.accelerate(velocity, Vector3.RIGHT, 4.41, 28.0, 1.0 / fps)
			position += velocity / fps
		check_near(velocity.x, 4.41, 1e-4, "full walking speed at %d FPS" % fps)
		check_near(position.x, 4.0627, 0.04, "distance after 1 s at %d FPS" % fps)


func test_jump_height_is_frame_rate_independent() -> void:
	# 5.5 m/s up against 18 m/s² peaks at 5.5² / 36 = 0.840 m and lands after 0.611 s.
	for fps in [60.0, 144.0, 500.0]:
		var state := Vector2(0.0, 5.5)
		var peak := 0.0
		var airtime := 0.0
		while true:
			state = PlayerMovement.fall(state.x, state.y, 18.0, 1.0 / fps)
			airtime += 1.0 / fps
			peak = maxf(peak, state.x)
			if state.x <= 0.0:
				break
		check_near(peak, 0.840, 0.01, "jump peak at %d FPS" % fps)
		check_near(airtime, 0.611, 1.5 / fps, "airtime at %d FPS" % fps)
		check_eq(state, Vector2.ZERO, "landing stops the fall")


func test_ballistics_is_tick_rate_independent() -> void:
	var gravity := Vector3(0, -9.81, 0)
	var one := Ballistics.step(Vector3.ZERO, Vector3(0, 0, -500), gravity, 0.2)
	var p := Vector3.ZERO
	var v := Vector3(0, 0, -500)
	for i in 24:
		var s := Ballistics.step(p, v, gravity, 0.2 / 24.0)
		p = s[0]
		v = s[1]
	check_vec_near(p, one[0], 1e-4, "position")
	check_vec_near(v, one[1], 1e-4, "velocity")
	check_near(-one[0].y, Ballistics.drop_at(100.0, 500.0, 9.81), 1e-5, "drop after 100 m")


func test_recoil_pattern() -> void:
	var pattern := RecoilPattern.new(PackedVector2Array([Vector2(0, 1), Vector2(0.5, 0.8), Vector2(-0.2, 0.6)]))
	check_eq(pattern.kick(1), Vector2(0.5, 0.8))
	check_eq(pattern.kick(10), Vector2(-0.2, 0.6), "long sprays repeat the last kick")
	check_vec_near(pattern.offset_after(4), Vector2(0.1, 3.0), 1e-6)


func test_stick_shape() -> void:
	check_eq(StickCurves.shape(Vector2(0.05, 0.0), 0.1, 0.95, 1.0), Vector2.ZERO, "inside deadzone")
	check_near(StickCurves.shape(Vector2(0.0, -1.0), 0.1, 0.95, 2.0).length(), 1.0, 1e-6, "past the outer threshold")
	var half := StickCurves.shape(Vector2(0.525, 0.0), 0.1, 0.95, 2.0)
	check_near(half.x, 0.25, 1e-6, "halfway with exponent 2")


func test_extra_turn_ramp() -> void:
	check_eq(StickCurves.extra_turn_ramp(0.1, 0.2, 0.5), 0.0)
	check_near(StickCurves.extra_turn_ramp(0.45, 0.2, 0.5), 0.5, 1e-9)
	check_eq(StickCurves.extra_turn_ramp(5.0, 0.2, 0.5), 1.0)
	check_near(StickCurves.look_rate(Vector2(1, -0.5), 160, 120, 200, 0, 0.5).x, 260.0, 1e-9)


func test_aim_assist_falloff_and_slowdown() -> void:
	check_eq(AimAssist.falloff(1.0, 2.0, 6.0), 1.0)
	check_near(AimAssist.falloff(4.0, 2.0, 6.0), 0.5, 1e-9)
	check_eq(AimAssist.falloff(7.0, 2.0, 6.0), 0.0)
	check_vec_near(AimAssist.slowdown(Vector2(100, 50), 1.0, 0.4), Vector2(60, 30), 1e-4)


func test_target_angular_velocity() -> void:
	# A target 10 m ahead moving right at 5 m/s sweeps 0.5 rad/s to the right (yaw decreasing).
	var rate := AimAssist.angular_velocity(Vector3.ZERO, Basis.IDENTITY, Vector3(0, 0, -10), Vector3(5, 0, 0))
	check_near(rate.x, -rad_to_deg(0.5), 1e-4, "yaw")
	check_near(rate.y, 0.0, 1e-9, "pitch")
	var rising := AimAssist.angular_velocity(Vector3.ZERO, Basis.IDENTITY, Vector3(0, 0, -10), Vector3(0, 5, 0))
	check_near(rising.y, rad_to_deg(0.5), 1e-4, "a rising target pitches the view up")
