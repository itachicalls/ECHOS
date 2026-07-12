extends Control
## Rich route-themed battle scenery — full-frame pixel art with parallax layers.

const VIEW_W := 240
const VIEW_H := 160
const HORIZON := 74

var _theme := "meadow"
var _time := 0.0
var _cloud_drift := 0.0
var _grass_tex: Texture2D
var _tall_grass_tex: Texture2D
var _stars: PackedVector2Array = PackedVector2Array()
var _star_phase: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(VIEW_W, VIEW_H)
	_grass_tex = load("res://assets/kenney/gen/grass_field.png") as Texture2D
	_tall_grass_tex = load("res://assets/kenney/gen/tall_grass.png") as Texture2D
	_seed_stars(24)
	set_process(true)


func _seed_stars(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8181
	for i in count:
		_stars.append(Vector2(rng.randf_range(2, VIEW_W - 2), rng.randf_range(4, 48)))
		_star_phase.append(rng.randf_range(0.0, TAU))


func configure(map_id: String, is_ranger: bool, kind: String) -> void:
	if is_ranger:
		_theme = "ranger"
	elif map_id.begins_with("desert"):
		_theme = "desert"
	elif map_id.begins_with("jungle"):
		_theme = "jungle"
	elif map_id.begins_with("cave"):
		_theme = "cave"
	elif map_id == "route2":
		_theme = "wood"
	elif kind == "versus":
		_theme = "arena"
	else:
		_theme = "meadow"
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_cloud_drift = fmod(_cloud_drift + delta * 5.0, VIEW_W + 60.0)
	queue_redraw()


func _draw() -> void:
	# Always paint the full frame so nothing shows the engine clear color.
	draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color("1a2030"))
	match _theme:
		"desert": _draw_desert()
		"jungle": _draw_jungle()
		"cave": _draw_cave()
		"wood": _draw_wood()
		"ranger": _draw_ranger()
		"arena": _draw_arena()
		_: _draw_meadow()
	_vignette()


# ---- themes ----------------------------------------------------------------

func _draw_meadow() -> void:
	_paint_sky(func(t): return _sky_day(t))
	_draw_sun(Vector2(196, 22), Color("fff8d0"))
	for i in _stars.size():
		if i % 3 != 0:
			continue
		var tw := 0.5 + 0.5 * sin(_time * 1.8 + _star_phase[i])
		draw_rect(Rect2(_stars[i].x, _stars[i].y, 1, 1), Color(1, 1, 1, tw * 0.35))
	_draw_cloud(Vector2(8 + _cloud_drift * 0.3, 14), 0, 0.75)
	_draw_cloud(Vector2(148 + _cloud_drift * 0.45, 26), 1, 0.65)
	_draw_hill(200, 68, 88, Color("3a7a48"), Color("4a9a58"))
	_draw_hill(48, 72, 72, Color("4a9a58"), Color("5aad62"))
	_draw_hill(140, 76, 100, Color("3d8a4a"), Color("52a85a"))
	_tile_ground(78, Color("4a9a50"))
	_scatter_tufts(82, 8)
	_scatter_flowers(88, 5)
	_draw_battle_floor()


func _draw_wood() -> void:
	_paint_sky(func(t): return Color("3a5878").lerp(Color("8ab898"), t))
	_draw_sun(Vector2(180, 18), Color("ffe8b0", 0.55))
	_draw_cloud(Vector2(20 + _cloud_drift * 0.25, 20), 2, 0.5)
	for i in 7:
		var depth := float(i) / 6.0
		var tx := 10 + i * 32 + sin(_time * 0.3 + i) * 0.4
		_draw_tree(tx, 44 + depth * 8, 0.55 + depth * 0.45)
	_draw_hill(170, 74, 80, Color("2d6040"), Color("3a7848"))
	_draw_hill(60, 78, 65, Color("356840"), Color("428850"))
	_tile_ground(80, Color("3a7840"))
	_scatter_tufts(84, 6)
	# Light shafts through trees.
	for i in 3:
		var lx := 40 + i * 56 + sin(_time * 0.5 + i) * 2
		draw_rect(Rect2(lx, 8, 3, 62), Color("fff8c0", 0.04 + sin(_time + i) * 0.02))
	_draw_battle_floor()


func _draw_desert() -> void:
	_paint_sky(func(t): return Color("e87830").lerp(Color("ffe8a8"), t))
	_draw_sun(Vector2(120, 20), Color("fff0a0"), 14)
	_draw_hill(40, 66, 55, Color("c89840"), Color("d8a850"))
	_draw_hill(180, 70, 70, Color("b88838"), Color("c89848"))
	for y in range(72, 100, 5):
		var w := sin(_time * 2.0 + y * 0.2) * 1.5
		draw_line(Vector2(0, y + w), Vector2(VIEW_W, y), Color("d8b060", 0.25))
	_tile_ground(96, Color("d4b058"))
	for i in 4:
		_draw_cactus(24 + i * 52, 92)
	_draw_dune_ripples(98)
	_draw_battle_floor()


