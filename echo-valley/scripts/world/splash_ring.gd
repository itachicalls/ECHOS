extends Node2D

var radius: float = 4.0


func _ready() -> void:
	radius = float(get_meta("radius", 4.0))
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color("e8f7ff", 0.65), 1.1, true)
	draw_arc(Vector2(0, 0.5), radius * 0.72, 0.0, TAU, 20, Color("9fd4ff", 0.35), 0.8, true)
