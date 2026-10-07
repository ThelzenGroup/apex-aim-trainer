class_name AimAssist
## Controller aim assist modelled on Apex's two parts: slowdown (look speed drops near a
## target) and rotational assist (the view follows a moving target while the player is
## giving look or move input). Strengths are tuning values, not Apex's exact numbers.
##
## Angles follow the camera's convention: yaw is rotation about +Y (positive turns left),
## pitch is rotation about the camera's +X (positive looks up).


## 1 inside `inner_deg` of the target, fading linearly to 0 at `outer_deg`.
static func falloff(angle_deg: float, inner_deg: float, outer_deg: float) -> float:
	if angle_deg <= inner_deg:
		return 1.0
	if angle_deg >= outer_deg:
		return 0.0
	return 1.0 - (angle_deg - inner_deg) / (outer_deg - inner_deg)


## Look rate after slowdown near a target.
static func slowdown(look_rate: Vector2, falloff_value: float, max_slowdown: float) -> Vector2:
	return look_rate * (1.0 - max_slowdown * falloff_value)


## View rotation in degrees per second that follows the target's angular velocity.
static func rotational(target_angular_velocity: Vector2, falloff_value: float, strength: float) -> Vector2:
	return target_angular_velocity * (strength * falloff_value)


## Angle in degrees between the view direction and the direction to `point`.
static func angle_to(view_origin: Vector3, view_forward: Vector3, point: Vector3) -> float:
	return rad_to_deg(view_forward.angle_to(point - view_origin))


## How fast a target sweeps across the view, in degrees per second (x = yaw, y = pitch),
## given its position and velocity relative to a stationary viewer.
static func angular_velocity(view_origin: Vector3, view_basis: Basis, target: Vector3, target_velocity: Vector3) -> Vector2:
	var r := target - view_origin
	var distance_sq := r.length_squared()
	if distance_sq < 1e-6:
		return Vector2.ZERO
	var omega := r.cross(target_velocity) / distance_sq
	return Vector2(rad_to_deg(omega.dot(Vector3.UP)), rad_to_deg(omega.dot(view_basis.x)))
