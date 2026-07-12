extends Control
## Places a small number of grounded hero sprites (Harmons / characters) as the
## focal point of each cutscene slide. Painted scenery lives in the backdrop;
## atmospheric VFX live in the fx layer. Sprites get soft shadows + subtle motion.

var _root: Control
var _fx: Control
var _nodes: Array[Node] = []
var _shadows: Array = []
var _visual := ""
var _starter_id := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(240, 160)
	_root = Control.new()
	_root.size = size
	_root.z_index = 1
	add_child(_root)
	_fx = Control.new()
	_fx.size = size
	_fx.z_index = 2
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.set_script(load("res://scripts/boot/intro_cutscene_fx.gd"))
	add_child(_fx)


func build(visual: String, starter_id: String) -> void:
	_visual = visual
	_starter_id = starter_id
	# Free immediately so old sprites never linger behind the new slide.
	for n in _nodes:
		if is_instance_valid(n):
			if n.get_parent():
				n.get_parent().remove_child(n)
			n.free()
	_nodes.clear()
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
	_play_entrance()


func animate(t: float) -> void:
	for n in _nodes:
		if not is_instance_valid(n) or not n.has_meta("anim"):
			continue
		var kind: String = n.get_meta("anim")
		var base: Vector2 = n.get_meta("base_pos")
		match kind:
			"bob":
				var amp: float = n.get_meta("amp")
				var spd: float = n.get_meta("spd")
				n.position = base + Vector2(0, sin(t * spd + n.get_meta("off")) * amp)
			"float":
				var amp2: float = n.get_meta("amp")
				n.position = base + Vector2(sin(t * 0.6 + n.get_meta("off")) * 1.0, sin(t * 1.1 + n.get_meta("off")) * amp2)
			"shake":
				# Soft tremor only — never a violent screen shake feel.
				n.position = base + Vector2(sin(t * 8.0) * 0.4, cos(t * 6.5) * 0.25)
			"walk":
				var spd2: float = n.get_meta("spd")
				var rng: float = n.get_meta("range")
				n.position = base + Vector2(fmod(t * spd2, rng), sin(t * 5.0) * 0.5)
	if _fx:
		_fx.queue_redraw()


func _draw() -> void:
	for s in _shadows:
		var c: Vector2 = s.pos
		var w: float = s.w
		# Soft elliptical ground shadow.
		draw_colored_polygon(_ellipse(c, w, w * 0.32), Color(0, 0, 0, 0.28))
		draw_colored_polygon(_ellipse(c, w * 0.6, w * 0.2), Color(0, 0, 0, 0.18))


func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		var a := float(i) / 20.0 * TAU
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _play_entrance() -> void:
	var delay := 0.0
	for n in _nodes:
		if not is_instance_valid(n):
			continue
		var c := n as CanvasItem
		var target_a: float = 1.0
		if n.has_meta("target_a"):
			target_a = n.get_meta("target_a")
		c.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(c, "modulate:a", target_a, 0.4).set_delay(delay)
		delay += 0.12


# ---- slide builds ----------------------------------------------------------

func _build_chorus() -> void:
	# The peaceful trio gathered under the rising sun.
	_hero_harmon("mossling", Vector2(78, 110), 28, 0.0)
	_hero_harmon("emberkit", Vector2(120, 112), 32, 0.7)
	_hero_harmon("tideling", Vector2(162, 110), 28, 1.4)


func _build_fracture() -> void:
	# Two lone silhouettes flee the breaking land — kept sparse for drama.
	_silhouette(Tiles.TRAINER_PATHS[4], Vector2(70, 108), 28, Color("120810"))
	_silhouette("res://assets/kenney/chars/trainer_smith.png", Vector2(170, 110), 30, Color("160a12"))


func _build_harmons() -> void:
	# Hero trio, front and center — the focal introduction.
	_hero_harmon("emberkit", Vector2(64, 108), 40, 0.0)
	_hero_harmon("tideling", Vector2(120, 104), 44, 0.9)
	_hero_harmon("mossling", Vector2(176, 108), 40, 1.8)


func _build_disturbance() -> void:
	# A lone explorer faces the awakening ruins.
	_silhouette(Tiles.TRAINER_PATHS[4], Vector2(70, 110), 32, Color("1a1428"))


