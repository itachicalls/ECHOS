extends Control
## Painted cinematic backgrounds for intro cutscenes.
## Each visual is a coherent, layered scene (sky, celestial body, silhouette
## layers, ground plane). Hero sprites + FX are drawn on top by other layers.

const VIEW_W := 240
const VIEW_H := 160

var _visual := "chorus"
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(VIEW_W, VIEW_H)
	set_process(true)


func set_visual(v: String) -> void:
	_visual = v
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	match _visual:
		"chorus": _paint_chorus()
		"fracture": _paint_fracture()
		"harmons": _paint_harmons()
		"disturbance": _paint_disturbance()
		"veil": _paint_veil()
		"journey": _paint_journey()
		"town": _paint_town()
		"bond": _paint_bond()
		"depart": _paint_depart()
		_: _paint_chorus()


# ---- scenes ----------------------------------------------------------------

func _paint_chorus() -> void:
	# Serene sunrise valley — the world in harmony.
	_vgrad(0, 108, Color("241a4a"), Color("f0a860"))
	_stars(0.5)
	_sun(Vector2(120, 60), 16, Color("fff2c0"), Color("ffd070"))
	_mountains(78, Color("6a5a8a"), Color("54487a"))
	_hill(96, 8, 70.0, Color("3a6a52"), 0.0)
	_hill(112, 10, 54.0, Color("2c5442"), 1.6)
	_ground(120, Color("245038"), Color("2e6244"))


func _paint_fracture() -> void:
	# The world breaks — blood-red sky, shattered land.
	_vgrad(0, 108, Color("2a0c16"), Color("a83020"))
	_sun(Vector2(120, 54), 20, Color("ff9060"), Color("d84828"))
	_mountains(80, Color("3a1420"), Color("2a0e18"))
	_hill(100, 9, 60.0, Color("34121c"), 0.8)
	_ground(118, Color("1e0a12"), Color("2c1018"))
	# Jagged fracture chasm across the ground.
	var col := Color("ff7a3c", 0.85)
	var y := 128.0
	var x := 0.0
	var pts := PackedVector2Array()
	pts.append(Vector2(0, y))
	var rng := 0
	while x < VIEW_W:
		x += 16
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var dy := float(rng % 9) - 4.0
		pts.append(Vector2(x, y + dy))
	for i in pts.size() - 1:
		draw_line(pts[i], pts[i + 1], col, 2.0)
	for i in pts.size() - 1:
		draw_line(pts[i], pts[i + 1] + Vector2(0, 3), Color("ffd070", 0.4), 1.0)


func _paint_harmons() -> void:
	# Bright hopeful meadow — home of the Harmons.
	_vgrad(0, 104, Color("3f7fc8"), Color("bfe4c4"))
	_clouds()
	_sun(Vector2(196, 30), 12, Color("fffbe0"), Color("ffe89a"))
	_hill(90, 10, 66.0, Color("4a9a5c"), 0.4)
	_hill(104, 12, 48.0, Color("3c8850"), 2.1)
	_ground(116, Color("3a8a4e"), Color("46a058"))


func _paint_disturbance() -> void:
	# Dusk — distant ruins pulse with a strange signal.
	_vgrad(0, 106, Color("2a2650"), Color("d87a52"))
	_stars(0.35)
	_mountains(76, Color("4a3a5e"), Color("382c4c"))
	_ruins(Vector2(120, 78))
	_hill(98, 8, 58.0, Color("2e2840"), 1.1)
	_ground(116, Color("241f36"), Color("2e2842"))


func _paint_veil() -> void:
	# Cold misty night at the valley's edge — the Veil watches.
	_vgrad(0, 110, Color("0c0a1e"), Color("2a2444"))
	_moon(Vector2(186, 34), 12)
	_stars(0.6)
	# Silhouetted dead trees.
	for tx in [26, 58, 200, 214]:
		_dead_tree(float(tx), 112.0)
	_hill(104, 6, 64.0, Color("14101f"), 0.5)
	_ground(120, Color("0e0a1a"), Color("161226"))
	# Drifting mist bands.
	for i in 3:
		var my := 84.0 + i * 12.0
		var mx := fmod(_t * (6.0 + i * 3.0), VIEW_W + 80.0) - 40.0
		draw_rect(Rect2(mx, my, 70, 6), Color("8a7ac8", 0.06))
		draw_rect(Rect2(mx - 90, my + 3, 70, 5), Color("8a7ac8", 0.05))


func _paint_journey() -> void:
	# Golden hour — arriving at the village of Harmona Rest.
	_vgrad(0, 108, Color("3a3a6e"), Color("f6c060"))
	_sun(Vector2(60, 52), 18, Color("fff0c0"), Color("ffcf70"))
	_mountains(80, Color("6a5074"), Color("543f62"))
	_village(112.0)
	_ground(120, Color("2c4636"), Color("386048"))


