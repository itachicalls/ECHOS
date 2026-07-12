extends Control
## Composes intro cutscenes from real Kenney / in-game assets (not procedural shapes).

const T := 16

var _root: Control
var _fx: Control
var _nodes: Array[Node] = []
var _visual := ""
var _starter_id := ""
var _atlas_cache: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(240, 160)
	_root = Control.new()
	_root.size = size
	add_child(_root)
	_fx = Control.new()
	_fx.size = size
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.set_script(load("res://scripts/boot/intro_cutscene_fx.gd"))
	add_child(_fx)


func build(visual: String, starter_id: String) -> void:
	_visual = visual
	_starter_id = starter_id
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()
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


func animate(t: float) -> void:
	for n in _nodes:
		if not is_instance_valid(n) or not n.has_meta("anim"):
			continue
		var kind: String = n.get_meta("anim")
		var base: Vector2 = n.get_meta("base_pos")
		var half := n.size * 0.5
		match kind:
			"orbit":
				var r: float = n.get_meta("orbit_r")
				var spd: float = n.get_meta("orbit_spd")
				var off: float = n.get_meta("orbit_off")
				var ang := t * spd + off
				n.position = base + Vector2(cos(ang), sin(ang)) * r - half
			"bob":
				var amp: float = n.get_meta("bob_amp")
				var spd: float = n.get_meta("bob_spd")
				n.position = base + Vector2(0, sin(t * spd + n.get_meta("bob_off")) * amp) - half
			"walk":
				var spd: float = n.get_meta("walk_spd")
				n.position = base + Vector2(fmod(t * spd, 120.0), sin(t * 8.0) * 1.0) - half
			"shake":
				n.position = base + Vector2(sin(t * 22.0) * 1.5, cos(t * 18.0) * 0.8) - half
			"pulse":
				var s := 1.0 + sin(t * 3.0 + n.get_meta("pulse_off")) * 0.06
				n.scale = Vector2(s, s)
				n.position = base - half * s
	if _fx:
		_fx.queue_redraw()


# ---- slide builds ----------------------------------------------------------

func _build_chorus() -> void:
	_fill_grass(0, 5, 14, 8)
	_stamp_cobble_area(4, 6, 11, 7)
	_prop(Tiles.SHRINE_FOUNTAIN, Vector2(104, 28), 32)
	_orbit_sprite(Tiles.TRAINER_PATHS[0], Vector2(120, 52), 34, 0.0)      # wizard
	_orbit_sprite("res://assets/kenney/chars/trainer_elder.png", Vector2(120, 52), 36, 1.2)
	_orbit_sprite(Tiles.NURSE, Vector2(120, 52), 32, 2.4)
	_orbit_harmon("mossling", Vector2(120, 52), 30, 3.6)
	_orbit_harmon("tideling", Vector2(120, 52), 30, 4.8)
	_orbit_harmon("emberkit", Vector2(120, 52), 30, 6.0)
	_prop(Tiles.HEAL_CROSS, Vector2(48, 44), 20)
	_prop(Tiles.HEAL_CROSS, Vector2(168, 46), 20)


func _build_fracture() -> void:
	_fill_grass(0, 5, 14, 8)
	_place_house(Vector2i(2, 4))
	_place_house(Vector2i(10, 3))
	_shake_sprite("res://assets/kenney/chars/echo_golem.png", Vector2(118, 36), 36)
	_prop(Tiles.SHRINE_FOUNTAIN, Vector2(96, 52), 28)
	_prop(Tiles.SPIKES, Vector2(40, 72), 22)
	_prop(Tiles.THORNS, Vector2(172, 70), 22)
	_shake_sprite("res://assets/kenney/chars/trainer_smith.png", Vector2(52, 58), 26)
	_shake_sprite("res://assets/kenney/chars/merchant.png", Vector2(168, 56), 26)


func _build_harmons() -> void:
	_fill_grass(0, 6, 14, 8)
	_tile_rect(3, 0, 0, 5, 7)  # grass2 decor patches
	for i in 4:
		_tile(3, 0, 0, 2 + i * 3, 7)
	_bob_harmon("emberkit", Vector2(52, 44), 40, 0.0)
	_bob_harmon("tideling", Vector2(120, 40), 40, 1.0)
	_bob_harmon("mossling", Vector2(188, 44), 40, 2.0)
	_prop(Tiles.ECHO_CAPSULE, Vector2(108, 68), 18)


