class_name PlayerMotor
extends RefCounted
## Moves the player's view the way Apex does while shooting: walk and strafe with WASD or
## the left stick, crouch with Ctrl or C (B or Circle on a controller), and jump with Space
## (A or Cross). Sprinting and sliding are left out, since Apex doesn't fire while sprinting.
##
## Keys are read by physical position, so WASD stays in place on any keyboard layout.
## Call update() once per frame, before anything that reads the camera position.

const STAND_EYE := 1.6  ## metres above the floor; placeholder
const CROUCH_EYE := 1.0  ## placeholder
const CROUCH_TIME := 0.15  ## seconds to crouch or stand up; placeholder
const AIR_CONTROL := 0.2  ## share of the ground acceleration available in the air; placeholder
const BOUNDS := 180.0  ## metres from the centre of the range floor

var look: LookController
var walk_speed := 4.41  ## m/s; see ScenarioConfig
var crouch_speed := 2.04
var acceleration := 28.0  ## m/s², placeholder (the bots use the same)
var gravity := 18.0  ## m/s², placeholder
var jump_speed := 5.5  ## m/s, placeholder
var enabled := true
var velocity := Vector3.ZERO  ## horizontal
var crouched := false

var _height := 0.0  ## of the feet above the floor
var _vertical_speed := 0.0
var _eye := STAND_EYE
var _jump_was_held := false


func _init(p_look: LookController) -> void:
	look = p_look


func on_ground() -> bool:
	return _height <= 0.0


func update(delta: float) -> void:
	var input := _move_input() if enabled else Vector2.ZERO
	crouched = enabled and _crouch_held()
	var jump_held := enabled and _jump_held()
	if jump_held and not _jump_was_held and on_ground():
		_vertical_speed = jump_speed
	_jump_was_held = jump_held

	var wish := PlayerMovement.wish_direction(look.yaw, input)
	var speed := crouch_speed if crouched else walk_speed
	var accel := acceleration if on_ground() else acceleration * AIR_CONTROL
	velocity = PlayerMovement.accelerate(velocity, wish, speed, accel, delta)
	var fallen := PlayerMovement.fall(_height, _vertical_speed, gravity, delta)
	_height = fallen.x
	_vertical_speed = fallen.y
	_eye = move_toward(_eye, CROUCH_EYE if crouched else STAND_EYE, (STAND_EYE - CROUCH_EYE) / CROUCH_TIME * delta)

	var flat := Vector2(look.position.x, look.position.z) + Vector2(velocity.x, velocity.z) * delta
	flat = flat.clamp(Vector2(-BOUNDS, -BOUNDS), Vector2(BOUNDS, BOUNDS))
	look.position = Vector3(flat.x, _height + _eye, flat.y)


## Puts the player back on the floor at `point`, standing still.
func reset(point: Vector3) -> void:
	velocity = Vector3.ZERO
	_height = 0.0
	_vertical_speed = 0.0
	_eye = STAND_EYE
	_jump_was_held = true  # a Space still held from the results screen doesn't jump
	look.position = Vector3(point.x, STAND_EYE, point.z)


## Feet position on the floor below the player.
func floor_position() -> Vector3:
	return Vector3(look.position.x, 0.0, look.position.z)


## x = right, y = forward.
func _move_input() -> Vector2:
	var keys := Vector2(
		_key(KEY_D) - _key(KEY_A),
		_key(KEY_W) - _key(KEY_S))
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return keys
	var raw := Vector2(Input.get_joy_axis(pads[0], JOY_AXIS_LEFT_X), -Input.get_joy_axis(pads[0], JOY_AXIS_LEFT_Y))
	var stick := StickCurves.shape(raw, Settings.stick_deadzone, Settings.stick_outer, 1.0)
	return (keys + stick).limit_length(1.0)


func _crouch_held() -> bool:
	return Input.is_physical_key_pressed(KEY_CTRL) or Input.is_physical_key_pressed(KEY_C) \
		or _pad_button(JOY_BUTTON_B)


func _jump_held() -> bool:
	return Input.is_physical_key_pressed(KEY_SPACE) or _pad_button(JOY_BUTTON_A)


func _key(keycode: Key) -> float:
	return 1.0 if Input.is_physical_key_pressed(keycode) else 0.0


func _pad_button(button: JoyButton) -> bool:
	var pads := Input.get_connected_joypads()
	return not pads.is_empty() and Input.is_joy_button_pressed(pads[0], button)
