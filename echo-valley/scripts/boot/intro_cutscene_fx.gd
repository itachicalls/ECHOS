extends Control
## Lightweight VFX overlay (rings, glow) on top of real sprite compositions.

var _visual := ""


func set_visual(v: String) -> void:
	_visual = v
	queue_redraw()


func _draw() -> void:
	if _visual in ["chorus", "bond"]:
		var c := Vector2(120, 52)
		for r in [42, 32, 22]:
			draw_arc(c, float(r), 0, TAU, 40, Color("5ad4c8", 0.22), 1.0, true)
	elif _visual == "fracture":
		var c := Vector2(120, 54)
		for i in 8:
			var ang := i * TAU / 8.0
			draw_line(c, c + Vector2(cos(ang), sin(ang)) * 46.0, Color("8ad8ff", 0.45), 1.0)
	elif _visual == "disturbance":
		for p in [Vector2(70, 58), Vector2(120, 52), Vector2(168, 56)]:
			draw_circle(p, 6.0, Color("ff6088", 0.12))
			draw_circle(p, 2.0, Color("ffd166", 0.55))
	elif _visual == "depart":
		draw_rect(Rect2(104, 28, 32, 4), Color("5ad4c8", 0.35))
