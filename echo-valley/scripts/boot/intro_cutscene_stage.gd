extends Control
## Cutscene hero sprites. Drawn in _draw (same pass as shadows) so feet stay
## locked to the ground and never sink under the letterbox.

const PlayerAvatarScript := preload("res://scripts/core/player_avatar.gd")

const LETTERBOX_TOP := 130.0
const SAFE_FEET := 112.0

var _fx: Control
var _sprites: Array = []  # {tex, region, rect, anim, base, ...}
var _shadows: Array = []
var _visual := ""
var _starter_id := ""
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(240, 160)
	_fx = Control.new()
	_fx.size = size
	_fx.z_index = 2
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.set_script(load("res://scripts/boot/intro_cutscene_fx.gd"))
	add_child(_fx)


func build(visual: String, starter_id: String) -> void:
	_visual = visual
	_starter_id = starter_id
	_sprites.clear()
	_shadows.clear()
	match visual:
		"chorus": _build_chorus()
		"fracture": _build_fracture()
		"harmons": _build_harmons()
		"disturbance": _build_disturbance()
		"veil": _build_veil()
		"journey": _build_journey()
		"town": _build_town()
		"bond": _build_bond()
		"depart": _build_depart()
		_: _build_chorus()
	if _fx.has_method("set_visual"):
		_fx.call("set_visual", visual)
	queue_redraw()


func animate(t: float) -> void:
	_t = t
	for s in _sprites:
		var base: Vector2 = s.base
		var pos := base
		match String(s.anim):
			"bob":
				pos = base + Vector2(0, sin(t * float(s.spd) + float(s.off)) * float(s.amp))
			"float":
				pos = base + Vector2(sin(t * 0.6 + float(s.off)) * 1.0, sin(t * 1.1 + float(s.off)) * float(s.amp))
			"shake":
				pos = base + Vector2(sin(t * 8.0) * 0.4, cos(t * 6.5) * 0.25)
			"walk":
				pos = base + Vector2(fmod(t * float(s.spd), float(s.range)), sin(t * 5.0) * 0.5)
		s.rect = Rect2(pos, s.rect.size)
	queue_redraw()
	if _fx:
		_fx.queue_redraw()


func _draw() -> void:
	for sh in _shadows:
		var c: Vector2 = sh.pos
		var w: float = sh.w
		draw_colored_polygon(_ellipse(c, w, w * 0.32), Color(0, 0, 0, 0.28))
		draw_colored_polygon(_ellipse(c, w * 0.6, w * 0.2), Color(0, 0, 0, 0.18))
	for s in _sprites:
		var col: Color = s.get("modulate", Color(1, 1, 1, 1))
		var entrance := clampf((_t - float(s.get("delay", 0.0))) / 0.35, 0.0, 1.0)
		col.a *= entrance * float(s.get("target_a", 1.0))
		var tex: Texture2D = s.tex
		if tex == null:
			continue
		var region: Rect2 = s.region
		if region.size.x > 0.0:
			draw_texture_rect_region(tex, s.rect, region, col)
		else:
			draw_texture_rect(tex, s.rect, false, col)


func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		var a := float(i) / 20.0 * TAU
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# ---- slides ----------------------------------------------------------------

func _build_chorus() -> void:
	_add_harmon("mossling", Vector2(78, 106), 28, 0.0)
	_add_harmon("emberkit", Vector2(120, 108), 32, 0.7)
	_add_harmon("tideling", Vector2(162, 106), 28, 1.4)


func _build_fracture() -> void:
	_add_sheet(Tiles.TRAINER_PATHS[4], Vector2(70, 106), 28, "bob", Color("120810"), 0.0)
	_add_sheet("res://assets/kenney/chars/trainer_smith.png", Vector2(170, 108), 30, "bob", Color("160a12"), 0.0)


func _build_harmons() -> void:
	_add_harmon("emberkit", Vector2(64, 104), 36, 0.0)
	_add_harmon("tideling", Vector2(120, 102), 40, 0.9)
	_add_harmon("mossling", Vector2(176, 104), 36, 1.8)


func _build_disturbance() -> void:
	_add_sheet(Tiles.TRAINER_PATHS[4], Vector2(70, 108), 32, "bob", Color("1a1428"), 0.0)


