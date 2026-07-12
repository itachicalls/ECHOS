extends Control
## Pulsing trial platform drawn under gym boss Harmons.

var accent := Color("5ad4c8")
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var pulse := 0.55 + sin(_time * 2.2) * 0.2
	# Ground shadow
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-size.x * 0.46, size.y * 0.18),
		c + Vector2(size.x * 0.46, size.y * 0.18),
		c + Vector2(size.x * 0.38, size.y * 0.42),
		c + Vector2(-size.x * 0.38, size.y * 0.42),
	]), Color(0.04, 0.06, 0.1, 0.55))
	# Stone slab
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-size.x * 0.42, size.y * 0.12),
		c + Vector2(size.x * 0.42, size.y * 0.12),
		c + Vector2(size.x * 0.36, size.y * 0.34),
		c + Vector2(-size.x * 0.36, size.y * 0.34),
	]), Color("3a4a58", 0.82))
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-size.x * 0.36, size.y * 0.08),
		c + Vector2(size.x * 0.36, size.y * 0.08),
		c + Vector2(size.x * 0.30, size.y * 0.22),
		c + Vector2(-size.x * 0.30, size.y * 0.22),
	]), Color("5a7088", 0.9))
	# Resonance rings
	for i in 3:
		var rx := size.x * (0.34 - i * 0.06)
		var ry := size.y * (0.22 - i * 0.03)
		var a := (0.28 - i * 0.06) * pulse
		draw_arc(c + Vector2(0, size.y * 0.04), rx, 0, TAU, 28, Color(accent.r, accent.g, accent.b, a), 1.5, true)
	# Corner runes
	for j in 4:
		var ang := float(j) * TAU / 4.0 + _time * 0.35
		var p := c + Vector2(cos(ang), sin(ang) * 0.35) * size.x * 0.28
		draw_rect(Rect2(p.x - 1, p.y - 1, 2, 2), Color("ffe08a", 0.5 + sin(_time * 4 + j) * 0.3))
