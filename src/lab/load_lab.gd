extends Lab
## Test 6: bot and projectile load.
##
## Dozens of ADAD-strafing dummies in all three sizes, an automatic emitter spraying
## bullets into them, analytic hit tests on every bullet, and aim-assist target selection
## every frame. You can also shoot with the left mouse button (or R2) to get a first feel
## for projectile travel and drop. Weapon numbers are placeholders, not Apex data.

const SIZES := ["small", "medium", "large"]
const EMITTER_RATES := [0, 15, 100, 500]
const BULLET_SPEED := 600.0  ## m/s, placeholder
const FIRE_RATE := 13.5  ## shots per second, placeholder
const RECOIL := [Vector2(0.0, 0.45), Vector2(0.1, 0.4), Vector2(-0.12, 0.35), Vector2(0.15, 0.3), Vector2(-0.1, 0.25)]
const REGION_COLORS := {"head": Color(1.0, 0.2, 0.2), "body": Color(1.0, 1.0, 1.0), "limb": Color(0.3, 0.6, 1.0)}
const CROSSHAIR := Color(0.2, 1.0, 0.4)

var look: LookController
var projectiles: Projectiles
var bots: Array[Bot] = []
var bot_count := 30

var _models: Array[PackedScene] = []
var _recoil := RecoilPattern.new(PackedVector2Array(RECOIL))
var _rng := RandomNumberGenerator.new()
var _emitter_index := EMITTER_RATES.size() - 1
var _emit_carry := 0.0
var _weapon := WeaponState.new(FIRE_RATE, 1_000_000, 0.0)
var _shot := 0
var _since_shot := 0.0
var _crosshair: ColorRect
var _marker_left := 0.0
var _your_hits := {"head": 0, "body": 0, "limb": 0}
var _show_hitboxes := false
var _tick_max_usec := 0
var _tick_max_shown := 0
var _tick_window_start := 0


func lab_name() -> String:
	return "load"


func _ready() -> void:
	super()
	LabWorld.build_range(self)
	look = LookController.new()
	look.position = Vector3(0, 1.6, 0)
	add_child(look)
	projectiles = Projectiles.new()
	add_child(projectiles)
	projectiles.hit.connect(_on_hit)
	_crosshair = LabWorld.add_crosshair(self)
	for size: String in SIZES:
		_models.append(load("res://assets/models/dummy_%s.glb" % size))
	_spawn_bots()


func _spawn_bots() -> void:
	for bot in bots:
		bot.queue_free()
	bots.clear()
	for i in bot_count:
		var distance := 15.0 + (i / 10) * 12.0
		var angle := deg_to_rad(((i % 10) - 4.5) * 7.0)
		var bot := Bot.new()
		bot.position = Vector3(sin(angle) * distance, 0.0, -cos(angle) * distance)
		add_child(bot)
		bot.setup(_models[i % _models.size()], Vector3.ZERO, i)
		bot.hitboxes.set_debug_visible(_show_hitboxes)
		bots.append(bot)
	projectiles.bots = bots


func _on_hit(bot: Bot, shape: DummyHitboxes.Shape, _point: Vector3, from_player: bool) -> void:
	bot.register_hit(shape.region)
	if from_player:
		_your_hits[shape.region] += 1
		_crosshair.color = REGION_COLORS[shape.region]
		_marker_left = 0.08


func _on_key(keycode: Key) -> void:
	match keycode:
		KEY_P:
			_emitter_index = (_emitter_index + 1) % EMITTER_RATES.size()
		KEY_H:
			_show_hitboxes = not _show_hitboxes
			for bot in bots:
				bot.hitboxes.set_debug_visible(_show_hitboxes)
		KEY_BRACKETLEFT:
			bot_count = maxi(0, bot_count - 10)
			_spawn_bots()
		KEY_BRACKETRIGHT:
			bot_count = mini(100, bot_count + 10)
			_spawn_bots()


func _physics_process(delta: float) -> void:
	# The emitter spreads bullets over random bots to load the hit tests.
	_emit_carry += EMITTER_RATES[_emitter_index] * delta
	var origin := look.camera.global_position + Vector3(0, -0.4, 0)
	while _emit_carry >= 1.0:
		_emit_carry -= 1.0
		if bots.is_empty():
			continue
		var target := bots[_rng.randi() % bots.size()].aim_point() + Vector3(
			_rng.randf_range(-0.5, 0.5), _rng.randf_range(-0.8, 0.5), _rng.randf_range(-0.5, 0.5))
		projectiles.fire(origin, (target - origin).normalized() * BULLET_SPEED, false)


func _process(delta: float) -> void:
	_fire(delta)
	_marker_left -= delta
	if _marker_left <= 0.0:
		_crosshair.color = CROSSHAIR

	_tick_max_usec = maxi(_tick_max_usec, projectiles.last_tick_usec)
	var now := Time.get_ticks_usec()
	if now - _tick_window_start > 1_000_000:
		_tick_max_shown = _tick_max_usec
		_tick_max_usec = 0
		_tick_window_start = now
	Telemetry.note = str(projectiles.live_count())

	var assist := "none in range"
	if not look.assist_info.is_empty():
		assist = "%.1f° off, strength %.2f" % [look.assist_info["angle"], look.assist_info["falloff"]]
	hud.text = "\n".join([
		"BOT LOAD · test 6",
		"Bots %d   live bullets %d   emitter %d/s" % [bots.size(), projectiles.live_count(), EMITTER_RATES[_emitter_index]],
		"Bullet hit tests: %.2f ms last tick, %.2f ms worst in the last second (%d ticks/s)" % [
			projectiles.last_tick_usec / 1000.0, _tick_max_shown / 1000.0, Engine.physics_ticks_per_second],
		"Your hits: head %d · body %d · limb %d" % [_your_hits["head"], _your_hits["body"], _your_hits["limb"]],
		"Aim-assist target: %s" % assist,
		Telemetry.stats_line(),
		recording_line(),
		"",
		"[LMB/R2] fire   [P] emitter rate   [ and ] bots −/+10   [H] hitboxes   [Esc] menu",
	])


func _fire(delta: float) -> void:
	_since_shot += delta
	var pads := Input.get_connected_joypads()
	var trigger := not pads.is_empty() and Input.get_joy_axis(pads[0], JOY_AXIS_TRIGGER_RIGHT) > 0.5
	var mouse := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var shots := _weapon.trigger(mouse or trigger, delta)
	if shots == 0 and _since_shot > 0.3:
		_shot = 0
	for i in shots:
		projectiles.fire(look.camera.global_position, -look.camera.global_basis.z * BULLET_SPEED, true)
		look.kick(_recoil.kick(_shot))
		_shot += 1
		_since_shot = 0.0