func _build_disturbance() -> void:
	_fill_grass(0, 4, 14, 8)
	_stamp_path_h(3, 6, 11)
	_place_house(Vector2i(1, 3))
	_place_house(Vector2i(9, 4))
	_tree(Vector2i(0, 2))
	_tree(Vector2i(13, 2))
	_sprite(Tiles.TRAINER_PATHS[4], Vector2(36, 52), 26, "bob", 0.0)  # scout
	_sprite(Tiles.TRAINER_PATHS[1], Vector2(108, 48), 26, "bob", 1.2) # monk
	_sprite("res://assets/kenney/chars/trainer_ranger.png", Vector2(168, 50), 28, "bob", 2.4)
	_prop(Tiles.SPIKES, Vector2(78, 66), 18)
	_prop(Tiles.THORNS, Vector2(142, 68), 18)


func _build_veil() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.12, 0.55)
	dim.size = size
	_track(dim)
	_fill_grass(0, 5, 14, 8)
	_tile_rect(1, 4, 3, 0, 4, 14)  # cave wall backdrop
	_sprite("res://assets/kenney/chars/trainer_hood.png", Vector2(34, 42), 30, "bob", 0.0, Color(0.65, 0.6, 0.85))
	_sprite("res://assets/kenney/chars/trainer_guard.png", Vector2(178, 40), 30, "bob", 1.5, Color(0.55, 0.55, 0.75))
	_sprite("res://assets/kenney/chars/echo_wraith.png", Vector2(108, 32), 34, "pulse", 0.0)
	_sprite("res://assets/kenney/chars/echo_ghost.png", Vector2(72, 50), 28, "bob", 0.8, Color(0.8, 0.85, 1.0))
	_sprite("res://assets/kenney/chars/echo_rogue.png", Vector2(148, 52), 28, "bob", 2.0, Color(0.75, 0.7, 0.95))


func _build_journey() -> void:
	_build_town_base()
	_walk_sprite("res://assets/kenney/chars/trainer_squire.png", Vector2(24, 58), 28)


func _build_town() -> void:
	_build_town_base()
	_sprite(Tiles.NURSE, Vector2(100, 50), 30, "bob", 0.0)
	_sprite(Tiles.TRAINER_PATHS[3], Vector2(48, 58), 26, "bob", 1.0)
	_sprite(Tiles.TRAINER_PATHS[5], Vector2(156, 56), 26, "bob", 2.0)
	_sprite("res://assets/kenney/chars/merchant.png", Vector2(188, 60), 26, "bob", 3.0)


func _build_bond() -> void:
	_fill_grass(0, 5, 14, 8)
	_stamp_cobble_area(5, 6, 10, 7)
	_prop(Tiles.SHRINE_FOUNTAIN, Vector2(104, 30), 30)
	_prop(Tiles.HEAL_CROSS, Vector2(72, 48), 22)
	var sid := _starter_id if _starter_id != "" else "emberkit"
	_bob_harmon(sid, Vector2(136, 42), 44, 0.0)
	_sprite(Tiles.NURSE, Vector2(72, 46), 30, "bob", 0.5)


func _build_depart() -> void:
	_build_town_base()
	var sid := _starter_id if _starter_id != "" else "emberkit"
	_sprite("res://assets/kenney/chars/trainer_ranger.png", Vector2(96, 48), 30, "bob", 0.0)
	_bob_harmon(sid, Vector2(128, 54), 32, 1.0)
	_stamp_path_v(7, 2, 5)


func _build_town_base() -> void:
	_fill_grass(0, 4, 14, 8)
	_stamp_path_v(7, 4, 7)
	_stamp_cobble_area(5, 5, 10, 6)
	_place_house(Vector2i(1, 3))
	_place_house(Vector2i(10, 2))
	_tree(Vector2i(0, 1))
	_tree(Vector2i(13, 1))
	_tree(Vector2i(14, 4), Tiles.TREE_ORANGE_COL)
	_tile(0, 2, 0, 6, 7)
	_tile(0, 2, 0, 8, 7)
	_prop(Tiles.SHRINE_FOUNTAIN, Vector2(168, 36), 26)


# ---- asset helpers ---------------------------------------------------------

func _track(n: Node) -> void:
	_root.add_child(n)
	_nodes.append(n)


func _atlas(source: int, col: int, row: int) -> AtlasTexture:
	var key := "%d_%d_%d" % [source, col, row]
	if _atlas_cache.has(key):
		return _atlas_cache[key]
	var entry: Dictionary = Tiles.SHEETS[source]
	var sheet: Texture2D = load(String(entry.path))
	var sep: Vector2i = entry.sep
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(
		col * (T + sep.x) + sep.x,
		row * (T + sep.y) + sep.y,
		T, T
	)
	_atlas_cache[key] = at
	return at


