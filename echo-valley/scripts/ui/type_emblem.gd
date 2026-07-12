class_name TypeEmblem
extends RefCounted

## Tiny resonance pip — flat, cute, and light. Used in battle HUD, draft, menus.


static func create(resonance: int, size: int = 9) -> Control:
	var node := Emblem.new()
	node.resonance = resonance
	node.custom_minimum_size = Vector2(size, size)
	node.size = Vector2(size, size)
	return node


class Emblem extends Control:
	var resonance: int = 0

	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		var s: float = minf(size.x, size.y)
		if s <= 0.0:
			s = 9.0
		var c := Vector2(s * 0.5, s * 0.5)
		var r := s * 0.42
		var res := resonance as EchoTypes.Resonance
		var col: Color = EchoTypes.RESONANCE_COLORS.get(res, Color("cbd5e1"))
		var rim := col.darkened(0.28)
		var face := col.lightened(0.12)

		# Soft flat disc — no heavy bezel or drop shadow.
		draw_circle(c, r + 0.5, rim)
		draw_circle(c, r, face)
		if s >= 7.0:
			draw_rect(Rect2(c.x - 1, c.y - r * 0.55, 2, 1), Color(1, 1, 1, 0.45))

		_draw_glyph(res, c, s * 0.62, Color(1, 1, 1, 0.92))

	func _draw_glyph(res: EchoTypes.Resonance, c: Vector2, s: float, ink: Color) -> void:
		match res:
			EchoTypes.Resonance.FIRE:
				_flame(c, s, ink)
				_flame(c - Vector2(0, s * 0.04), s * 0.38, Color("ffe08a"))
			EchoTypes.Resonance.WATER:
				_droplet(c, s, ink)
				draw_circle(c - Vector2(s * 0.1, s * 0.04), s * 0.06, Color("cfefff"))
			EchoTypes.Resonance.GRASS:
				_leaf(c, s, ink)
			EchoTypes.Resonance.ROCK:
				_crystal(c, s, ink)
			EchoTypes.Resonance.AIR:
				_gust(c, s, ink)
			EchoTypes.Resonance.SHADOW:
				_crescent(c, s, ink)
				_spark(c + Vector2(s * 0.18, -s * 0.16), s * 0.09, Color("fff3b0"))
			_:
				draw_circle(c, s * 0.12, ink)

	func _flame(c: Vector2, s: float, col: Color) -> void:
		var h := s * 0.48
		var w := s * 0.28
		var pts := PackedVector2Array([
			c + Vector2(w * 0.12, -h),
			c + Vector2(w * 0.7, -h * 0.1),
			c + Vector2(w, h * 0.42),
			c + Vector2(0, h * 0.65),
			c + Vector2(-w, h * 0.42),
			c + Vector2(-w * 0.7, -h * 0.1),
		])
		draw_colored_polygon(pts, col)

	func _droplet(c: Vector2, s: float, col: Color) -> void:
		var top := c + Vector2(0, -s * 0.48)
		var pts := PackedVector2Array([
			top,
			c + Vector2(s * 0.28, s * 0.04),
			c + Vector2(s * 0.18, s * 0.38),
			c + Vector2(-s * 0.18, s * 0.38),
			c + Vector2(-s * 0.28, s * 0.04),
		])
		draw_colored_polygon(pts, col)

	func _leaf(c: Vector2, s: float, col: Color) -> void:
		var a := c + Vector2(-s * 0.26, s * 0.26)
		var b := c + Vector2(s * 0.26, -s * 0.28)
		var pts := PackedVector2Array()
		for i in 7:
			var t := float(i) / 6.0
			var base := a.lerp(b, t)
			var bulge := sin(t * PI) * s * 0.16
			pts.append(base + Vector2(bulge, bulge))
		for i in 7:
			var t := 1.0 - float(i) / 6.0
			var base := a.lerp(b, t)
			var bulge := sin(t * PI) * s * 0.16
			pts.append(base - Vector2(bulge, bulge))
		draw_colored_polygon(pts, col)

	func _crystal(c: Vector2, s: float, col: Color) -> void:
		var pts := PackedVector2Array([
			c + Vector2(0, -s * 0.46),
			c + Vector2(s * 0.3, -s * 0.1),
			c + Vector2(s * 0.16, s * 0.42),
			c + Vector2(-s * 0.16, s * 0.42),
			c + Vector2(-s * 0.3, -s * 0.1),
		])
		draw_colored_polygon(pts, col)

	func _gust(c: Vector2, s: float, col: Color) -> void:
		var w := maxf(1.0, s * 0.1)
		draw_arc(c + Vector2(-s * 0.04, -s * 0.14), s * 0.18, -PI * 0.5, PI * 0.95, 10, col, w, true)
		draw_arc(c + Vector2(0, s * 0.05), s * 0.22, -PI * 0.6, PI * 1.05, 10, col, w, true)

	func _crescent(c: Vector2, s: float, col: Color) -> void:
		draw_circle(c, s * 0.32, col)
		var carve: Color = EchoTypes.RESONANCE_COLORS.get(EchoTypes.Resonance.SHADOW, Color("7b2cbf")).lightened(0.12)
		draw_circle(c + Vector2(s * 0.14, -s * 0.05), s * 0.28, carve)

	func _spark(c: Vector2, s: float, col: Color) -> void:
		draw_rect(Rect2(c.x, c.y - s, 1, s * 2), col)
		draw_rect(Rect2(c.x - s, c.y, s * 2, 1), col)