func _draw_jungle() -> void:
	_paint_sky(func(t): return Color("1a3828").lerp(Color("4a8868"), t))
	draw_rect(Rect2(0, 0, VIEW_W, 32), Color("0c2018", 0.75))
	for i in 8:
		draw_rect(Rect2(4 + i * 28, 2 + (i % 3), 24 + (i % 2) * 8, 8), Color("1a4028", 0.9))
	for i in 5:
		draw_rect(Rect2(12 + i * 44, 10, 2, 20 + (i % 3) * 6), Color("2a5838"))
		draw_rect(Rect2(10 + i * 44, 8, 6, 4), Color("3a7048"))
	# Mist band.
	draw_rect(Rect2(0, 52, VIEW_W, 18), Color("a8d8c8", 0.08))
	_draw_hill(100, 76, 110, Color("2a6038"), Color("3a7848"))
	_tile_ground(84, Color("3a8048"))
	_scatter_tufts(88, 10)
	for i in 4:
		draw_rect(Rect2(18 + i * 54, 94, 2, 6), Color("4a9858"))
		draw_rect(Rect2(16 + i * 54, 92, 6, 2), Color("ff6088", 0.8))
	_draw_battle_floor()


func _draw_cave() -> void:
	for y in VIEW_H:
		var t := float(y) / float(VIEW_H - 1)
		draw_line(Vector2(0, y), Vector2(VIEW_W, y), Color("12101c").lerp(Color("2a2838"), t))
	# Ceiling stalactites.
	for i in 10:
		var sx := 4 + i * 23
		var sh := 8 + (i % 4) * 4
		draw_rect(Rect2(sx, 0, 4 + (i % 2), sh), Color("4a4868"))
		draw_rect(Rect2(sx - 1, sh - 2, 6 + (i % 2), 2), Color("6a6888"))
	# Torch glow pools.
	var glow := Vector2(60, 70)
	for r in [28, 18, 10]:
		draw_circle(glow, float(r), Color("ff9040", 0.04))
	draw_circle(Vector2(180, 65), 16.0, Color("6090ff", 0.05))
	# Crystal clusters.
	for i in 5:
		var cx := 20 + i * 42
		var pulse := 0.45 + sin(_time * 2.5 + i) * 0.25
		draw_rect(Rect2(cx, 98, 3, 10), Color("5a5878"))
		draw_rect(Rect2(cx - 1, 96, 5, 3), Color("8ad8ff", pulse))
		draw_rect(Rect2(cx + 1, 93, 2, 4), Color("c8f0ff", pulse * 0.8))
	_tile_ground(104, Color("3a3848"))
	_draw_rock_floor(106)
	_draw_battle_floor()


func _draw_ranger() -> void:
	_paint_sky(func(t): return Color("2a3868").lerp(Color("8ab0e0"), t))
	_draw_sun(Vector2(200, 24), Color("ffe8a0", 0.7))
	_draw_cloud(Vector2(30 + _cloud_drift * 0.2, 18), 0, 0.45)
	# Distant standing stones.
	for i in 4:
		var sx := 20 + i * 55
		draw_rect(Rect2(sx, 58, 4, 14), Color("5a6070", 0.5))
	# Trial arena floor.
	draw_circle(Vector2(120, 100), 54, Color("2a3040", 0.4))
	for r in [48, 40, 32]:
		var pulse := 0.35 + sin(_time * 1.6) * 0.15
		draw_arc(Vector2(120, 100), float(r), 0, TAU, 40, Color("5ad4c8", pulse * 0.4), 1.5, true)
	draw_arc(Vector2(120, 100), 48.0, 0, TAU, 48, Color("ffe08a", 0.5), 2.0, true)
	# Rotating sigil nodes.
	for i in 4:
		var ang := i * TAU / 4.0 + _time * 0.2
		var p := Vector2(120, 100) + Vector2(cos(ang), sin(ang) * 0.55) * 44
		draw_rect(Rect2(p.x - 2, p.y - 10, 4, 14), Color("6a7088"))
		draw_rect(Rect2(p.x - 1, p.y - 12, 2, 3), Color("ffe08a", 0.8 + sin(_time * 3 + i) * 0.2))
	_tile_ground(108, Color("4a6848", 0.35))
	_scatter_tufts(110, 4)
	_draw_battle_floor()


