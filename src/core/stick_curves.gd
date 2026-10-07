class_name StickCurves
## Controller stick shaping in the style of Apex's look controls. The structure follows
## Apex's Advanced Look Controls (deadzone, outer threshold, response curve, yaw/pitch
## speed, extra turn speed with ramp-up); the exact Apex formulas are not public, so
## values are tuned by feel against the real game.


## Radial deadzone, outer threshold and power curve. Returns a vector of length 0..1.
static func shape(raw: Vector2, deadzone: float, outer_threshold: float, exponent: float) -> Vector2:
	var length := raw.length()
	if length <= deadzone:
		return Vector2.ZERO
	var t := clampf((length - deadzone) / (outer_threshold - deadzone), 0.0, 1.0)
	return raw / length * pow(t, exponent)


## How much of the extra turn speed applies: 0 until the stick has been at full deflection
## for `delay` seconds, then rising linearly to 1 over `ramp_time`.
static func extra_turn_ramp(time_at_full: float, delay: float, ramp_time: float) -> float:
	if time_at_full <= delay:
		return 0.0
	if ramp_time <= 0.0:
		return 1.0
	return clampf((time_at_full - delay) / ramp_time, 0.0, 1.0)


## Look velocity in degrees per second (x = yaw, y = pitch) for a shaped stick vector.
static func look_rate(shaped: Vector2, yaw_speed: float, pitch_speed: float,
		extra_yaw: float, extra_pitch: float, ramp: float) -> Vector2:
	return Vector2(shaped.x * (yaw_speed + extra_yaw * ramp), shaped.y * (pitch_speed + extra_pitch * ramp))
