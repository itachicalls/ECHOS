extends Control
## Rich pixel-art sky, hills, and grass for title / loading screens.

const VIEW_W := 240
const VIEW_H := 160

var _grass_tex: Texture2D
var _dirt_tex: Texture2D
var _tall_grass_tex: Texture2D
var _cloud_offset: float = 0.0
var _time: float = 0.0

var _stars: PackedVector2Array = PackedVector2Array()
var _star_twinkle: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(VIEW_W, VIEW_H)
	_grass_tex = load("res://assets/kenney/gen/grass_field.png") as Texture2D
	_dirt_tex = load("res://assets/kenney/tiles/dirt.png") as Texture2D
	_tall_grass_tex = load("res://assets/kenney/gen/tall_grass.png") as Texture2D
	_seed_stars()
	set_process(true)


func _seed_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in 48:
		_stars.append(Vector2(rng.randf_range(4, VIEW_W - 4), rng.randf_range(6, 72)))
		_star_twinkle.append(rng.randf_range(0.0, TAU))


func _process(delta: float) -> void:
	_time += delta
	_cloud_offset = fmod(_cloud_offset + delta * 6.0, VIEW_W + 80.0)
	queue_redraw()


func _sky_color(t: float) -> Color:
	if t < 0.42:
		var u := t / 0.42
		return Color("0c1438").lerp(Color("2a3f7a"), u)
	if t < 0.72:
		var u := (t - 0.42) / 0.30
		return Color("2a3f7a").lerp(Color("6b8fd4"), u)
	if t < 0.88:
		var u := (t - 0.72) / 0.16
		return Color("6b8fd4").lerp(Color("f0b878"), u)
	var u := (t - 0.88) / 0.12
	return Color("f0b878").lerp(Color("ffe8b8"), u)


func _draw() -> void:
	for y in VIEW_H:
		var t := float(y) / float(VIEW_H - 1)
		draw_line(Vector2(0, y), Vector2(VIEW_W, y), _sky_color(t))

	var aurora := PackedVector2Array([
		Vector2(0, 38), Vector2(60, 28), Vector2(120, 34), Vector2(180, 26), Vector2(VIEW_W, 36),
		Vector2(VIEW_W, 48), Vector2(0, 52),
	])
	draw_colored_polygon(aurora, Color("5ad4c8", 0.12))

	for i in _stars.size():
		var p := _stars[i]
		var fade := clampf(1.0 - (p.y - 8.0) / 64.0, 0.15, 1.0)
		var tw := 0.55 + 0.45 * sin(_time * 2.2 + _star_twinkle[i])
		draw_rect(Rect2(p.x, p.y, 1, 1), Color(1, 1, 1, fade * tw * 0.9))

	var sun := Vector2(188, 34)
	for r in [22, 16, 10]:
		var a := 0.08 + float(10 - r) * 0.04
		draw_circle(sun, float(r), Color("ffe8a0", a))
	draw_circle(sun, 7.0, Color("fff4c8"))
	draw_circle(sun, 5.0, Color("fffde8"))

	_draw_cloud(Vector2(28 + _cloud_offset * 0.35, 22), 1.0)
	_draw_cloud(Vector2(110 + _cloud_offset * 0.55, 38), 0.85)
	_draw_cloud(Vector2(200 + _cloud_offset * 0.4 - VIEW_W, 18), 0.7)

	_draw_hill(118, 92, 130, Color("2d6b3a"))
	_draw_hill(200, 96, 110, Color("256032"))
	_draw_hill(52, 100, 95, Color("3a8a48"))
	_draw_hill(168, 104, 88, Color("348040"))
	_draw_hill(0, 108, 140, Color("4aa858"))
	_draw_hill(120, 112, 150, Color("42a050"))

	var ground_y := 118
	var grass_h := 42
	if _grass_tex:
		var tw := _grass_tex.get_width()
		var th := _grass_tex.get_height()
		var rows := ceili(float(grass_h) / float(th))
		for row in rows:
			for x in range(0, VIEW_W, tw):
				draw_texture_rect(_grass_tex, Rect2(x, ground_y + row * th, tw, th), false)
	else:
		draw_rect(Rect2(0, ground_y, VIEW_W, grass_h), Color("4aa858"))

	if _dirt_tex:
		var tw := _dirt_tex.get_width()
		var path_w := 28
		var path_x := 108
		for x in range(path_x, path_x + path_w, tw):
			draw_texture_rect(_dirt_tex, Rect2(x, ground_y + 14, tw, 16), false)
		draw_rect(Rect2(path_x - 1, ground_y + 14, 1, 16), Color("2a5a30", 0.5))
		draw_rect(Rect2(path_x + path_w, ground_y + 14, 1, 16), Color("2a5a30", 0.5))

	_draw_tuft(Vector2(18, ground_y + 8))
	_draw_tuft(Vector2(72, ground_y + 12))
	_draw_tuft(Vector2(210, ground_y + 6))
	_draw_tuft(Vector2(156, ground_y + 10))

	_draw_flower(Vector2(44, ground_y + 20), Color("ff7ab0"))
	_draw_flower(Vector2(86, ground_y + 26), Color("ffd060"))
	_draw_flower(Vector2(196, ground_y + 22), Color("c878ff"))
	_draw_flower(Vector2(24, ground_y + 30), Color("78d8ff"))

	draw_rect(Rect2(0, VIEW_H - 6, VIEW_W, 6), Color("1a4028", 0.35))


func _draw_hill(cx: float, base_y: float, radius: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 24
	for i in steps + 1:
		var a := PI + float(i) / float(steps) * PI
		pts.append(Vector2(cx + cos(a) * radius, base_y + sin(a) * radius * 0.42))
	pts.append(Vector2(cx + radius, base_y + 40))
	pts.append(Vector2(cx - radius, base_y + 40))
	draw_colored_polygon(pts, col)
	draw_line(Vector2(cx - radius * 0.35, base_y - 2), Vector2(cx + radius * 0.1, base_y - 6), Color(1, 1, 1, 0.08))


func _draw_cloud(origin: Vector2, scale: float) -> void:
	var puff := Color(1, 1, 1, 0.88 * scale)
	var shadow := Color("9ab8e8", 0.35 * scale)
	var offsets := [
		Vector2(0, 0), Vector2(10, -2), Vector2(22, 0), Vector2(34, 2),
		Vector2(6, 4), Vector2(18, 5), Vector2(28, 4),
	]
	for off in offsets:
		draw_circle(origin + off * scale, 5.5 * scale, shadow)
	for off in offsets:
		draw_circle(origin + off * scale + Vector2(0, -1), 5.0 * scale, puff)


func _draw_tuft(pos: Vector2) -> void:
	if _tall_grass_tex:
		draw_texture_rect(_tall_grass_tex, Rect2(pos.x - 4, pos.y - 10, 16, 16), false)
	else:
		draw_rect(Rect2(pos.x, pos.y - 6, 2, 6), Color("2d7038"))
		draw_rect(Rect2(pos.x + 3, pos.y - 8, 2, 8), Color("3a9050"))
		draw_rect(Rect2(pos.x + 6, pos.y - 5, 2, 5), Color("2d7038"))


func _draw_flower(pos: Vector2, petal_col: Color) -> void:
	draw_rect(Rect2(pos.x, pos.y, 1, 3), Color("2d6038"))
	draw_rect(Rect2(pos.x - 1, pos.y - 1, 3, 1), petal_col)
	draw_rect(Rect2(pos.x, pos.y - 2, 1, 1), Color("fff0a8"))