func _draw_arena() -> void:
	_paint_sky(func(t): return Color("1a2848").lerp(Color("5070a8"), t))
	# Stadium rim lights.
	for i in 6:
		draw_rect(Rect2(8 + i * 38, 6, 6, 2), Color("fff0b0", 0.35 + sin(_time * 4 + i) * 0.15))
	# Crowd silhouettes.
	for i in 20:
		var cx := i * 12
		draw_rect(Rect2(cx, 52 + (i % 3), 8, 6), Color("1a2038", 0.6))
	# Battle mat.
	draw_rect(Rect2(0, 86, VIEW_W, 74), Color("3a4050"))
	for x in range(0, VIEW_W, 12):
		draw_line(Vector2(x, 86), Vector2(x, VIEW_H), Color("2a3040", 0.5))
	for y in range(86, VIEW_H, 12):
		draw_line(Vector2(0, y), Vector2(VIEW_W, y), Color("2a3040", 0.5))
	draw_rect(Rect2(16, 92, VIEW_W - 32, 2), Color("5ad4c8", 0.4))
	draw_rect(Rect2(16, VIEW_H - 18, VIEW_W - 32, 2), Color("5ad4c8", 0.4))


# ---- shared painters -------------------------------------------------------

func _sky_day(t: float) -> Color:
	if t < 0.55:
		return Color("4a90d8").lerp(Color("7eb8e8"), t / 0.55)
	if t < 0.85:
		var u := (t - 0.55) / 0.30
		return Color("7eb8e8").lerp(Color("b8e0a8"), u)
	return Color("b8e0a8").lerp(Color("d8f0b8"), (t - 0.85) / 0.15)


func _paint_sky(color_fn: Callable) -> void:
	for y in HORIZON:
		var t := float(y) / float(HORIZON - 1)
		draw_line(Vector2(0, y), Vector2(VIEW_W, y), color_fn.call(t))


func _draw_sun(pos: Vector2, core: Color, glow_r: int = 10) -> void:
	for r in range(glow_r, 0, -2):
		var a := 0.06 + float(glow_r - r) * 0.035
		draw_circle(pos, float(r), Color(core.r, core.g, core.b, a))
	draw_circle(pos, 5.0, core)
	draw_circle(pos, 3.0, Color(1, 1, 1, 0.9))


func _draw_hill(cx: float, base_y: float, radius: float, dark: Color, light: Color) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := PI + float(i) / 27.0 * PI
		pts.append(Vector2(cx + cos(a) * radius, base_y + sin(a) * radius * 0.36))
	pts.append(Vector2(cx + radius, base_y + 32))
	pts.append(Vector2(cx - radius, base_y + 32))
	draw_colored_polygon(pts, light)
	# Shadow side.
	var shade := PackedVector2Array([
		Vector2(cx - radius * 0.2, base_y - 4),
		Vector2(cx + radius * 0.55, base_y - 2),
		Vector2(cx + radius, base_y + 32),
		Vector2(cx - radius * 0.1, base_y + 28),
	])
	draw_colored_polygon(shade, Color(dark.r, dark.g, dark.b, 0.55))
	draw_line(Vector2(cx - radius * 0.3, base_y - 3), Vector2(cx + radius * 0.05, base_y - 6), Color(1, 1, 1, 0.1))


func _tile_ground(y: int, tint: Color = Color.WHITE) -> void:
	if _grass_tex:
		var tw := _grass_tex.get_width()
		var th := _grass_tex.get_height()
		for row in ceili(float(VIEW_H - y) / float(th)):
			for x in range(0, VIEW_W, tw):
				draw_texture_rect(_grass_tex, Rect2(x, y + row * th, tw, th), false)
	if tint != Color.WHITE:
		draw_rect(Rect2(0, y, VIEW_W, VIEW_H - y), tint)


func _scatter_tufts(base_y: int, count: int) -> void:
	for i in count:
		_draw_tuft(Vector2(12 + i * 26 + (i % 2) * 8, base_y + (i % 3) * 3))


func _scatter_flowers(base_y: int, count: int) -> void:
	var cols := [Color("ff7ab0"), Color("ffd060"), Color("78d8ff"), Color("c878ff")]
	for i in count:
		_draw_flower(Vector2(20 + i * 38, base_y + (i % 2) * 4), cols[i % cols.size()])


func _draw_tuft(pos: Vector2) -> void:
	if _tall_grass_tex:
		draw_texture_rect(_tall_grass_tex, Rect2(pos.x - 3, pos.y - 8, 12, 12), false)
	else:
		draw_rect(Rect2(pos.x, pos.y - 4, 2, 4), Color("3a7848"))
		draw_rect(Rect2(pos.x + 2, pos.y - 6, 2, 6), Color("4a9858"))


