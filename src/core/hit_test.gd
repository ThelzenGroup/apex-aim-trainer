class_name HitTest
## Ray intersection with hitbox shapes, as plain math so hit detection runs at any time
## (not only inside the physics step) and boxes keep sharp corners.
##
## `dir` must be normalized. Every function returns the distance along `dir` to the first
## hit (0 if the origin is already inside), or INF on a miss.


static func ray_sphere(origin: Vector3, dir: Vector3, center: Vector3, radius: float) -> float:
	var oc := origin - center
	var b := oc.dot(dir)
	var c := oc.length_squared() - radius * radius
	if c <= 0.0:
		return 0.0
	if b > 0.0:
		return INF
	var disc := b * b - c
	if disc < 0.0:
		return INF
	return -b - sqrt(disc)


## Capsule = every point within `radius` of the segment a-b.
static func ray_capsule(origin: Vector3, dir: Vector3, a: Vector3, b: Vector3, radius: float) -> float:
	var ba := b - a
	var oa := origin - a
	var baba := ba.dot(ba)
	if baba < 1e-12:
		return ray_sphere(origin, dir, a, radius)
	var bard := ba.dot(dir)
	var baoa := ba.dot(oa)
	if (oa - ba * clampf(baoa / baba, 0.0, 1.0)).length_squared() <= radius * radius:
		return 0.0
	var k := baba - bard * bard
	if k > 1e-9 * baba:
		# Side of the cylinder.
		var half_b := baba * dir.dot(oa) - baoa * bard
		var c := baba * oa.dot(oa) - baoa * baoa - radius * radius * baba
		var h := half_b * half_b - k * c
		if h < 0.0:
			return INF
		var t := (-half_b - sqrt(h)) / k
		var y := baoa + t * bard
		if y > 0.0 and y < baba:
			return t if t >= 0.0 else INF
	# End caps: the ray meets the cylinder beyond an end, or runs parallel to the axis.
	return minf(ray_sphere(origin, dir, a, radius), ray_sphere(origin, dir, b, radius))


## Box with half extents `half` placed by `box` (rotation and translation, no scale).
static func ray_box(origin: Vector3, dir: Vector3, box: Transform3D, half: Vector3) -> float:
	var inv := box.affine_inverse()
	var o := inv * origin
	var d := inv.basis * dir
	var t_near := -INF
	var t_far := INF
	for i in 3:
		if absf(d[i]) < 1e-12:
			if absf(o[i]) > half[i]:
				return INF
			continue
		var t1 := (-half[i] - o[i]) / d[i]
		var t2 := (half[i] - o[i]) / d[i]
		t_near = maxf(t_near, minf(t1, t2))
		t_far = minf(t_far, maxf(t1, t2))
	if t_near > t_far or t_far < 0.0:
		return INF
	return maxf(t_near, 0.0)
