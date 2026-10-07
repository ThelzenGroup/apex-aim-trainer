extends TestCase
## Analytic ray tests against spheres, capsules and boxes.

const FWD := Vector3(0, 0, -1)
## Vectors are 32-bit floats; 0.01 mm is far below anything a hitbox can resolve.
const EPS := 1e-5


func test_ray_sphere() -> void:
	check_near(HitTest.ray_sphere(Vector3.ZERO, FWD, Vector3(0, 0, -10), 1.0), 9.0, EPS)
	check_eq(HitTest.ray_sphere(Vector3.ZERO, FWD, Vector3(0, 2, -10), 1.0), INF, "passes above")
	check_eq(HitTest.ray_sphere(Vector3.ZERO, FWD, Vector3(0, 0, 10), 1.0), INF, "behind")
	check_eq(HitTest.ray_sphere(Vector3.ZERO, FWD, Vector3(0, 0, 0.5), 1.0), 0.0, "inside")


func test_ray_capsule_body_and_caps() -> void:
	var a := Vector3(0, 0, -10)
	var b := Vector3(0, 2, -10)
	check_near(HitTest.ray_capsule(Vector3(0, 1, 0), FWD, a, b, 0.5), 9.5, EPS, "side")
	check_near(HitTest.ray_capsule(Vector3(0, 2.3, 0), FWD, a, b, 0.5), 10.0 - sqrt(0.25 - 0.09), EPS, "top cap")
	check_eq(HitTest.ray_capsule(Vector3(0, 2.6, 0), FWD, a, b, 0.5), INF, "over the top")
	check_eq(HitTest.ray_capsule(Vector3(0.6, 1, 0), FWD, a, b, 0.5), INF, "beside")
	check_near(HitTest.ray_capsule(Vector3(0, 10, -10), Vector3.DOWN, a, b, 0.5), 7.5, EPS, "down the axis")
	check_eq(HitTest.ray_capsule(Vector3(0, -0.3, -10), Vector3.DOWN, a, b, 0.5), 0.0, "inside a cap")


func test_ray_capsule_tilted() -> void:
	# A capsule lying along X; a ray from above hits its top at y = radius.
	var t := HitTest.ray_capsule(Vector3(0.3, 5, 0), Vector3.DOWN, Vector3(-1, 0, 0), Vector3(1, 0, 0), 0.2)
	check_near(t, 4.8, EPS)


func test_ray_box_rotated() -> void:
	var box := Transform3D(Basis(Vector3.UP, deg_to_rad(45)), Vector3(0, 0, -10))
	var half := Vector3(1, 1, 1)
	check_near(HitTest.ray_box(Vector3.ZERO, FWD, box, half), 10.0 - sqrt(2.0), EPS, "hits the corner edge")
	check_eq(HitTest.ray_box(Vector3(1.5, 0, 0), FWD, box, half), INF, "misses past the corner")
	check_near(HitTest.ray_box(Vector3(1.0, 0, 0), FWD, box, half), 10.0 - (sqrt(2.0) - 1.0), EPS, "hits a face")
	check_eq(HitTest.ray_box(Vector3(0, 0, -10), FWD, box, half), 0.0, "inside")
