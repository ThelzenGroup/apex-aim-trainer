class_name Ballistics
## Projectile flight under constant gravity, advanced in closed form so the path
## doesn't depend on the physics tick rate.


## Position and velocity after `dt` seconds: [position, velocity].
static func step(position: Vector3, velocity: Vector3, gravity: Vector3, dt: float) -> PackedVector3Array:
	return PackedVector3Array([
		position + velocity * dt + gravity * (0.5 * dt * dt),
		velocity + gravity * dt,
	])


## How far a bullet fired level has dropped after travelling `distance` metres.
static func drop_at(distance: float, speed: float, gravity: float) -> float:
	var t := distance / speed
	return 0.5 * gravity * t * t
