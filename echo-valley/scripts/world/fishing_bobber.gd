extends Node2D

## Tiny painted fishing bobber for overworld casts.


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, 1), 2.2, Color("c62828"))
	draw_circle(Vector2(0, -1), 2.0, Color("f2f7ff"))
	draw_circle(Vector2(-0.6, -1.6), 0.7, Color(1, 1, 1, 0.55))
	draw_line(Vector2(0, -3.2), Vector2(0, -5.0), Color("8b5a2b"), 1.0)
