class_name TargetBar
extends Control
## The current target's shield (in 25-point cells, coloured by tier) and health, drawn at
## the top of the screen.

const WIDTH := 320.0
const CELL := 25.0

var bot: Bot


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -WIDTH / 2.0
	offset_right = WIDTH / 2.0
	offset_top = 24.0
	offset_bottom = 58.0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if bot == null or not is_instance_valid(bot):
		return
	var shield_color: Color = ApexDamage.SHIELD_COLORS[bot.shield_tier]
	var cells := ceili(bot.max_shield / CELL)
	var gap := 3.0
	var cell_width := (WIDTH - gap * (cells - 1)) / maxi(cells, 1)
	for i in cells:
		var rect := Rect2(i * (cell_width + gap), 0, cell_width, 12)
		draw_rect(rect, Color(0, 0, 0, 0.5))
		var fill := clampf((bot.shield - i * CELL) / CELL, 0.0, 1.0)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x * fill, rect.size.y)), shield_color)
	var health_rect := Rect2(0, 18, WIDTH, 10)
	draw_rect(health_rect, Color(0, 0, 0, 0.5))
	draw_rect(Rect2(health_rect.position, Vector2(WIDTH * bot.health / ApexDamage.HEALTH, 10)), Color(0.95, 0.95, 0.95))