func _paint_town() -> void:
	# Warm daytime village square.
	_vgrad(0, 104, Color("5a95d4"), Color("cfe8cf"))
	_clouds()
	_sun(Vector2(206, 28), 11, Color("fffbe0"), Color("ffe89a"))
	_village(108.0)
	_ground(116, Color("3a7a48"), Color("46925a"))


func _paint_bond() -> void:
	# Intimate close moment — soft radial warmth, dark cinematic vignette.
	_vgrad(0, VIEW_H, Color("101830"), Color("0a1020"))
	var c := Vector2(120, 78)
	for r in range(70, 0, -6):
		var a := 0.10 * (1.0 - float(r) / 70.0)
		draw_circle(c, float(r), Color("ffd88a", a))
	_ground(122, Color("1a2238"), Color("222c46"))


func _paint_depart() -> void:
	# Sunrise — the gate north to Route 1 opens.
	_vgrad(0, 108, Color("2e2a5c"), Color("ffcf7a"))
	_stars(0.25)
	_sun(Vector2(120, 66), 22, Color("fff4d0"), Color("ffd884"))
	_mountains(82, Color("5a4a72"), Color("463860"))
	_hill(100, 7, 60.0, Color("2e5a42"), 0.9)
	_ground(118, Color("245038"), Color("2e6244"))
	# Stone gate arch framing the path north.
	_gate(Vector2(120, 118))


# ---- painter helpers -------------------------------------------------------

func _vgrad(y0: int, y1: int, top: Color, bottom: Color) -> void:
	# 1px filled rows (draw_rect, not draw_line — avoids scan-line banding).
	var span := maxi(1, y1 - y0)
	for y in range(y0, y1):
		var t := float(y - y0) / float(span)
		draw_rect(Rect2(0, y, VIEW_W, 1), top.lerp(bottom, t))


func _ground(y: int, dark: Color, light: Color) -> void:
	draw_rect(Rect2(0, y, VIEW_W, VIEW_H - y), dark)
	draw_rect(Rect2(0, y, VIEW_W, 3), light)
	# Faint texture speckle.
	var rng := 777
	for i in 60:
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var px := rng % VIEW_W
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var py := y + 4 + rng % maxi(1, VIEW_H - y - 4)
		draw_rect(Rect2(px, py, 1, 1), Color(light.r, light.g, light.b, 0.25))


func _hill(base_y: float, amp: float, wl: float, col: Color, phase: float) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, VIEW_H))
	var x := 0.0
	while x <= VIEW_W:
		pts.append(Vector2(x, base_y + sin(x / wl + phase) * amp))
		x += 6.0
	pts.append(Vector2(VIEW_W, base_y))
	pts.append(Vector2(VIEW_W, VIEW_H))
	draw_colored_polygon(pts, col)


func _mountains(base_y: float, light: Color, dark: Color) -> void:
	var peaks := [30, 84, 138, 196, 236]
	var heights := [34, 48, 30, 44, 30]
	for i in peaks.size():
		var cx := float(peaks[i])
		var h := float(heights[i])
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - h, base_y), Vector2(cx, base_y - h), Vector2(cx + h, base_y),
		]), dark)
		# Lit left face.
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - h, base_y), Vector2(cx, base_y - h), Vector2(cx, base_y),
		]), light)
		# Snow cap.
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - h * 0.28, base_y - h * 0.72), Vector2(cx, base_y - h),
			Vector2(cx + h * 0.28, base_y - h * 0.72),
		]), Color(1, 1, 1, 0.28))


func _sun(pos: Vector2, r: int, core: Color, glow: Color) -> void:
	for gr in range(r + 22, r, -3):
		var a := 0.05 + float(r + 22 - gr) * 0.012
		draw_circle(pos, float(gr), Color(glow.r, glow.g, glow.b, a))
	draw_circle(pos, float(r), glow)
	draw_circle(pos, float(r) * 0.68, core)


func _moon(pos: Vector2, r: int) -> void:
	for gr in range(r + 12, r, -2):
		var a := 0.04 + float(r + 12 - gr) * 0.02
		draw_circle(pos, float(gr), Color("cfe0ff", a))
	draw_circle(pos, float(r), Color("e8f0ff"))
	draw_circle(pos + Vector2(r * 0.35, -r * 0.2), float(r) * 0.82, Color("0c0a1e", 0.0))
	draw_circle(pos + Vector2(3, -2), float(r) * 0.9, Color("dbe6ff"))
	draw_circle(pos + Vector2(-2, 2), 2.0, Color("c2d2f0", 0.6))


