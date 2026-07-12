extends Control
## Route-themed battle scenery drawn behind sprites and UI.

const VIEW_W := 240
const VIEW_H := 160

var _theme := "meadow"
var _is_ranger := false
var _time := 0.0
var _grass_tex: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(VIEW_W, VIEW_H)
	_grass_tex = load("res://assets/kenney/gen/grass_field.png") as Texture2D
	set_process(true)


func configure(map_id: String, is_ranger: bool, kind: String) -> void:
	_is_ranger = is_ranger
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
	queue_redraw()


func _draw() -> void:
	match _theme:
		"desert": _draw_desert()
		"jungle": _draw_jungle()
		"cave": _draw_cave()
		"wood": _draw_wood()
		"ranger": _draw_ranger()
		"arena": _draw_arena()
		_: _draw_meadow()


func _sky_band(y: int, top: Color, bottom: Color) -> Color:
	var t := float(y) / 71.0
	return top.lerp(bottom, t)


func _draw_meadow() -> void:
	for y in 72:
		draw_line(Vector2(0, y), Vector2(VIEW_W, y), _sky_band(y, Color("7eb8e8"), Color("dff2c6")))
	_draw_hill(60, 78, 70, Color("5aad5a"))
	_draw_hill(190, 82, 55, Color("4a9d4a"))
	_tile_grass(88)


func _draw_wood() -> void:
	for y in 72:
		draw_line(Vector2(0, y), Vector2(VIEW_W, y), _sky_band(y, Color("5a88b0"), Color("a8d8a0")))
	for i in 5:
		var tx := 18 + i * 44
		_draw_tree(tx, 52 + (i % 2) * 4)
	_draw_hill(120, 80, 90, Color("3d8a48"))
	_tile_grass(90)


func _draw_desert() -> void:
	for y in 72:
		draw_line(Vector2(0, y), Vector2(VIEW_W, y), _sky_band(y, Color("f0a860"), Color("ffe8b0")))
	draw_rect(Rect2(0, 72, VIEW_W, 34), Color("e8c878"))
	for i in 4:
		var dx := sin(_time * 1.2 + i) * 0.5
		draw_line(Vector2(0, 78 + i * 6), Vector2(VIEW_W, 78 + i * 6 + dx), Color("d8b868", 0.35))
	_draw_dune(50, 86, 60)
	_draw_dune(170, 90, 48)
	draw_rect(Rect2(0, 100, VIEW_W, 60), Color("d4b060"))
	for i in 3:
		_draw_cactus(30 + i * 70, 96)


func _draw_jungle() -> void:
	for y in 72:
		draw_line(Vector2(0, y), Vector2(VIEW_W, y), _sky_band(y, Color("2a5848"), Color("4a8868")))
	draw_rect(Rect2(0, 0, VIEW_W, 28), Color("1a3828", 0.55))
	for i in 6:
		draw_rect(Rect2(8 + i * 38, 4 + (i % 2), 28, 6), Color("2d6040", 0.8))
	for i in 4:
		draw_rect(Rect2(20 + i * 52, 18, 2, 14 + (i % 3) * 4), Color("3a7848"))
	_tile_grass(92)
	for i in 5:
		draw_rect(Rect2(10 + i * 42, 100 + (i % 2), 3, 5), Color("2d7040"))


func _draw_cave() -> void:
	draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color("1a1828"))
	for y in 40:
		var t := float(y) / 39.0
		draw_line(Vector2(0, y), Vector2(VIEW_W, y), Color("2a2840").lerp(Color("3a3858"), t))
	for i in 8:
		draw_rect(Rect2(6 + i * 28, 2 + (i % 3), 4 + (i % 2) * 2, 10 + (i % 4)), Color("4a4868"))
	draw_rect(Rect2(0, 100, VIEW_W, 60), Color("2a2838"))
	for i in 5:
		var cx := 24 + i * 40
		draw_rect(Rect2(cx, 104, 3, 8), Color("5a5878"))
		draw_rect(Rect2(cx - 1, 102, 5, 2), Color("8ad8ff", 0.5 + sin(_time * 2 + i) * 0.2))


func _draw_ranger() -> void:
	for y in 72:
		draw_line(Vector2(0, y), Vector2(VIEW_W, y), _sky_band(y, Color("4a6898"), Color("8ab0d8")))
	# Stone trial circle.
	draw_circle(Vector2(120, 108), 52, Color("3a4050", 0.35))
	draw_arc(Vector2(120, 108), 46, 0, TAU, 48, Color("ffe08a", 0.55), 2.0, true)
	draw_arc(Vector2(120, 108), 38, 0, TAU, 36, Color("5ad4c8", 0.35), 1.0, true)
	for i in 4:
		var ang := i * TAU / 4.0 + _time * 0.15
		var p := Vector2(120, 108) + Vector2(cos(ang), sin(ang)) * 42
		draw_rect(Rect2(p.x - 3, p.y - 8, 6, 16), Color("5a6078"))
		draw_rect(Rect2(p.x - 2, p.y - 10, 4, 3), Color("8a90a8"))
	draw_rect(Rect2(0, 112, VIEW_W, 48), Color("4a5848", 0.6))
	_tile_grass(112, Color("3a6848", 0.22))


func _draw_arena() -> void:
	for y in 72:
		draw_line(Vector2(0, y), Vector2(VIEW_W, y), _sky_band(y, Color("3a5088"), Color("7090c8")))
	draw_rect(Rect2(0, 88, VIEW_W, 72), Color("4a5060"))
	for x in range(0, VIEW_W, 16):
		draw_line(Vector2(x, 88), Vector2(x, 160), Color("3a4050", 0.4))
	for y in range(88, VIEW_H, 16):
		draw_line(Vector2(0, y), Vector2(VIEW_W, y), Color("3a4050", 0.4))


func _tile_grass(y: int, overlay := Color(0, 0, 0, 0)) -> void:
	if _grass_tex:
		var tw := _grass_tex.get_width()
		var th := _grass_tex.get_height()
		for row in ceili(float(VIEW_H - y) / float(th)):
			for x in range(0, VIEW_W, tw):
				draw_texture_rect(_grass_tex, Rect2(x, y + row * th, tw, th), false)
	if overlay.a > 0.0:
		draw_rect(Rect2(0, y, VIEW_W, VIEW_H - y), overlay)


func _draw_hill(cx: float, base_y: float, radius: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 25:
		var a := PI + float(i) / 24.0 * PI
		pts.append(Vector2(cx + cos(a) * radius, base_y + sin(a) * radius * 0.38))
	pts.append(Vector2(cx + radius, base_y + 28))
	pts.append(Vector2(cx - radius, base_y + 28))
	draw_colored_polygon(pts, col)


func _draw_dune(cx: float, base_y: float, radius: float) -> void:
	_draw_hill(cx, base_y, radius, Color("c8a850"))


func _draw_tree(x: float, base_y: float) -> void:
	draw_rect(Rect2(x, base_y, 6, 18), Color("4a3020"))
	draw_rect(Rect2(x - 6, base_y - 10, 18, 12), Color("2d6840"))
	draw_rect(Rect2(x - 2, base_y - 16, 10, 8), Color("3a7848"))


func _draw_cactus(x: float, base_y: float) -> void:
	draw_rect(Rect2(x, base_y, 4, 12), Color("3a7848"))
	draw_rect(Rect2(x - 3, base_y + 3, 3, 2), Color("4a8858"))
	draw_rect(Rect2(x + 4, base_y + 5, 3, 2), Color("4a8858"))