func _build_veil() -> void:
	_add_sheet("res://assets/kenney/chars/trainer_monk.png", Vector2(40, 108), 32, "bob", Color("241d3a"), 0.0)
	_add_sheet("res://assets/kenney/chars/trainer_guard.png", Vector2(200, 108), 32, "bob", Color("221b34"), 0.0)
	_add_sheet("res://assets/kenney/chars/echo_ghost.png", Vector2(120, 78), 28, "float", Color(0.8, 0.85, 1.0), 0.0, false, 0.8)


func _build_journey() -> void:
	_add_sheet(Tiles.TRAINER_PATHS[4], Vector2(30, 108), 30, "walk", Color.WHITE, 0.0)


func _build_town() -> void:
	_add_sheet(Tiles.NURSE, Vector2(96, 108), 28, "bob", Color.WHITE, 0.0)
	_add_sheet(Tiles.TRAINER_PATHS[3], Vector2(150, 108), 28, "bob", Color.WHITE, 1.0)


func _build_bond() -> void:
	var sid := _starter_id if _starter_id != "" else "emberkit"
	_add_sheet(PlayerAvatarScript.sprite_path(GameState.player_avatar), Vector2(70, 108), 26, "bob", Color.WHITE, 0.0)
	_add_harmon(sid, Vector2(150, 90), 40, 0.0, true)


func _build_depart() -> void:
	var sid := _starter_id if _starter_id != "" else "emberkit"
	_add_sheet(PlayerAvatarScript.sprite_path(GameState.player_avatar), Vector2(92, 108), 24, "bob", Color.WHITE, 0.0)
	_add_harmon(sid, Vector2(132, 108), 26, 0.8)


# ---- factories -------------------------------------------------------------

func _add_harmon(id: String, feet: Vector2, px: int, off: float, floating: bool = false) -> void:
	var path := _harmon_path(id)
	if path == "":
		return
	_add_sheet(path, feet, px, "float" if floating else "bob", Color.WHITE, off, true)


func _add_sheet(
	path: String,
	feet: Vector2,
	px: int,
	anim: String,
	modulate: Color,
	off: float,
	with_shadow: bool = true,
	target_a: float = 1.0
) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	if tex == null:
		return
	var tw := tex.get_width()
	var th := tex.get_height()
	var region := Rect2()
	var src_w := float(tw)
	var src_h := float(th)
	# Hero-layout sheet: one 16x32 idle frame.
	if tw == 64 and th == 128:
		region = Rect2(0, 0, 16, 32)
		src_w = 16.0
		src_h = 32.0
	var display_w := float(px)
	var display_h := display_w * (src_h / src_w)

	var grounded := Vector2(feet.x, minf(feet.y, SAFE_FEET))
	# Keep the entire sprite above the letterbox.
	if grounded.y > LETTERBOX_TOP - 2.0:
		grounded.y = LETTERBOX_TOP - 2.0
	if grounded.y - display_h < 8.0:
		# extremely tall — still prefer clearing the bar
		pass
	var top := grounded.y - display_h
	if grounded.y > LETTERBOX_TOP - 1.0:
		grounded.y = LETTERBOX_TOP - 1.0
		top = grounded.y - display_h
	# Final clamp: bottom edge must be above letterbox.
	if grounded.y > LETTERBOX_TOP - 1.0:
		grounded.y = LETTERBOX_TOP - 1.0
	top = grounded.y - display_h

	var rect := Rect2(grounded.x - display_w * 0.5, top, display_w, display_h)
	# If somehow still intersecting letterbox, shift up.
	if rect.end.y > LETTERBOX_TOP - 1.0:
		var shift := rect.end.y - (LETTERBOX_TOP - 1.0)
		rect.position.y -= shift
		grounded.y -= shift

	var entry := {
		"tex": tex,
		"region": region,
		"rect": rect,
		"base": rect.position,
		"anim": anim,
		"amp": 1.0 if anim == "bob" else 2.0,
		"spd": 1.6 if anim != "walk" else 10.0,
		"off": off,
		"range": 150.0,
		"modulate": modulate,
		"target_a": target_a,
		"delay": float(_sprites.size()) * 0.1,
	}
	_sprites.append(entry)
	if with_shadow and anim != "float":
		_shadows.append({"pos": Vector2(grounded.x, grounded.y + 1.0), "w": display_w * 0.42})


func _harmon_path(id: String) -> String:
	var def := EchoCatalog.get_echo(id)
	if def == null:
		return ""
	return def.sprite_path if ResourceLoader.exists(def.sprite_path) else ""