func _stars(intensity: float) -> void:
	var rng := 4242
	for i in 46:
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var x := rng % VIEW_W
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var y := rng % 70
		var tw := 0.5 + 0.5 * sin(_t * 2.0 + i)
		draw_rect(Rect2(x, y, 1, 1), Color(1, 1, 1, intensity * (0.4 + tw * 0.5)))


func _clouds() -> void:
	var drift := fmod(_t * 5.0, VIEW_W + 80.0)
	_cloud(Vector2(-30 + drift, 20), 0.9)
	_cloud(Vector2(120 + fmod(drift * 0.7, VIEW_W + 60), 14), 0.7)
	_cloud(Vector2(60 + fmod(drift * 1.2, VIEW_W + 70), 34), 0.6)


func _cloud(o: Vector2, a: float) -> void:
	var body := Color("f4f8ff", 0.9 * a)
	var shade := Color("c8d8ee", 0.85 * a)
	draw_rect(Rect2(o.x, o.y + 3, 34, 5), shade)
	draw_rect(Rect2(o.x + 3, o.y, 14, 8), body)
	draw_rect(Rect2(o.x + 14, o.y + 1, 12, 7), body)
	draw_rect(Rect2(o.x + 1, o.y + 3, 32, 4), body)


func _ruins(base: Vector2) -> void:
	# Broken columns + a cracked arch, pulsing signal glow.
	var pulse := 0.4 + 0.35 * sin(_t * 2.2)
	var stone := Color("2a2440")
	var stone_lit := Color("3c3458")
	for dx in [-40, -22, 20, 38]:
		var h := 26 + absi(dx) % 10
		draw_rect(Rect2(base.x + dx - 3, base.y - h, 6, h), stone)
		draw_rect(Rect2(base.x + dx - 3, base.y - h, 3, h), stone_lit)
	# Central broken arch.
	draw_rect(Rect2(base.x - 12, base.y - 34, 5, 34), stone)
	draw_rect(Rect2(base.x + 7, base.y - 34, 5, 34), stone)
	draw_rect(Rect2(base.x - 12, base.y - 36, 24, 4), stone)
	# Signal glow between the pillars.
	draw_circle(Vector2(base.x, base.y - 18), 10.0, Color("ff6088", 0.12 * pulse))
	draw_circle(Vector2(base.x, base.y - 18), 3.0, Color("ffd166", pulse))


func _village(base_y: float) -> void:
	# Row of cozy silhouetted houses with warm lit windows.
	var win := 0.7 + 0.3 * sin(_t * 3.0)
	var houses := [
		{"x": 18, "w": 34, "h": 30},
		{"x": 62, "w": 28, "h": 24},
		{"x": 150, "w": 30, "h": 26},
		{"x": 190, "w": 38, "h": 34},
	]
	for h in houses:
		var x := float(h.x)
		var w := float(h.w)
		var ht := float(h.h)
		var top := base_y - ht
		draw_rect(Rect2(x, top, w, ht), Color("2a2236"))
		# Roof.
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 3, top), Vector2(x + w * 0.5, top - 10), Vector2(x + w + 3, top),
		]), Color("3a2c3e"))
		# Warm windows.
		draw_rect(Rect2(x + w * 0.24, top + ht * 0.35, 4, 5), Color("ffc766", win))
		draw_rect(Rect2(x + w * 0.6, top + ht * 0.35, 4, 5), Color("ffc766", win * 0.9))


func _dead_tree(x: float, base_y: float) -> void:
	var col := Color("0a0814")
	draw_rect(Rect2(x - 1, base_y - 30, 3, 30), col)
	draw_line(Vector2(x, base_y - 20), Vector2(x - 8, base_y - 30), col, 2.0)
	draw_line(Vector2(x, base_y - 24), Vector2(x + 9, base_y - 32), col, 2.0)
	draw_line(Vector2(x, base_y - 14), Vector2(x - 6, base_y - 20), col, 1.0)


func _gate(base: Vector2) -> void:
	var stone := Color("42364e")
	var stone_lit := Color("564764")
	# Two pillars + lintel forming an arch, with bright dawn light in the gap.
	draw_rect(Rect2(base.x - 26, base.y - 44, 10, 44), stone)
	draw_rect(Rect2(base.x + 16, base.y - 44, 10, 44), stone)
	draw_rect(Rect2(base.x - 26, base.y - 44, 4, 44), stone_lit)
	draw_rect(Rect2(base.x + 16, base.y - 44, 4, 44), stone_lit)
	draw_rect(Rect2(base.x - 30, base.y - 50, 60, 8), stone)
	draw_rect(Rect2(base.x - 30, base.y - 50, 60, 3), stone_lit)
	# Glowing path through the gate.
	var glow := 0.5 + 0.2 * sin(_t * 2.0)
	draw_rect(Rect2(base.x - 15, base.y - 42, 30, 42), Color("ffe6a0", 0.14 * glow))
