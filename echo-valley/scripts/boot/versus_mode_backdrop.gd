extends Control
## Animated "VERSUS" showdown backdrop for the mode-select screen:
## a split blue/purple arena, two Harmons squaring off, a pulsing VS emblem,
## spotlights, clash sparks and drifting energy motes.

const TitleFonts := preload("res://scripts/ui/title_fonts.gd")

const VIEW_W := 240
const VIEW_H := 160
const FLOOR_Y := 104
const LEFT_BASE := Vector2(64, FLOOR_Y)
const RIGHT_BASE := Vector2(176, FLOOR_Y)

const C_BLUE := Color("4a9eff")
const C_PURPLE := Color("c49bff")

var _t := 0.0
var _left: TextureRect
var _right: TextureRect
var _vs: Label
var _clash := 0.0
var _lunge := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(VIEW_W, VIEW_H)
	_spawn_fighters()
	_spawn_vs()
	set_process(true)


func _spawn_fighters() -> void:
	var ids := _pick_two()
	_left = _make_fighter(ids[0], false)
	_right = _make_fighter(ids[1], true)


func _pick_two() -> Array:
	# Prefer a contrasting fire/water pair, else two random valid Harmons.
	var valid: Array = []
	for id in EchoCatalog.all_echo_ids():
		var def := EchoCatalog.get_echo(id)
		if def and ResourceLoader.exists(def.sprite_path):
			valid.append(id)
	if valid.size() < 2:
		return ["emberkit", "tideling"]
	valid.shuffle()
	return [valid[0], valid[1]]


func _make_fighter(id: String, face_left: bool) -> TextureRect:
	var def := EchoCatalog.get_echo(id)
	var tr := TextureRect.new()
	if def and ResourceLoader.exists(def.sprite_path):
		tr.texture = load(def.sprite_path)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.flip_h = face_left
	tr.size = Vector2(46, 46)
	tr.z_index = 2
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	return tr


func _spawn_vs() -> void:
	_vs = Label.new()
	_vs.text = "VS"
	_vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_vs.size = Vector2(60, 40)
	_vs.pivot_offset = Vector2(30, 20)
	_vs.position = Vector2(120, 62) - Vector2(30, 20)
	_vs.z_index = 3
	_vs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TitleFonts.apply(_vs, 20, Color("ffe08a"), Color("2a1030"), 3)
	add_child(_vs)


func _process(delta: float) -> void:
	_t += delta
	# Clash rhythm: they idle, then dash inward and recoil with a spark burst.
	var cycle := fmod(_t, 2.6)
	_lunge = 0.0
	_clash = 0.0
	if cycle > 1.55 and cycle < 2.0:
		var p := (cycle - 1.55) / 0.45
		_lunge = sin(p * PI) * 16.0
	if cycle > 1.72 and cycle < 1.94:
		_clash = 1.0 - absf(cycle - 1.83) / 0.11

	var bobL := sin(_t * 3.0) * 2.0
	var bobR := sin(_t * 3.0 + 1.2) * 2.0
	if _left:
		_left.position = LEFT_BASE + Vector2(_lunge - 23.0, bobL - 46.0)
	if _right:
		_right.position = RIGHT_BASE + Vector2(-_lunge - 23.0, bobR - 46.0)
	if _vs:
		var s := 1.0 + _clash * 0.5 + sin(_t * 2.2) * 0.06
		_vs.scale = Vector2(s, s)
		_vs.rotation = sin(_t * 1.6) * 0.06 + _clash * 0.1
	queue_redraw()


