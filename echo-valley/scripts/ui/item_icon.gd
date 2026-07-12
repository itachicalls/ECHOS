class_name ItemIcon
extends Control

## Painted item icons — crisp pixel-art capsules, rod, salve, etc.

var item_id: String = "echo_capsule"
var icon_size: int = 16

static var _tex_cache: Dictionary = {}


static func make(id: String, size: int = 16) -> ItemIcon:
	var node := ItemIcon.new()
	node.item_id = id
	node.icon_size = size
	node.custom_minimum_size = Vector2(size, size)
	node.size = Vector2(size, size)
	return node


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func _draw() -> void:
	var s := float(icon_size)
	match item_id:
		"fishing_rod":
			_draw_rod(s)
		"heart_salve":
			_draw_salve(s)
		_:
			var tex := _capsule_texture(item_id, icon_size)
			if tex:
				draw_texture_rect(tex, Rect2(0, 0, s, s), false)


func _capsule_texture(kind: String, size: int) -> Texture2D:
	var key := "%s_%d" % [kind, size]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var img := _build_capsule_image(kind)
	if size != 32:
		img.resize(size, size, Image.INTERPOLATE_NEAREST)
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[key] = tex
	return tex


func _build_capsule_image(kind: String) -> Image:
	const W := 32
	var img := Image.create(W, W, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var pal := _palette_for_kind(kind)
	var cx := 16.0
	var r := 7.0
	var cy_top := 10.0
	var cy_bot := 22.0
	var mid := 16.0
	var outline := Color("1c2430")
	var band := Color("2e3848")
	var band_hi := Color("566678")
	var btn_ring := Color("dce6f2")
	var btn_hi := Color("ffffff")

	for y in W:
		for x in W:
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			if not _inside_capsule(p, cx, cy_top, cy_bot, r):
				continue
			if _near_capsule_edge(p, cx, cy_top, cy_bot, r, 0.95):
				img.set_pixel(x, y, outline)
				continue

			var on_band := absf(p.y - mid) <= 2.0
			var dist_btn := p.distance_to(Vector2(cx, mid))

			if on_band:
				if dist_btn <= 1.8:
					if dist_btn <= 1.1:
						img.set_pixel(x, y, pal.accent)
					elif dist_btn <= 1.45:
						img.set_pixel(x, y, btn_ring)
					else:
						img.set_pixel(x, y, band)
					if p.x <= cx - 0.5 and p.y <= mid - 0.5 and dist_btn <= 1.0:
						img.set_pixel(x, y, btn_hi)
					if kind == "revive_capsule" and dist_btn <= 1.2:
						if absf(p.x - cx) <= 0.55 or absf(p.y - mid) <= 0.55:
							img.set_pixel(x, y, btn_hi)
					if kind == "evo_capsule" and dist_btn <= 0.85:
						img.set_pixel(x, y, Color("fff6cc"))
				else:
					img.set_pixel(x, y, band_hi if p.y < mid else band)
				continue

			var top_half := p.y < mid
			var base: Color = pal.top if top_half else pal.bottom
			if top_half:
				if p.x <= cx - 1.0 and p.y <= cy_top - 1.0:
					base = pal.top_hi
				elif p.x >= cx + 2.0:
					base = pal.top_shade
			else:
				if p.x >= cx + 2.0:
					base = pal.bottom_shade
				elif p.x <= cx - 2.0 and p.y >= mid + 2.0:
					base = pal.bottom_hi

			img.set_pixel(x, y, base)

	return img


func _inside_capsule(p: Vector2, cx: float, cy_top: float, cy_bot: float, r: float) -> bool:
	if p.y < cy_top:
		return p.distance_to(Vector2(cx, cy_top)) <= r
	if p.y > cy_bot:
		return p.distance_to(Vector2(cx, cy_bot)) <= r
	return absf(p.x - cx) <= r


func _near_capsule_edge(p: Vector2, cx: float, cy_top: float, cy_bot: float, r: float, inset: float) -> bool:
	return _inside_capsule(p, cx, cy_top, cy_bot, r) and not _inside_capsule(p, cx, cy_top, cy_bot, r - inset)


func _palette_for_kind(kind: String) -> Dictionary:
	match kind:
		"revive_capsule":
			return {
				"top": Color("effff6"),
				"top_hi": Color("ffffff"),
				"top_shade": Color("c8e8d8"),
				"bottom": Color("3de88a"),
				"bottom_hi": Color("5dffa8"),
				"bottom_shade": Color("22b866"),
				"accent": Color("1faa62"),
			}
		"evo_capsule":
			return {
				"top": Color("fff8e0"),
				"top_hi": Color("fffcee"),
				"top_shade": Color("f0d898"),
				"bottom": Color("f0a820"),
				"bottom_hi": Color("ffc848"),
				"bottom_shade": Color("c88010"),
				"accent": Color("e09018"),
			}
		_:
			return {
				"top": Color("f2f6fa"),
				"top_hi": Color("ffffff"),
				"top_shade": Color("d8e0ea"),
				"bottom": Color("34c86a"),
				"bottom_hi": Color("48de7e"),
				"bottom_shade": Color("229650"),
				"accent": Color("1a9e4c"),
			}


func _draw_salve(s: float) -> void:
	var cx := s * 0.5
	draw_rect(Rect2(cx - s * 0.14, s * 0.72, s * 0.28, s * 0.06), Color(0, 0, 0, 0.2))
	draw_rect(Rect2(cx - s * 0.12, s * 0.34, s * 0.24, s * 0.4), Color("ff6b8a"))
	draw_rect(Rect2(cx - s * 0.1, s * 0.36, s * 0.2, s * 0.34), Color("ff8fab"))
	draw_rect(Rect2(cx - s * 0.08, s * 0.22, s * 0.16, s * 0.14), Color("ffd0dc"))
	draw_circle(Vector2(cx - s * 0.03, s * 0.46), s * 0.05, Color("fff0f4"))


func _draw_rod(s: float) -> void:
	var cx := s * 0.5
	draw_line(Vector2(cx - s * 0.34, s * 0.82), Vector2(cx + s * 0.3, s * 0.18), Color("8b5a2b"), 1.5)
	draw_line(Vector2(cx + s * 0.3, s * 0.18), Vector2(cx + s * 0.34, s * 0.08), Color("cfe8ff", 0.8), 1.0)
	draw_circle(Vector2(cx - s * 0.34, s * 0.82), s * 0.06, Color("c49bff"))
