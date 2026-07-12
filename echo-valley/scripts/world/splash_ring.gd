extends Node2D

var radius: float = 4.0


func _ready() -> void:
	radius = float(get_meta("radius", 4.0))
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Color("cfefff", 0.55), 1.2, true)
