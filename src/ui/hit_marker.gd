class_name HitMarker
extends Control
## The crosshair dot plus an X-shaped hit marker that flashes on hits and fades out.

const FADE := 0.15
const DOT_COLOR := Color(0.2, 1.0, 0.4)

var _color := Color.WHITE
var _scale := 1.0
var _left := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func flash(color: Color, size_scale: float = 1.0) -> void:
	_color = color
	_scale = size_scale
	_left = FADE
	queue_redraw()


func _process(delta: float) -> void:
	if _left > 0.0:
		_left -= delta
		queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	draw_rect(Rect2(center - Vector2(2, 2), Vector2(4, 4)), DOT_COLOR)
	if _left <= 0.0:
		return
	var color := Color(_color, clampf(_left / FADE, 0.0, 1.0))
	var inner := 7.0 * _scale
	var outer := 15.0 * _scale
	for corner in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var direction: Vector2 = corner.normalized()
		draw_line(center + direction * inner, center + direction * outer, color, 2.0 * _scale, true)