func _draw() -> void:
	# Base arena gradient.
	for y in VIEW_H:
		var t := float(y) / float(VIEW_H - 1)
		draw_rect(Rect2(0, y, VIEW_W, 1), Color("0a0e20").lerp(Color("161028"), t))

	var sway := sin(_t * 0.8) * 4.0
	var top_x := 132.0 + sway
	var bot_x := 108.0 - sway

	# Blue (CPU) side + purple (PvP) side, split by an angled seam.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 0), Vector2(top_x, 0), Vector2(bot_x, VIEW_H), Vector2(0, VIEW_H),
	]), Color(C_BLUE.r, C_BLUE.g, C_BLUE.b, 0.14))
	draw_colored_polygon(PackedVector2Array([
		Vector2(top_x, 0), Vector2(VIEW_W, 0), Vector2(VIEW_W, VIEW_H), Vector2(bot_x, VIEW_H),
	]), Color(C_PURPLE.r, C_PURPLE.g, C_PURPLE.b, 0.14))

	# Spotlight cones from the top corners sweeping the fighters.
	_spotlight(Vector2(18, -6), LEFT_BASE + Vector2(0, -20), C_BLUE)
	_spotlight(Vector2(VIEW_W - 18, -6), RIGHT_BASE + Vector2(0, -20), C_PURPLE)

	# Radial energy glow behind the VS.
	var center := Vector2(120, 62)
	var glow_r := 34.0 + _clash * 18.0
	for r in range(int(glow_r), 0, -5):
		var a := (1.0 - float(r) / glow_r) * (0.10 + _clash * 0.25)
		draw_circle(center, float(r), Color("ffe0a0", a))

	# Crackling seam of energy down the middle.
	_seam(top_x, bot_x)

	# Drifting energy motes on each side.
	_motes(true, C_BLUE)
	_motes(false, C_PURPLE)

	# Arena floor + colored ground glows under each fighter.
	draw_rect(Rect2(0, FLOOR_Y, VIEW_W, VIEW_H - FLOOR_Y), Color("0c0f1e"))
	draw_rect(Rect2(0, FLOOR_Y, VIEW_W, 2), Color("2a3050"))
	_floor_glow(LEFT_BASE + Vector2(_lunge, 0), C_BLUE)
	_floor_glow(RIGHT_BASE + Vector2(-_lunge, 0), C_PURPLE)

	# Clash burst: converging speed lines + white flash at the meeting point.
	if _clash > 0.01:
		var cp := Vector2(120, 70)
		for i in 12:
			var ang := i * TAU / 12.0
			var inner := cp + Vector2(cos(ang), sin(ang)) * (10.0 + (1.0 - _clash) * 30.0)
			var outer := cp + Vector2(cos(ang), sin(ang)) * (24.0 + _clash * 20.0)
			draw_line(inner, outer, Color("fff4d0", _clash * 0.8), 1.5)
		draw_circle(cp, 6.0 + _clash * 10.0, Color("ffffff", _clash * 0.5))


func _spotlight(from: Vector2, to: Vector2, col: Color) -> void:
	var dir := (to - from).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var flick := 0.05 + 0.02 * sin(_t * 3.0 + from.x)
	draw_colored_polygon(PackedVector2Array([
		from - perp * 3.0, from + perp * 3.0,
		to + perp * 22.0, to - perp * 22.0,
	]), Color(col.r, col.g, col.b, flick))


func _seam(top_x: float, bot_x: float) -> void:
	var segs := 10
	var prev := Vector2(top_x, 0)
	var rng := int(_t * 20.0)
	for i in range(1, segs + 1):
		var ty := float(i) / segs
		var base_x := lerpf(top_x, bot_x, ty)
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var jitter := float(rng % 11) - 5.0
		var p := Vector2(base_x + jitter, ty * VIEW_H)
		var a := 0.25 + 0.2 * sin(_t * 6.0 + i)
		draw_line(prev, p, Color("bfe0ff", a), 1.0)
		prev = p


func _motes(left_side: bool, col: Color) -> void:
	var rng := 131 if left_side else 977
	for i in 10:
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var phase := float(rng % 100) / 100.0
		var x0 := (10.0 + phase * 90.0) if left_side else (140.0 + phase * 90.0)
		var y := fmod(_t * (10.0 + phase * 8.0) + phase * VIEW_H, float(FLOOR_Y))
		var a := 0.2 + 0.2 * sin(_t * 2.0 + i)
		draw_rect(Rect2(x0 + sin(_t + i) * 3.0, FLOOR_Y - y, 1, 1), Color(col.r, col.g, col.b, a))


func _floor_glow(feet: Vector2, col: Color) -> void:
	for k in 3:
		var rx := 20.0 - k * 4.0
		var a := 0.12 + 0.05 * sin(_t * 3.0)
		var pts := PackedVector2Array()
		for i in 18:
			var ang := float(i) / 18.0 * TAU
			pts.append(feet + Vector2(cos(ang) * rx, sin(ang) * rx * 0.28))
		draw_colored_polygon(pts, Color(col.r, col.g, col.b, a))
