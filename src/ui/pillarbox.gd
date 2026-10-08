class_name Pillarbox
extends CanvasLayer
## Black bars at the sides of the 3D view when "Limit view to 21:9" is on and the screen
## is wider than that. The bars sit above the 3D view and below every HUD, so lab text
## stays readable over them.

var _bars: Array[ColorRect] = []


func _ready() -> void:
	layer = -100
	for side in 2:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
		_bars.append(bar)
	get_viewport().size_changed.connect(_layout)
	Settings.changed.connect(_layout)
	_layout()


## Width of each bar in pixels, 0 when there are none.
func bar_width() -> float:
	return _bars[0].size.x if _bars[0].visible else 0.0


func _layout() -> void:
	var screen := get_viewport().get_visible_rect().size
	var width := ApexSensitivity.pillarbox_width(screen, ApexSensitivity.ASPECT_21_9) \
		if Settings.limit_to_21_9 else 0.0
	_bars[0].position = Vector2.ZERO
	_bars[1].position = Vector2(screen.x - width, 0.0)
	for bar in _bars:
		bar.size = Vector2(width, screen.y)
		bar.visible = width > 0.0
