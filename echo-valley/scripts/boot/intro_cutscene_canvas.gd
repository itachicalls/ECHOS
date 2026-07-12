extends Control
## Draws animated visuals for each intro cutscene slide.

var _parent: Node


func _ready() -> void:
	_parent = get_parent()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _parent == null or not _parent.has_method("get_visual"):
		return
	var visual := String(_parent.call("get_visual"))
	var t := float(_parent.call("get_anim_t"))
	var starter := String(_parent.call("get_starter_id"))
	match visual:
		"chorus": _draw_chorus(t)
		"fracture": _draw_fracture(t)
		"harmons": _draw_harmons(t)
		"disturbance": _draw_disturbance(t)
		"veil": _draw_veil(t)
		"journey": _draw_journey(t)
		"town": _draw_town(t)
		"bond": _draw_bond(t, starter)
		"depart": _draw_depart(t)
		_: _draw_chorus(t)


func _draw_chorus(t: float) -> void:
	var center := Vector2(120, 58)
	for r in [38, 28, 18]:
		var pulse := 0.35 + sin(t * 1.4 + r * 0.1) * 0.15
		draw_arc(center, float(r), 0, TAU, 48, Color("5ad4c8", pulse), 1.5, true)
	for i in 8:
		var ang := i * TAU / 8.0 + t * 0.35
		var p := center + Vector2(cos(ang), sin(ang)) * 30.0
		draw_circle(p, 3.0, Color("fff0b0", 0.75 + sin(t * 2 + i) * 0.2))
	draw_circle(center, 6.0, Color("ffe08a", 0.9))
	# Linked threads.
	for i in 8:
		var a0 := i * TAU / 8.0 + t * 0.35
		var a1 := (i + 2) * TAU / 8.0 + t * 0.35
		var p0 := center + Vector2(cos(a0), sin(a0)) * 30.0
		var p1 := center + Vector2(cos(a1), sin(a1)) * 30.0
		draw_line(p0, p1, Color("7ee8d8", 0.25))


func _draw_fracture(t: float) -> void:
	var center := Vector2(120, 56)
	draw_circle(center, 10.0, Color("ffe08a", 0.5 + sin(t * 6) * 0.3))
	for i in 10:
		var ang := i * TAU / 10.0 + 0.2
		var len := 20.0 + minf(t * 40.0, 50.0) + sin(t * 3 + i) * 4.0
		var end := center + Vector2(cos(ang), sin(ang)) * len
		draw_line(center, end, Color("8ad8ff", 0.7), 2.0)
		draw_line(end, end + Vector2(cos(ang + 0.4), sin(ang + 0.4)) * 16.0, Color("5ad4c8", 0.5), 1.0)
	# Shatter shards falling.
	for i in 6:
		var sh := center + Vector2(cos(i * 1.2), sin(i * 0.9)) * (12.0 + t * 18.0 + i * 3.0)
		draw_rect(Rect2(sh.x, sh.y + t * 20.0, 2, 2), Color("cfe8ff", 0.6))


func _draw_harmons(t: float) -> void:
	var ids := ["emberkit", "tideling", "mossling"]
	var center := Vector2(120, 56)
	for i in ids.size():
		var ang := i * TAU / 3.0 + t * 0.5
		var pos := center + Vector2(cos(ang), sin(ang)) * (22.0 + sin(t * 2 + i) * 3.0)
		_draw_harmon_sprite(ids[i], pos, 28)
	# Memory motes.
	for i in 10:
		var m := center + Vector2(sin(t * 0.8 + i), cos(t * 0.6 + i * 1.3)) * 40.0
		draw_rect(Rect2(m.x, m.y, 1, 1), Color("fff0b0", 0.4 + sin(t * 3 + i) * 0.3))


