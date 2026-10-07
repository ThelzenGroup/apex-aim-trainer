class_name TestCase
extends RefCounted
## Base for unit tests run by tests/run_tests.gd. Methods named test_* run in order;
## the assert helpers record failures instead of stopping the run.

var failures: PackedStringArray = []
var current_test := ""
## The runner; tests that need nodes in a live tree add them to tree.root and await frames.
var tree: SceneTree


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append("%s: %s" % [current_test, message])


func check_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	check(actual == expected, "%s expected %s, got %s" % [message, expected, actual])


func check_near(actual: float, expected: float, tolerance: float, message: String = "") -> void:
	check(absf(actual - expected) <= tolerance, "%s expected %s ± %s, got %s" % [message, expected, tolerance, actual])


## Vector2/Vector3 hold 32-bit floats, so compare them with a tolerance rather than ==.
func check_vec_near(actual: Variant, expected: Variant, tolerance: float, message: String = "") -> void:
	check(actual.distance_to(expected) <= tolerance, "%s expected %s ± %s, got %s" % [message, expected, tolerance, actual])
