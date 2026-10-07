class_name Projectiles
extends Node3D
## Bullets with travel time and drop.
##
## Each physics tick every bullet advances in closed form and the segment it covered is
## tested against the bots: first a cheap sphere test per bot (inline, since it runs for
## every bullet-bot pair), then the exact hitboxes only for bots the bullet passes near.

signal hit(bot: Bot, shape: DummyHitboxes.Shape, point: Vector3, from_player: bool)

const MAX_TRACERS := 1024

@export var gravity := Vector3(0, -9.81, 0)  ## Placeholder until per-weapon Apex values exist.
@export var max_range := 200.0

var bots: Array[Bot] = []
## Microseconds the last tick spent moving and hit-testing bullets.
var last_tick_usec := 0

var _positions := PackedVector3Array()
var _velocities := PackedVector3Array()
var _travelled := PackedFloat32Array()
var _from_player := PackedByteArray()
var _tracers: MultiMesh


func _ready() -> void:
	var mesh := BoxMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.85, 0.3)
	mesh.material = material
	_tracers = MultiMesh.new()
	_tracers.transform_format = MultiMesh.TRANSFORM_3D
	_tracers.mesh = mesh
	_tracers.instance_count = MAX_TRACERS
	_tracers.visible_instance_count = 0
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _tracers
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func fire(origin: Vector3, velocity: Vector3, from_player: bool) -> void:
	_positions.append(origin)
	_velocities.append(velocity)
	_travelled.append(0.0)
	_from_player.append(1 if from_player else 0)


func live_count() -> int:
	return _positions.size()


func _physics_process(delta: float) -> void:
	var start := Time.get_ticks_usec()
	var centers := PackedVector3Array()
	var radii_sq := PackedFloat32Array()
	for bot in bots:
		bot.hitboxes.update_pose()
		centers.append(bot.hitboxes.bound_center())
		radii_sq.append(bot.hitboxes.bound_radius * bot.hitboxes.bound_radius)

	var i := 0
	while i < _positions.size():
		var from := _positions[i]
		var next := Ballistics.step(from, _velocities[i], gravity, delta)
		var segment := next[0] - from
		var length := segment.length()
		var dir := segment / length
		var best_t := INF
		var best_bot: Bot = null
		var best_shape: DummyHitboxes.Shape = null
		for b in centers.size():
			# Inline ray-sphere broad phase: skip bots the segment can't reach.
			var oc := from - centers[b]
			var along := oc.dot(dir)
			var c := oc.length_squared() - radii_sq[b]
			if c > 0.0 and (along > 0.0 or along * along < c or -along - sqrt(along * along - c) > length):
				continue
			var result := bots[b].hitboxes.intersect(from, dir, length)
			if not result.is_empty() and result["t"] < best_t:
				best_t = result["t"]
				best_bot = bots[b]
				best_shape = result["shape"]
		if best_bot != null:
			hit.emit(best_bot, best_shape, from + dir * best_t, _from_player[i] == 1)
			_remove(i)
			continue
		_positions[i] = next[0]
		_velocities[i] = next[1]
		_travelled[i] += length
		if _travelled[i] > max_range:
			_remove(i)
			continue
		i += 1
	last_tick_usec = Time.get_ticks_usec() - start
	_update_tracers()


func _remove(i: int) -> void:
	var last := _positions.size() - 1
	_positions[i] = _positions[last]
	_velocities[i] = _velocities[last]
	_travelled[i] = _travelled[last]
	_from_player[i] = _from_player[last]
	_positions.resize(last)
	_velocities.resize(last)
	_travelled.resize(last)
	_from_player.resize(last)


func _update_tracers() -> void:
	var count := mini(_positions.size(), MAX_TRACERS)
	for i in count:
		var v := _velocities[i]
		var up := Vector3.UP if absf(v.normalized().y) < 0.99 else Vector3.FORWARD
		var basis := Basis.looking_at(v, up).scaled_local(Vector3(0.02, 0.02, 1.5))
		_tracers.set_instance_transform(i, Transform3D(basis, _positions[i]))
	_tracers.visible_instance_count = count
