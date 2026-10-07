class_name StickView
extends Control
## Draws one analog stick: the raw position (white), the position after the response
## curve (green), and the deadzone and outer-threshold circles.

var raw := Vector2.ZERO
var shaped := Vector2.ZERO
var deadzone := Settings.stick_deadzone
var outer := Settings.stick_outer


func _init() -> void:
	custom_minimum_size = Vector2(220, 220)


func _draw() -> void:
	var half := minf(size.x, size.y) / 2.0
	var center := Vector2(half, half)
	draw_rect(Rect2(Vector2.ZERO, Vector2(half, half) * 2.0), Color(1, 1, 1, 0.25), false, 1.0)
	draw_arc(center, half, 0.0, TAU, 64, Color(1, 1, 1, 0.4), 1.0)
	draw_arc(center, half * deadzone, 0.0, TAU, 32, Color(1, 0.4, 0.3, 0.8), 1.0)
	draw_arc(center, half * outer, 0.0, TAU, 64, Color(1, 0.8, 0.2, 0.6), 1.0)
	draw_circle(center + raw * half, 5.0, Color.WHITE)
	draw_circle(center + shaped * half, 4.0, Color(0.3, 1.0, 0.4))
