class_name PlayerMovement
## First-person movement on flat ground. Velocity eases toward the wished velocity at a
## fixed acceleration, and a diagonal is no faster than a straight line, as in Apex.


## World direction for a move input (x = right, y = forward) when facing `yaw_degrees`
## (0 looks down -Z; positive turns left, as LookController.yaw does).
static func wish_direction(yaw_degrees: float, input: Vector2) -> Vector3:
	var yaw := deg_to_rad(yaw_degrees)
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	return (right * input.x + forward * input.y).limit_length(1.0)


## Horizontal velocity after `delta` seconds of accelerating toward `wish * speed`.
static func accelerate(velocity: Vector3, wish: Vector3, speed: float, acceleration: float, delta: float) -> Vector3:
	return velocity.move_toward(wish * speed, acceleration * delta)


## Height above the floor and vertical speed after `delta` seconds of falling. Landing
## stops the fall.
static func fall(height: float, vertical_speed: float, gravity: float, delta: float) -> Vector2:
	# Exact for constant gravity, so a jump peaks at the same height at any frame rate.
	var new_height := height + vertical_speed * delta - 0.5 * gravity * delta * delta
	var new_speed := vertical_speed - gravity * delta
	if new_height <= 0.0:
		return Vector2.ZERO
	return Vector2(new_height, new_speed)