func _draw_disturbance(t: float) -> void:
	# Simple valley map silhouette.
	var pts := PackedVector2Array([
		Vector2(40, 78), Vector2(80, 62), Vector2(120, 70), Vector2(160, 58), Vector2(200, 74),
		Vector2(200, 88), Vector2(40, 88),
	])
	draw_colored_polygon(pts, Color("3a6848", 0.55))
	var nodes := [Vector2(70, 68), Vector2(120, 64), Vector2(168, 70), Vector2(95, 76), Vector2(145, 74)]
	for i in nodes.size():
		var pulse := 0.5 + sin(t * 4.0 + i * 1.7) * 0.5
		draw_circle(nodes[i], 4.0 + pulse * 2.0, Color("ff6088", 0.15 + pulse * 0.2))
		draw_circle(nodes[i], 2.0, Color("ffd166", pulse))


func _draw_veil(t: float) -> void:
	draw_rect(Rect2(0, 0, 240, 160), Color(0, 0, 0, 0.35))
	for i in 4:
		var x := 20 + i * 52
		var h := 40 + (i % 2) * 12
		draw_rect(Rect2(x, 90 - h, 14, h), Color("1a1830", 0.7))
		draw_rect(Rect2(x + 4, 86 - h, 6, 6), Color("5a5080", 0.5 + sin(t + i) * 0.2))
	# Watching eyes.
	draw_rect(Rect2(58, 42, 3, 1), Color("cfe8ff", 0.5 + sin(t * 2) * 0.3))
	draw_rect(Rect2(178, 48, 3, 1), Color("cfe8ff", 0.5 + sin(t * 2.3) * 0.3))


func _draw_journey(t: float) -> void:
	_draw_town(t * 0.5)
	# Traveler dot walking the path.
	var path_x := 40.0 + fmod(t * 18.0, 140.0)
	draw_circle(Vector2(path_x, 92), 3.0, Color("fff0b0"))
	draw_rect(Rect2(path_x - 2, 88, 4, 5), Color("5ad4c8", 0.8))


func _draw_town(t: float) -> void:
	draw_rect(Rect2(0, 82, 240, 30), Color("4a8858", 0.45))
	for i in 5:
		var bx := 28 + i * 36
		var bh := 18 + (i % 3) * 4
		draw_rect(Rect2(bx, 86 - bh, 22, bh), Color("5a6078"))
		draw_rect(Rect2(bx + 6, 88 - bh - 6, 10, 6), Color("8a90a8", 0.7))
		if i % 2 == 0:
			draw_rect(Rect2(bx + 9, 90 - bh - 10, 4, 4), Color("ffe08a", 0.5 + sin(t * 2 + i) * 0.3))
	# North gate path.
	draw_rect(Rect2(112, 70, 16, 24), Color("6a5848", 0.5))


func _draw_bond(t: float, starter_id: String) -> void:
	var id := starter_id if starter_id != "" else "emberkit"
	var center := Vector2(120, 56)
	for r in [24, 16]:
		draw_circle(center, float(r), Color("5ad4c8", 0.08 + sin(t * 2) * 0.05))
	_draw_harmon_sprite(id, center, 40)
	# Bond rings rising.
	for i in 3:
		var ry := 70.0 - fmod(t * 20.0 + i * 12.0, 40.0)
		draw_arc(Vector2(120, ry), 14.0 + i * 4.0, 0, PI, 16, Color("7ee8d8", 0.35), 1.0, true)


func _draw_depart(t: float) -> void:
	_draw_town(t * 0.3)
	# North arrow path.
	draw_rect(Rect2(116, 48, 8, 30), Color("8a7858", 0.6))
	for i in 3:
		var y := 52 + i * 8 - fmod(t * 12.0, 8.0)
		draw_rect(Rect2(118, y, 4, 2), Color("fff0b0", 0.7))
	# Gate glow.
	draw_rect(Rect2(108, 44, 24, 4), Color("5ad4c8", 0.25 + sin(t * 3) * 0.15))


func _draw_harmon_sprite(id: String, pos: Vector2, px: int) -> void:
	if id == "":
		return
	var def := EchoCatalog.get_echo(id)
	if def == null:
		return
	var path := def.sprite_path
	if path == "" or not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	draw_texture_rect(tex, Rect2(pos.x - px * 0.5, pos.y - px * 0.5, px, px), false)