func _build_veil() -> void:
	# Two hooded watchers flank a drifting ghost-Harmon.
	_silhouette("res://assets/kenney/chars/trainer_monk.png", Vector2(40, 110), 32, Color("241d3a"))
	_silhouette("res://assets/kenney/chars/trainer_guard.png", Vector2(200, 110), 32, Color("221b34"))
	_wisp("res://assets/kenney/chars/echo_ghost.png", Vector2(120, 64), 28, 0.0)


func _build_journey() -> void:
	# A traveler approaches the village at golden hour.
	_walker(Tiles.TRAINER_PATHS[4], Vector2(30, 112), 30)


func _build_town() -> void:
	# The nurse greets a villager in the square — just two figures.
	_hero_sprite(Tiles.NURSE, Vector2(96, 110), 28, 0.0)
	_hero_sprite(Tiles.TRAINER_PATHS[3], Vector2(150, 110), 28, 1.0)


func _build_bond() -> void:
	# Close intimate moment: the chosen Harmon and its new partner.
	var sid := _starter_id if _starter_id != "" else "emberkit"
	_silhouette(Tiles.TRAINER_PATHS[4], Vector2(66, 112), 36, Color("101828"))
	_float_harmon(sid, Vector2(140, 70), 48)


func _build_depart() -> void:
	# Partner and ranger set out north through the gate.
	var sid := _starter_id if _starter_id != "" else "emberkit"
	_hero_sprite(Tiles.TRAINER_PATHS[5], Vector2(92, 110), 28, 0.0)
	_hero_harmon(sid, Vector2(132, 112), 26, 0.8)


# ---- sprite factories ------------------------------------------------------

func _hero_harmon(id: String, feet: Vector2, px: int, off: float) -> void:
	var path := _harmon_path(id)
	if path == "":
		return
	_hero_sprite(path, feet, px, off)


func _hero_sprite(path: String, feet: Vector2, px: int, off: float) -> void:
	var tr := _make_sprite(path, feet, px)
	tr.set_meta("anim", "bob")
	tr.set_meta("base_pos", tr.position)
	tr.set_meta("amp", 1.0)
	tr.set_meta("spd", 1.6)
	tr.set_meta("off", off)
	_shadows.append({"pos": feet + Vector2(0, 1), "w": px * 0.42})
	_track(tr)


func _float_harmon(id: String, center: Vector2, px: int) -> void:
	var path := _harmon_path(id)
	if path == "":
		return
	var tr := _make_sprite(path, center + Vector2(0, px * 0.5), px)
	tr.set_meta("anim", "float")
	tr.set_meta("base_pos", tr.position)
	tr.set_meta("amp", 2.0)
	tr.set_meta("off", 0.0)
	_track(tr)


func _wisp(path: String, center: Vector2, px: int, off: float) -> void:
	var tr := _make_sprite(path, center + Vector2(0, px * 0.5), px)
	tr.modulate = Color(0.8, 0.85, 1.0)
	tr.set_meta("anim", "float")
	tr.set_meta("base_pos", tr.position)
	tr.set_meta("amp", 2.5)
	tr.set_meta("off", off)
	tr.set_meta("target_a", 0.8)
	_track(tr)


func _silhouette(path: String, feet: Vector2, px: int, tint: Color) -> void:
	var tr := _make_sprite(path, feet, px)
	tr.modulate = tint
	tr.set_meta("anim", "bob")
	tr.set_meta("base_pos", tr.position)
	tr.set_meta("amp", 0.5)
	tr.set_meta("spd", 1.2)
	tr.set_meta("off", 0.0)
	_shadows.append({"pos": feet + Vector2(0, 1), "w": px * 0.4})
	_track(tr)


func _walker(path: String, feet: Vector2, px: int) -> void:
	var tr := _make_sprite(path, feet, px)
	tr.set_meta("anim", "walk")
	tr.set_meta("base_pos", tr.position)
	tr.set_meta("spd", 10.0)
	tr.set_meta("range", 150.0)
	_shadows.append({"pos": feet + Vector2(0, 1), "w": px * 0.4})
	_track(tr)


func _make_sprite(path: String, feet: Vector2, px: int) -> TextureRect:
	# `feet` is the ground contact point; sprite is centered horizontally and
	# sits its bottom edge on that point.
	var tr := TextureRect.new()
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.size = Vector2(px, px)
	tr.position = feet - Vector2(px * 0.5, px)
	return tr


func _track(n: Node) -> void:
	_root.add_child(n)
	_nodes.append(n)


func _harmon_path(id: String) -> String:
	var def := EchoCatalog.get_echo(id)
	if def == null:
		return ""
	return def.sprite_path if ResourceLoader.exists(def.sprite_path) else ""
