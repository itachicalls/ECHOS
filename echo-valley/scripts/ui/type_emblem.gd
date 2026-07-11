class_name TypeEmblem
extends RefCounted

## Resonance crest — a hand-drawn, beveled gem badge with a unique icon per
## element. Used in the battle HUD, versus draft, party menus and journal.
## `create()` returns a self-contained Control that redraws crisply at any size.


static func create(resonance: int, size: int = 14) -> Control:
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
			s = 14.0
		var c := Vector2(s * 0.5, s * 0.5)
		var r := s * 0.5
		var res := resonance as EchoTypes.Resonance
		var col: Color = EchoTypes.RESONANCE_COLORS.get(res, Color("cbd5e1"))
		var deep := col.darkened(0.55)
		var lite := col.lightened(0.45)
		var rim := col.lightened(0.7)

		# soft drop shadow
		draw_circle(c + Vector2(0, maxf(1.0, s * 0.08)), r, Color(0, 0, 0, 0.28))
		# dark bezel
		draw_circle(c, r, Color(0.05, 0.07, 0.10, 1.0))
		# jewel body
		draw_circle(c, r - maxf(1.0, s * 0.09), col)
		# lower shading (depth)
		draw_circle(c + Vector2(0, r * 0.28), r * 0.62, Color(deep.r, deep.g, deep.b, 0.5))
		# upper sheen
		draw_circle(c - Vector2(r * 0.22, r * 0.28), r * 0.5, Color(lite.r, lite.g, lite.b, 0.55))
		# top rim highlight
		draw_arc(c, r - maxf(1.0, s * 0.12), PI * 1.05, PI * 1.95, 16, Color(rim.r, rim.g, rim.b, 0.9), maxf(1.0, s * 0.07), true)

		# element glyph — bright, with a subtle dark backing for punch
		var ink := Color(1, 1, 1, 0.96)
		var back := Color(0.05, 0.06, 0.09, 0.35)
		_draw_glyph(res, c, s, ink, back)

	func _draw_glyph(res: EchoTypes.Resonance, c: Vector2, s: float, ink: Color, back: Color) -> void:
		match res:
			EchoTypes.Resonance.FIRE:
				_flame(c + Vector2(s * 0.03, s * 0.04), s * 0.9, back)
				_flame(c, s * 0.78, ink)
				_flame(c - Vector2(0, s * 0.02), s * 0.42, Color("ffe08a"))
			EchoTypes.Resonance.WATER:
				_droplet(c + Vector2(s * 0.03, s * 0.03), s * 0.9, back)
				_droplet(c, s * 0.78, ink)
				var hi := c - Vector2(s * 0.08, s * 0.02)
				draw_circle(hi, s * 0.07, Color("cfefff"))
			EchoTypes.Resonance.GRASS:
				_leaf(c, s, back, Vector2(s * 0.03, s * 0.03))
				_leaf(c, s, ink, Vector2.ZERO)
			EchoTypes.Resonance.ROCK:
				_crystal(c + Vector2(s * 0.03, s * 0.03), s * 0.92, back)
				_crystal(c, s * 0.8, ink)
			EchoTypes.Resonance.AIR:
				_gust(c, s, back, Vector2(s * 0.03, s * 0.03))
				_gust(c, s, ink, Vector2.ZERO)
			EchoTypes.Resonance.SHADOW:
				_crescent(c, s, back, Vector2(s * 0.03, s * 0.03))
				_crescent(c, s, ink, Vector2.ZERO)
				var star := c + Vector2(s * 0.16, -s * 0.14)
				_spark(star, s * 0.1, Color("fff3b0"))
			_:
				draw_circle(c, s * 0.16, ink)

	# ---- glyph primitives (all scale-relative) ----
	func _flame(c: Vector2, s: float, col: Color) -> void:
		var h := s * 0.5
		var w := s * 0.3
		var pts := PackedVector2Array([
			c + Vector2(0, -h),
			c + Vector2(w * 0.75, -h * 0.15),
			c + Vector2(w, h * 0.45),
			c + Vector2(w * 0.45, h * 0.62),
			c + Vector2(0, h * 0.7),
			c + Vector2(-w * 0.45, h * 0.62),
			c + Vector2(-w, h * 0.45),
			c + Vector2(-w * 0.75, -h * 0.15),
		])
		# pull the tip inward for a licking-flame notch
		pts[0] = c + Vector2(w * 0.18, -h)
		draw_colored_polygon(pts, col)

	func _droplet(c: Vector2, s: float, col: Color) -> void:
		var top := c + Vector2(0, -s * 0.5)
		var pts := PackedVector2Array([
			top,
			c + Vector2(s * 0.32, s * 0.05),
			c + Vector2(s * 0.22, s * 0.42),
			c + Vector2(-s * 0.22, s * 0.42),
			c + Vector2(-s * 0.32, s * 0.05),
		])
		draw_colored_polygon(pts, col)
		draw_circle(c + Vector2(0, s * 0.12), s * 0.3, col)

	func _leaf(c: Vector2, s: float, col: Color, off: Vector2) -> void:
		var a := c + off + Vector2(-s * 0.28, s * 0.3)
		var b := c + off + Vector2(s * 0.3, -s * 0.32)
		var pts := PackedVector2Array()
		var steps := 12
		for i in range(steps + 1):
			var t := float(i) / float(steps)
			var base := a.lerp(b, t)
			var bulge := sin(t * PI) * s * 0.2
			pts.append(base + Vector2(bulge, bulge))
		for i in range(steps + 1):
			var t := 1.0 - float(i) / float(steps)
			var base := a.lerp(b, t)
			var bulge := sin(t * PI) * s * 0.2
			pts.append(base - Vector2(bulge, bulge))
		draw_colored_polygon(pts, col)
		draw_line(a + Vector2(s * 0.02, -s * 0.02), b, Color(0, 0, 0, 0.25), maxf(1.0, s * 0.05), true)

	func _crystal(c: Vector2, s: float, col: Color) -> void:
		var pts := PackedVector2Array([
			c + Vector2(0, -s * 0.5),
			c + Vector2(s * 0.34, -s * 0.12),
			c + Vector2(s * 0.2, s * 0.48),
			c + Vector2(-s * 0.2, s * 0.48),
			c + Vector2(-s * 0.34, -s * 0.12),
		])
		draw_colored_polygon(pts, col)
		# facet lines
		draw_line(c + Vector2(0, -s * 0.5), c + Vector2(0, s * 0.48), Color(0, 0, 0, 0.22), maxf(1.0, s * 0.04), true)
		draw_line(c + Vector2(-s * 0.34, -s * 0.12), c + Vector2(s * 0.34, -s * 0.12), Color(0, 0, 0, 0.22), maxf(1.0, s * 0.04), true)

	func _gust(c: Vector2, s: float, col: Color, off: Vector2) -> void:
		var w := maxf(1.2, s * 0.11)
		var o := c + off
		draw_arc(o + Vector2(-s * 0.05, -s * 0.16), s * 0.22, -PI * 0.5, PI * 0.95, 14, col, w, true)
		draw_arc(o + Vector2(s * 0.0, s * 0.06), s * 0.28, -PI * 0.6, PI * 1.05, 16, col, w, true)
		draw_arc(o + Vector2(-s * 0.02, s * 0.26), s * 0.16, -PI * 0.5, PI * 0.9, 12, col, w, true)

	func _crescent(c: Vector2, s: float, col: Color, off: Vector2) -> void:
		var o := c + off
		draw_circle(o, s * 0.36, col)
		# carve with a body-colored circle to leave a crescent
		var carve: Color = EchoTypes.RESONANCE_COLORS.get(EchoTypes.Resonance.SHADOW, Color("7b2cbf"))
		draw_circle(o + Vector2(s * 0.16, -s * 0.06), s * 0.32, carve)

	func _spark(c: Vector2, s: float, col: Color) -> void:
		var pts := PackedVector2Array([
			c + Vector2(0, -s),
			c + Vector2(s * 0.28, -s * 0.28),
			c + Vector2(s, 0),
			c + Vector2(s * 0.28, s * 0.28),
			c + Vector2(0, s),
			c + Vector2(-s * 0.28, s * 0.28),
			c + Vector2(-s, 0),
			c + Vector2(-s * 0.28, -s * 0.28),
		])
		draw_colored_polygon(pts, col)
