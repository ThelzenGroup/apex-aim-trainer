class_name Bot
extends Node3D
## An ADAD-strafing target dummy that faces the player, with Apex health and shields.
##
## The movement is a stand-in for Apex movement: it flips strafe direction at random
## intervals, accelerates like a player, and sometimes crouch-spams or jumps. Speeds are
## placeholders until they are measured from Apex footage.

signal knocked_down

const LOOPING_CLIPS := ["Idle", "Jog", "Sprint", "Strafe_Left", "Strafe_Right", "Crouch_Idle",
	"Crouch_Fwd", "Crouch_Strafe_Left", "Crouch_Strafe_Right", "Jump", "Slide"]
const BLEND := 0.12

@export var strafe_speed := 4.2  ## m/s
@export var crouch_speed := 2.0
@export var acceleration := 28.0  ## m/s²
@export var strafe_width := 3.0  ## How far the bot may drift from its spawn point, in metres.
@export var gravity := 18.0
@export var jump_speed := 5.5

var velocity := Vector3.ZERO
var hitboxes: DummyHitboxes
var hits := {"head": 0, "body": 0, "limb": 0}
var shield_tier := "none"
var max_shield := 0.0
var shield := 0.0
var health := ApexDamage.HEALTH
var knocked := false

var _model: Node3D
var _animations: AnimationPlayer
var _chest_bone: int
var _home: Vector3
var _direction := 1.0
var _switch_in := 0.0
var _crouch_left := 0.0
var _vertical_speed := 0.0
var _rng := RandomNumberGenerator.new()


## Call after the bot is in the scene tree, at its spawn position.
func setup(model: PackedScene, look_at_point: Vector3, seed_value: int) -> void:
	assert(is_inside_tree(), "add the bot to the tree before setup()")
	_model = model.instantiate()
	add_child(_model)
	_animations = _model.find_children("*", "AnimationPlayer", true, false)[0]
	for clip: String in LOOPING_CLIPS:
		if _animations.has_animation(clip):
			_animations.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	hitboxes = DummyHitboxes.new(_model)
	_chest_bone = hitboxes.skeleton.find_bone("spine_03")
	_rng.seed = seed_value
	_direction = 1.0 if _rng.randf() < 0.5 else -1.0
	_home = position
	look_at(Vector3(look_at_point.x, position.y, look_at_point.z), Vector3.UP, true)
	add_to_group(LookController.TARGET_GROUP)


## Where aim assist aims: the chest.
func aim_point() -> Vector3:
	return hitboxes.skeleton.global_transform * hitboxes.skeleton.get_bone_global_pose(_chest_bone).origin


func register_hit(region: String) -> void:
	hits[region] += 1


func set_shield_tier(tier: String) -> void:
	shield_tier = tier
	max_shield = ApexDamage.SHIELDS[tier]
	shield = max_shield
	health = ApexDamage.HEALTH


## Applies a hit. Returns the shield and health damage dealt and whether the shield broke
## or the bot went down.
func take_damage(amount: float) -> Dictionary:
	if knocked:
		return {"shield_damage": 0.0, "health_damage": 0.0, "shield_broken": false, "knocked": false}
	var after := ApexDamage.apply(shield, health, amount)
	var result := {
		"shield_damage": shield - after.x,
		"health_damage": health - after.y,
		"shield_broken": shield > 0.0 and after.x <= 0.0,
		"knocked": after.y <= 0.0,
	}
	shield = after.x
	health = after.y
	if result["knocked"]:
		_knock()
	return result


func _knock() -> void:
	knocked = true
	velocity = Vector3.ZERO
	position.y = _home.y
	remove_from_group(LookController.TARGET_GROUP)
	_animations.play("Knocked", BLEND)
	knocked_down.emit()


func _process(delta: float) -> void:
	if knocked:
		return
	_think(delta)
	var right := -global_basis.x  # the model faces +Z, so its right is -X
	var speed := crouch_speed if _crouch_left > 0.0 else strafe_speed
	var flat := Vector3(velocity.x, 0.0, velocity.z).move_toward(right * (_direction * speed), acceleration * delta)
	velocity = Vector3(flat.x, _vertical_speed, flat.z)
	position += velocity * delta
	if position.y > _home.y or _vertical_speed > 0.0:
		_vertical_speed -= gravity * delta
	if position.y <= _home.y and _vertical_speed <= 0.0:
		position.y = _home.y
		_vertical_speed = 0.0
	_animate(flat.dot(right))


func _think(delta: float) -> void:
	_switch_in -= delta
	_crouch_left -= delta
	var offset := (position - _home).dot(-global_basis.x)
	if absf(offset) > strafe_width:
		_direction = -signf(offset)
	elif _switch_in <= 0.0:
		_direction = -_direction
		_switch_in = _rng.randf_range(0.2, 0.8)
		if _rng.randf() < 0.25:
			_crouch_left = _rng.randf_range(0.15, 0.4)
		elif _rng.randf() < 0.1 and position.y <= _home.y:
			_vertical_speed = jump_speed


func _animate(lateral_speed: float) -> void:
	var moving := absf(lateral_speed) > 0.5
	var side := "Right" if lateral_speed > 0.0 else "Left"
	var clip: String
	if position.y > _home.y + 0.05:
		clip = "Jump"
	elif _crouch_left > 0.0:
		clip = "Crouch_Strafe_" + side if moving else "Crouch_Idle"
	else:
		clip = "Strafe_" + side if moving else "Idle"
	if _animations.current_animation != clip:
		_animations.play(clip, BLEND)
