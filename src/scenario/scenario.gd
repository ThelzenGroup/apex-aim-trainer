class_name Scenario
extends Lab
## A training session. Targets appear one at a time near where you are looking and strafe;
## knock each one as fast as you can. Scored on time to knock, accuracy, headshots and
## damage per magazine, and every session is saved so you can compare runs.

const DEFAULT_CONFIG := "res://data/scenarios/close_range_r99.tres"
const COUNTDOWN := 3.0
const NEXT_TARGET_DELAY := 0.5
const REMOVE_KNOCKED_AFTER := 1.5
const SPRAY_RESET := 0.3  ## seconds without firing before recoil starts from the first kick again
const DAMAGE_STACK_TIME := 0.8  ## seconds after the last hit before the damage number fades

enum State { COUNTDOWN, RUNNING, RESULTS }

## Set by the menu before switching to this scene.
static var selected: ScenarioConfig

var config: ScenarioConfig
var state := State.COUNTDOWN
var stats: SessionStats
var look: LookController
var projectiles: Projectiles
var target: Bot
## Holds the trigger without a mouse or controller, for automated tests.
var force_trigger := false

var _weapon: WeaponState
var _recoil: RecoilPattern
var _models := {}
var _rng := RandomNumberGenerator.new()
var _sfx: Sfx
var _marker: HitMarker
var _target_bar: TargetBar
var _center_label: Label
var _ammo_label: Label
var _results: Control
var _results_label: Label
var _clock := 0.0
var _countdown := 0.0
var _spawn_time := 0.0
var _next_spawn_in := 0.0
var _target_hit := false
var _shot := 0
var _since_shot := 0.0
var _damage_label: Label3D
var _damage_total := 0.0
var _damage_left := 0.0


func lab_name() -> String:
	return "scenario_" + config.id


func _ready() -> void:
	config = selected if selected != null else load(DEFAULT_CONFIG)
	super()
	LabWorld.build_range(self)
	look = LookController.new()
	look.position = Vector3(0, 1.6, 0)
	add_child(look)
	projectiles = Projectiles.new()
	projectiles.gravity = Vector3(0, -config.weapon.bullet_gravity, 0)
	add_child(projectiles)
	projectiles.hit.connect(_on_hit)
	_sfx = Sfx.new()
	add_child(_sfx)
	for size: String in config.sizes:
		_models[size] = load("res://assets/models/dummy_%s.glb" % size)
	_build_ui()
	restart()