func _tile(source: int, col: int, row: int, gx: int, gy: int) -> void:
	var tr := TextureRect.new()
	tr.texture = _atlas(source, col, row)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.position = Vector2(gx * T, gy * T)
	tr.size = Vector2(T, T)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	_track(tr)


func _tile_rect(source: int, col: int, row: int, x0: int, y0: int, x1: int, y1: int) -> void:
	for gy in range(y0, y1 + 1):
		for gx in range(x0, x1 + 1):
			_tile(source, col, row, gx, gy)


func _fill_grass(x0: int, y0: int, x1: int, y1: int) -> void:
	_tile_rect(5, 0, 0, x0, y0, x1, y1)


func _stamp_cobble_area(x0: int, y0: int, x1: int, y1: int) -> void:
	for gy in range(y0, y1 + 1):
		for gx in range(x0, x1 + 1):
			_tile(7, 3, 3, gx, gy)


func _stamp_path_h(x0: int, y: int, x1: int) -> void:
	for gx in range(x0, x1 + 1):
		_tile(6, 3, 3, gx, y)


func _stamp_path_v(x: int, y0: int, y1: int) -> void:
	for gy in range(y0, y1 + 1):
		_tile(6, 3, 3, x, gy)


func _place_house(origin: Vector2i) -> void:
	for row in Tiles.HOUSE_H:
		for col in Tiles.HOUSE_W:
			var atlas: Vector2i = Tiles.HOUSE_ROWS[row][col]
			_tile(0, atlas.x, atlas.y, origin.x + col, origin.y + row)


func _tree(cell: Vector2i, col: int = Tiles.TREE_GREEN_COL) -> void:
	var tr := TextureRect.new()
	var sheet: Texture2D = load(Tiles.TREE_SHEET)
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(col * T, 0, T, T * 2)
	tr.texture = at
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.position = Vector2(cell.x * T, cell.y * T - T)
	tr.size = Vector2(T, T * 2)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	_track(tr)


func _prop(path: String, pos: Vector2, px: int) -> void:
	var tr := _make_sprite(path, pos, px)
	_track(tr)


func _sprite(path: String, pos: Vector2, px: int, anim: String, off: float, tint: Color = Color.WHITE) -> void:
	var tr := _make_sprite(path, pos, px)
	tr.modulate = tint
	tr.set_meta("anim", anim)
	tr.set_meta("base_pos", pos)
	match anim:
		"bob":
			tr.set_meta("bob_amp", 2.0)
			tr.set_meta("bob_spd", 2.2)
			tr.set_meta("bob_off", off)
		"pulse":
			tr.pivot_offset = Vector2(px * 0.5, px * 0.5)
			tr.set_meta("pulse_off", off)
	_track(tr)


func _orbit_sprite(path: String, center: Vector2, px: int, off: float) -> void:
	var tr := _make_sprite(path, center, px)
	tr.set_meta("anim", "orbit")
	tr.set_meta("base_pos", center)
	tr.set_meta("orbit_r", 38.0)
	tr.set_meta("orbit_spd", 0.45)
	tr.set_meta("orbit_off", off)
	_track(tr)


func _orbit_harmon(id: String, center: Vector2, px: int, off: float) -> void:
	var path := _harmon_path(id)
	if path == "":
		return
	_orbit_sprite(path, center, px, off)


func _bob_harmon(id: String, pos: Vector2, px: int, off: float) -> void:
	var path := _harmon_path(id)
	if path == "":
		return
	_sprite(path, pos, px, "bob", off)


func _shake_sprite(path: String, pos: Vector2, px: int) -> void:
	var tr := _make_sprite(path, pos, px)
	tr.set_meta("anim", "shake")
	tr.set_meta("base_pos", pos)
	_track(tr)


func _walk_sprite(path: String, pos: Vector2, px: int) -> void:
	var tr := _make_sprite(path, pos, px)
	tr.set_meta("anim", "walk")
	tr.set_meta("base_pos", pos)
	tr.set_meta("walk_spd", 22.0)
	_track(tr)


func _make_sprite(path: String, pos: Vector2, px: int) -> TextureRect:
	var tr := TextureRect.new()
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.size = Vector2(px, px)
	tr.position = pos - Vector2(px * 0.5, px * 0.5)
	return tr


func _harmon_path(id: String) -> String:
	var def := EchoCatalog.get_echo(id)
	if def == null:
		return ""
	return def.sprite_path if ResourceLoader.exists(def.sprite_path) else ""