func _draw_flower(pos: Vector2, col: Color) -> void:
	draw_rect(Rect2(pos.x, pos.y, 1, 2), Color("3a6848"))
	draw_rect(Rect2(pos.x - 1, pos.y - 1, 3, 1), col)
	draw_rect(Rect2(pos.x, pos.y - 2, 1, 1), Color("fff0a8"))


func _draw_cactus(x: float, base_y: float) -> void:
	draw_rect(Rect2(x, base_y, 4, 14), Color("3a7848"))
	draw_rect(Rect2(x - 3, base_y + 4, 3, 2), Color("4a8858"))
	draw_rect(Rect2(x + 4, base_y + 6, 3, 2), Color("4a8858"))
	draw_rect(Rect2(x + 1, base_y - 2, 2, 3), Color("4a9858"))


func _draw_dune_ripples(y: int) -> void:
	for x in range(0, VIEW_W, 14):
		draw_rect(Rect2(x + int(sin(_time + x * 0.1) * 2), y, 10, 1), Color("c8a848", 0.35))


func _draw_tree(x: float, base_y: float, scale: float) -> void:
	var w := 6.0 * scale
	draw_rect(Rect2(x, base_y, w, 18 * scale), Color("3a2818"))
	draw_rect(Rect2(x - 6 * scale, base_y - 12 * scale, 18 * scale, 12 * scale), Color("2a5838"))
	draw_rect(Rect2(x - 2 * scale, base_y - 18 * scale, 10 * scale, 8 * scale), Color("3a7048"))


func _draw_rock_floor(y: int) -> void:
	for i in 12:
		var rx := 8 + i * 19
		draw_rect(Rect2(rx, y + (i % 2), 6 + (i % 3), 3), Color("4a4858", 0.6))


func _draw_battle_floor() -> void:
	# Subtle darken strip where the UI bar sits so menus read clearly.
	draw_rect(Rect2(0, 104, VIEW_W, 6), Color(0, 0, 0, 0.12))
	draw_rect(Rect2(0, VIEW_H - 4, VIEW_W, 4), Color("1a3020", 0.25))


func _vignette() -> void:
	draw_rect(Rect2(0, 0, VIEW_W, 8), Color(0, 0, 0, 0.15))
	draw_rect(Rect2(0, 0, 6, VIEW_H), Color(0, 0, 0, 0.08))
	draw_rect(Rect2(VIEW_W - 6, 0, 6, VIEW_H), Color(0, 0, 0, 0.08))


# ---- pixel clouds (from title_backdrop) ------------------------------------

func _draw_cloud(origin: Vector2, style: int, alpha: float) -> void:
	var styles := [
		{
			"shadow": [[0, 7, 14, 2], [12, 5, 12, 2], [4, 8, 26, 3]],
			"body": [[1, 6, 12, 2], [11, 4, 14, 3], [3, 7, 26, 3], [16, 2, 8, 2]],
			"highlight": [[2, 5, 5, 1], [13, 3, 6, 1], [18, 2, 3, 1]],
			"wisp": [[28, 6, 4, 1]],
		},
		{
			"shadow": [[0, 6, 18, 2], [6, 7, 28, 3]],
			"body": [[1, 5, 16, 2], [14, 3, 18, 3], [5, 6, 28, 3]],
			"highlight": [[3, 4, 6, 1], [17, 2, 7, 1]],
			"wisp": [[32, 5, 4, 1]],
		},
		{
			"shadow": [[0, 5, 10, 2], [2, 6, 14, 2]],
			"body": [[1, 4, 8, 2], [5, 2, 12, 3], [2, 5, 14, 2]],
			"highlight": [[2, 3, 3, 1], [7, 2, 4, 1]],
			"wisp": [],
		},
	]
	var data: Dictionary = styles[style % styles.size()]
	var sh_col := Color("4a6898", 0.38 * alpha)
	var body_col := Color("eef6ff", 0.9 * alpha)
	var hi_col := Color("ffffff", alpha)
	for r: Array in data.get("shadow", []):
		_cloud_rect(origin, r, sh_col, Vector2(1, 1))
	for r: Array in data.get("body", []):
		_cloud_rect(origin, r, body_col)
	for r: Array in data.get("highlight", []):
		_cloud_rect(origin, r, hi_col)
	for r: Array in data.get("wisp", []):
		_cloud_rect(origin, r, Color("f4faff", 0.65 * alpha))


func _cloud_rect(origin: Vector2, rect: Array, col: Color, offset: Vector2 = Vector2.ZERO) -> void:
	draw_rect(Rect2(origin + Vector2(rect[0], rect[1]) + offset, Vector2(rect[2], rect[3])), col)