func restart() -> void:
	if target != null:
		target.queue_free()
		target = null
	projectiles.bots.clear()
	var w := config.weapon
	var magazine := w.magazine(config.magazine_level)
	stats = SessionStats.new(magazine)
	_weapon = WeaponState.new(w.fire_rate(), magazine, w.tactical_reload, w.empty_reload)
	_recoil = RecoilPattern.new(config.weapon.recoil)
	_clock = 0.0
	_countdown = COUNTDOWN
	_next_spawn_in = 0.0
	state = State.COUNTDOWN
	_results.visible = false
	look.face(0.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func skip_countdown() -> void:
	_countdown = 0.0


func _input(event: InputEvent) -> void:
	super(event)
	var button := event as InputEventJoypadButton
	if button and button.pressed and button.button_index == JOY_BUTTON_X:
		_weapon.start_reload()


func _on_key(keycode: Key) -> void:
	match keycode:
		KEY_R:
			_weapon.start_reload()
		KEY_ENTER, KEY_SPACE, KEY_KP_ENTER:
			if state == State.RESULTS:
				restart()


func _process(delta: float) -> void:
	match state:
		State.COUNTDOWN:
			_countdown -= delta
			_center_label.text = str(ceili(_countdown)) if _countdown > 0.0 else ""
			if _countdown <= 0.0:
				state = State.RUNNING
				_spawn_target()
		State.RUNNING:
			_clock += delta
			_update_weapon(delta)
			if target == null:
				_next_spawn_in -= delta
				if _next_spawn_in <= 0.0:
					_spawn_target()
	_fade_damage(delta)
	_update_hud()


func _update_weapon(delta: float) -> void:
	var pads := Input.get_connected_joypads()
	var held := force_trigger \
		or (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) \
		or (not pads.is_empty() and Input.get_joy_axis(pads[0], JOY_AXIS_TRIGGER_RIGHT) > 0.5)
	var shots := _weapon.trigger(held, delta)
	_since_shot += delta
	if shots == 0 and _since_shot > SPRAY_RESET:
		_shot = 0
	for i in shots:
		# Each shot leaves along the view as it is after the previous shot's kick.
		projectiles.fire(look.camera.global_position, -look.camera.global_basis.z * config.weapon.bullet_speed(), true)
		look.kick(_recoil.kick(_shot))
		_shot += 1
		_since_shot = 0.0
	stats.record_shots(shots)


func _spawn_target() -> void:
	var yaw := deg_to_rad(look.yaw + _rng.randf_range(-config.spread_degrees, config.spread_degrees))
	var distance := _rng.randf_range(config.distance_min, config.distance_max)
	var bot := Bot.new()
	bot.strafe_speed = config.strafe_speed
	bot.crouch_speed = config.crouch_speed
	bot.strafe_width = config.strafe_width
	bot.position = Vector3(-sin(yaw), 0.0, -cos(yaw)) * distance
	add_child(bot)
	bot.setup(_models[config.sizes[_rng.randi() % config.sizes.size()]], Vector3.ZERO, _rng.randi())
	bot.set_shield_tier(config.shield_tier)
	target = bot
	projectiles.bots.clear()
	projectiles.bots.append(bot)
	_target_bar.bot = bot
	_spawn_time = _clock
	_target_hit = false
	_damage_left = 0.0
	_damage_label.visible = false


func _on_hit(bot: Bot, shape: DummyHitboxes.Shape, point: Vector3, from_player: bool) -> void:
	if bot != target or not from_player or state != State.RUNNING:
		return
	var shield_color: Color = ApexDamage.SHIELD_COLORS[bot.shield_tier] if bot.shield > 0.0 else Color.WHITE
	var result := bot.take_damage(config.weapon.damage_for(shape.region))
	var dealt: float = result["shield_damage"] + result["health_damage"]
	stats.record_hit(shape.region, dealt)
	if not _target_hit:
		_target_hit = true
		stats.record_first_hit(_clock - _spawn_time)
	_show_damage(point, dealt, shield_color if result["shield_damage"] > 0.0 else Color.WHITE)
	var headshot := shape.region == "head"
	if result["knocked"]:
		_marker.flash(Color(1.0, 0.3, 0.3), 1.6)
		_sfx.play("knock")
		_on_knocked()
	elif result["shield_broken"]:
		_marker.flash(shield_color, 1.4)
		_sfx.play("shield_break")
	else:
		_marker.flash(Color(1.0, 0.3, 0.3) if headshot else Color.WHITE)
		_sfx.play("head" if headshot else "hit")


func _on_knocked() -> void:
	stats.record_knock(_clock - _spawn_time)
	var fallen := target
	get_tree().create_timer(REMOVE_KNOCKED_AFTER).timeout.connect(fallen.queue_free)
	target = null
	projectiles.bots.clear()
	_target_bar.bot = null
	if stats.knock_times.size() >= config.target_count:
		_finish()
	else:
		_next_spawn_in = NEXT_TARGET_DELAY


func _finish() -> void:
	state = State.RESULTS
	stats.duration = _clock
	var summary := stats.summary()
	var sessions := ScenarioHistory.append(config.id, summary)
	_results_label.text = _results_text(summary, sessions)
	_results.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _results_text(summary: Dictionary, sessions: Array) -> String:
	var weapon := config.weapon
	var best := ScenarioHistory.best(sessions, "avg_time_to_knock", config.target_count)
	var lines := PackedStringArray([
		"%s · %d targets · %s shields · %s" % [config.title, config.target_count, config.shield_tier, weapon.display_name],
		"",
		"Average time to knock   %.2f s   (your best %.2f s)" % [summary["avg_time_to_knock"], best],
		"Fastest knock           %.2f s" % summary["best_time_to_knock"],
		"Average time to 1st hit %.2f s" % summary["avg_time_to_first_hit"],
		"Accuracy                %.1f%%" % (summary["accuracy"] * 100.0),
		"Headshots               %.1f%% of hits" % (summary["headshot_rate"] * 100.0),
		"Damage per magazine     %d of %d possible with body shots" % [
			summary["damage_per_magazine"], weapon.body_damage * _weapon.magazine_size],
		"Shots %d · hits %d · session %.1f s" % [summary["shots"], summary["hits"], summary["duration"]],
		"",
		"Recent sessions (time to knock · accuracy):",
	])
	for session: Dictionary in sessions.slice(-5):
		lines.append("  %s   %.2f s · %.0f%%" % [
			str(session.get("date", "")).replace("T", " "), session.get("avg_time_to_knock", 0.0), session.get("accuracy", 0.0) * 100.0])
	lines.append_array(["", "Weapon data: " + weapon.source])
	if not weapon.placeholder_fields.is_empty():
		lines.append(weapon.placeholder_note())
	return "\n".join(lines)


## One number per target that adds up consecutive hits, like Apex's stacking damage
## numbers, coloured by what the last hit damaged (shield tier or white for health).
func _show_damage(point: Vector3, amount: float, color: Color) -> void:
	if _damage_left <= 0.0:
		_damage_total = 0.0
	_damage_total += amount
	_damage_left = DAMAGE_STACK_TIME
	_damage_label.text = str(roundi(_damage_total))
	_damage_label.modulate = color
	# Up and to the right of the hit, so the number never covers the target's head.
	_damage_label.position = point + look.camera.global_basis.x * 0.6 + Vector3(0.0, 0.6, 0.0)
	_damage_label.visible = true


func _fade_damage(delta: float) -> void:
	if _damage_left <= 0.0:
		return
	_damage_left -= delta
	_damage_label.modulate.a = clampf(_damage_left / 0.3, 0.0, 1.0)
	_damage_label.visible = _damage_left > 0.0


func _update_hud() -> void:
	hud.text = "\n".join([
		config.title.to_upper(),
		"Target %d / %d · %.1f s" % [mini(stats.knock_times.size() + 1, config.target_count), config.target_count, _clock],
		"Accuracy %.0f%% · headshots %.0f%%" % [stats.accuracy() * 100.0, stats.headshot_rate() * 100.0],
		"Last knock %.2f s" % stats.knock_times[-1] if not stats.knock_times.is_empty() else "Last knock –",
		"[LMB/R2] fire   [R/X] reload   [Esc] menu",
	])
	_ammo_label.text = "Reloading…" if _weapon.is_reloading() else "%d / %d" % [_weapon.ammo, _weapon.magazine_size]


func _build_ui() -> void:
	_damage_label = Label3D.new()
	_damage_label.font_size = 72
	_damage_label.outline_size = 12
	_damage_label.pixel_size = 0.0011
	_damage_label.fixed_size = true
	_damage_label.no_depth_test = true
	_damage_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_damage_label.visible = false
	add_child(_damage_label)

	var layer := CanvasLayer.new()
	add_child(layer)
	_marker = HitMarker.new()
	layer.add_child(_marker)
	_target_bar = TargetBar.new()
	layer.add_child(_target_bar)

	_center_label = Label.new()
	_center_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_center_label.add_theme_font_size_override("font_size", 96)
	_center_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_center_label)

	_ammo_label = Label.new()
	_ammo_label.add_theme_font_size_override("font_size", 32)
	_ammo_label.anchor_left = 1.0
	_ammo_label.anchor_right = 1.0
	_ammo_label.anchor_top = 1.0
	_ammo_label.anchor_bottom = 1.0
	_ammo_label.offset_left = -220.0
	_ammo_label.offset_right = -32.0
	_ammo_label.offset_top = -72.0
	_ammo_label.offset_bottom = -24.0
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(_ammo_label)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Session complete"
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	_results_label = Label.new()
	_results_label.add_theme_font_size_override("font_size", 17)
	box.add_child(_results_label)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	var again := Button.new()
	again.text = "Go again (Enter)"
	again.pressed.connect(restart)
	buttons.add_child(again)
	var menu := Button.new()
	menu.text = "Menu (Esc)"
	menu.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU))
	buttons.add_child(menu)
	_results = center
