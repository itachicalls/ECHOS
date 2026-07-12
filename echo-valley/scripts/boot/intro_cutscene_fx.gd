extends Control
## Animated atmospheric VFX drawn on top of the painted scene + hero sprites:
## motes, light rays, chorus rings, embers, fog. Keeps each slide feeling alive.

const VIEW_W := 240
const VIEW_H := 160

var _visual := ""
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
		"chorus": _fx_chorus()
		"fracture": _fx_fracture()
		"harmons": _fx_harmons()
		"disturbance": _fx_disturbance()
		"veil": _fx_veil()
		"journey": _fx_journey()
		"town": _fx_town()
		"bond": _fx_bond()
		"depart": _fx_depart()


# ---- per-scene fx ----------------------------------------------------------

func _fx_chorus() -> void:
	var c := Vector2(120, 60)
	for k in 3:
		var r := fmod(_t * 14.0 + k * 26.0, 80.0)
		var a := (1.0 - r / 80.0) * 0.3
		draw_arc(c, r, 0, TAU, 40, Color("ffe6a0", a), 1.5, true)
	_rising_motes(18, Color("fff0b0"), 0.7)


func _fx_fracture() -> void:
	_falling_embers(16, Color("ff7a3c"))
	# Soft pulse — no full-screen flash jolt.
	var pulse := 0.04 + 0.03 * maxf(0.0, sin(_t * 0.9))
	draw_rect(Rect2(0, 40, VIEW_W, 40), Color("ff5030", pulse))


func _fx_harmons() -> void:
	# Soft resonance auras around the trio + rising music motes.
	for p in [Vector2(64, 96), Vector2(120, 88), Vector2(176, 96)]:
		var pulse := 0.18 + 0.1 * sin(_t * 2.2 + p.x)
		draw_arc(p, 20.0, 0, TAU, 28, Color("7ee8d8", pulse), 1.0, true)
	_rising_motes(16, Color("bff0e0"), 0.8)


func _fx_disturbance() -> void:
	var c := Vector2(120, 60)
	for k in 3:
		var r := fmod(_t * 18.0 + k * 22.0, 66.0)
		var a := (1.0 - r / 66.0) * 0.35
		draw_arc(c, r, 0, TAU, 36, Color("ff6088", a), 1.5, true)
	_drifting_dust(14, Color("d8a0b0"))


func _fx_veil() -> void:
	# Cold vertical light streaks + purple motes.
	for i in 6:
		var x := 20.0 + i * 38.0 + sin(_t * 0.4 + i) * 4.0
		draw_rect(Rect2(x, 0, 2, VIEW_H), Color("6a5acd", 0.05))
	_drifting_dust(16, Color("b6a8ee"))
	# Ghost glow center.
	var g := 0.14 + 0.08 * sin(_t * 2.0)
	draw_circle(Vector2(120, 76), 18.0, Color("cfe0ff", g))


func _fx_journey() -> void:
	_light_rays(Vector2(60, 52), Color("fff0c0"))
	_rising_motes(14, Color("ffe0a0"), 0.6)


func _fx_town() -> void:
	_drifting_dust(12, Color("fff4c0"))


func _fx_bond() -> void:
	var a := Vector2(80, 96)
	var b := Vector2(140, 80)
	# Bond thread of light between partner and Harmon.
	for k in 4:
		var pulse := 0.5 + 0.5 * sin(_t * 2.4 + k)
		var r := fmod(_t * 12.0 + k * 18.0, 60.0)
		draw_arc(b, r, 0, TAU, 32, Color("ffd88a", (1.0 - r / 60.0) * 0.3), 1.0, true)
		var mid := a.lerp(b, fmod(_t * 0.5 + k * 0.25, 1.0))
		draw_circle(mid, 1.5, Color("fff2c0", pulse))
	_rising_motes(12, Color("ffe6b0"), 0.5)


func _fx_depart() -> void:
	_light_rays(Vector2(120, 66), Color("ffe6a0"))
	_rising_motes(16, Color("fff0c0"), 0.7)


# ---- particle primitives ---------------------------------------------------

func _rising_motes(count: int, col: Color, base_a: float) -> void:
	var rng := 313
	for i in count:
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var x := float(rng % VIEW_W)
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var phase := float(rng % 100) / 100.0
		var life := fmod(_t * 0.28 + phase, 1.0)
		var y := 130.0 - life * 96.0
		var wob := sin(_t * 1.5 + i) * 4.0
		var a := base_a * sin(life * PI)
		draw_rect(Rect2(x + wob, y, 1, 1), Color(col.r, col.g, col.b, a))
		if i % 3 == 0:
			draw_rect(Rect2(x + wob, y - 1, 1, 1), Color(col.r, col.g, col.b, a * 0.5))


func _falling_embers(count: int, col: Color) -> void:
	var rng := 991
	for i in count:
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var x := float(rng % VIEW_W)
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var phase := float(rng % 100) / 100.0
		var life := fmod(_t * 0.4 + phase, 1.0)
		var y := life * 130.0
		var wob := sin(_t * 2.0 + i) * 6.0
		var a := 0.8 * (1.0 - life * 0.5)
		draw_rect(Rect2(x + wob, y, 1, 2), Color(col.r, col.g, col.b, a))


func _drifting_dust(count: int, col: Color) -> void:
	var rng := 555
	for i in count:
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var y := float(rng % 120)
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var phase := float(rng % 100) / 100.0
		var x := fmod(_t * (8.0 + phase * 6.0) + phase * VIEW_W, VIEW_W)
		var a := 0.25 + 0.15 * sin(_t * 1.5 + i)
		draw_rect(Rect2(x, y + sin(_t + i) * 2.0, 1, 1), Color(col.r, col.g, col.b, a))


func _light_rays(origin: Vector2, col: Color) -> void:
	for i in 5:
		var ang := -1.0 + i * 0.28 + sin(_t * 0.3) * 0.05
		var len := 120.0
		var dir := Vector2(cos(ang), sin(ang)) * len
		var a := 0.05 + 0.03 * sin(_t * 0.8 + i)
		draw_colored_polygon(PackedVector2Array([
			origin,
			origin + dir + Vector2(-4, 0),
			origin + dir + Vector2(4, 0),
		]), Color(col.r, col.g, col.b, a))
