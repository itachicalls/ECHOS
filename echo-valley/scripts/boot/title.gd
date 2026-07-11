extends Control

const VIEW_W := 240
const VIEW_H := 160

const STARTER_BLURB := {
	"emberkit": "Fire - brave and warm",
	"tideling": "Water - gentle and calm",
	"mossling": "Grass - curious and spry",
}
const STARTER_IDS := ["emberkit", "tideling", "mossling"]

var _menu: VBoxContainer
var _starter_panel: Control


func _ready() -> void:
	custom_minimum_size = Vector2(VIEW_W, VIEW_H)
	size = Vector2(VIEW_W, VIEW_H)
	SceneRouter.ensure_visible()
	_build_scene()
	_build_menu()


# ------------------------------------------------------------------ scenery
func _build_scene() -> void:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([Color("21356b"), Color("6f8fd0"), Color("f7d9a6")])
	var sky_tex := GradientTexture2D.new()
	sky_tex.gradient = grad
	sky_tex.fill_from = Vector2(0, 0)
	sky_tex.fill_to = Vector2(0, 1)
	sky_tex.width = VIEW_W
	sky_tex.height = VIEW_H
	var sky := TextureRect.new()
	sky.texture = sky_tex
	sky.position = Vector2.ZERO
	sky.size = Vector2(VIEW_W, VIEW_H)
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(sky)

	_circle(Vector2(188, 28), 28, Color(1, 0.92, 0.7, 0.55))
	_circle(Vector2(188, 28), 20, Color(1, 0.95, 0.78, 0.9))
	_cloud(Vector2(10, 10), 0.75)
	_cloud(Vector2(130, 6), 0.55)

	_hill(Vector2(52, 120), 80, Color("6cbf6a"))
	_hill(Vector2(178, 124), 96, Color("58ad57"))
	var ground := ColorRect.new()
	ground.color = Color("4f9d4e")
	ground.position = Vector2(0, 112)
	ground.size = Vector2(VIEW_W, 48)
	add_child(ground)
	var ground2 := ColorRect.new()
	ground2.color = Color("3f8a44")
	ground2.position = Vector2(0, 126)
	ground2.size = Vector2(VIEW_W, 34)
	add_child(ground2)

	# fixed coords — no anchors (anchors break when the window is scaled on web)
	var title := _label("ECHO VALLEY", 22, Color("ffe08a"), Vector2(0, 8), Vector2(VIEW_W, 28), HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_outline_color", Color("2a1a3a"))
	title.add_theme_constant_override("outline_size", 4)
	title.clip_text = true
	add_child(title)

	var sub := _label("a cozy Echo-catching adventure", 7, Color("2a3a5a"), Vector2(4, 36), Vector2(VIEW_W - 8, 12), HORIZONTAL_ALIGNMENT_CENTER)
	sub.clip_text = true
	add_child(sub)

	const STARTER_PX := 26
	for i in STARTER_IDS.size():
		var tr := TextureRect.new()
		var def := EchoCatalog.get_echo(STARTER_IDS[i])
		tr.texture = load(def.sprite_path)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size = Vector2(STARTER_PX, STARTER_PX)
		var base_y := 84.0
		tr.position = Vector2(10 + i * 32, base_y)
		add_child(tr)
		var t := create_tween().set_loops()
		var up := 0.55 + i * 0.12
		t.tween_property(tr, "position:y", base_y - 2.0, up).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(tr, "position:y", base_y, up).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var ver := _label("v0.14", 7, Color("2a3a5a", 0.8), Vector2(4, 148), Vector2(40, 10), HORIZONTAL_ALIGNMENT_LEFT)
	add_child(ver)


func _circle(center: Vector2, radius: float, color: Color) -> void:
	var c := _make_disc(radius, color)
	c.position = center - Vector2(radius, radius)
	add_child(c)


func _make_disc(radius: float, color: Color) -> TextureRect:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var r := 30.0
	for y in 64:
		for x in 64:
			if Vector2(x - 32, y - 32).length() <= r:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	var tex := ImageTexture.create_from_image(img)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.modulate = color
	tr.size = Vector2(radius * 2, radius * 2)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	return tr


func _cloud(pos: Vector2, scale: float) -> void:
	var col := Color(1, 1, 1, 0.85)
	for off in [Vector2(0, 6), Vector2(14, 2), Vector2(28, 6), Vector2(10, 0), Vector2(20, 0)]:
		var d := _make_disc(9 * scale, col)
		d.position = pos + off * scale
		add_child(d)


func _hill(center: Vector2, width: float, color: Color) -> void:
	var d := _make_disc(width * 0.5, color)
	d.position = center - Vector2(width * 0.5, width * 0.5)
	add_child(d)


func _label(text: String, size: int, color: Color, pos: Vector2, sz: Vector2, align: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = sz
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	return l


# ------------------------------------------------------------------ menu
func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	return sb


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 9)
	b.add_theme_color_override("font_color", Color("ffffff"))
	b.add_theme_color_override("font_hover_color", Color("ffe08a"))
	b.add_theme_color_override("font_pressed_color", Color("ffd166"))
	b.add_theme_stylebox_override("normal", _button_style(Color("1d3a5f", 0.92), Color("cfe8ff")))
	b.add_theme_stylebox_override("hover", _button_style(Color("2b5384", 0.96), Color("ffe08a")))
	b.add_theme_stylebox_override("pressed", _button_style(Color("14263f", 0.96), Color("ffd166")))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.custom_minimum_size = Vector2(90, 18)
	b.size = Vector2(90, 18)
	b.pressed.connect(cb)
	return b


func _build_menu() -> void:
	var count := 3 if SaveService.has_save() else 2
	var panel_h := count * 18 + (count - 1) * 4 + 12

	var panel := Panel.new()
	panel.position = Vector2(124, 52)
	panel.size = Vector2(110, panel_h)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.06, 0.12, 0.2, 0.55)
	psb.set_corner_radius_all(6)
	psb.set_border_width_all(1)
	psb.border_color = Color(1, 1, 1, 0.25)
	panel.add_theme_stylebox_override("panel", psb)
	add_child(panel)

	_menu = VBoxContainer.new()
	_menu.position = Vector2(8, 6)
	_menu.add_theme_constant_override("separation", 4)
	panel.add_child(_menu)

	if SaveService.has_save():
		_menu.add_child(_button("Continue", _on_continue))
	_menu.add_child(_button("New Adventure", _on_new_game))
	_menu.add_child(_button("Versus Battle", _on_versus))


func _on_continue() -> void:
	if SaveService.load_game():
		GameState.play_mode = "solo"
		SceneRouter.go_to_map(GameState.current_map, GameState.player_cell, GameState.player_facing)


func _on_versus() -> void:
	GameState.play_mode = "versus"
	SceneRouter.go_to_versus_setup()


func _on_new_game() -> void:
	SaveService.delete_save()
	_reset_state()
	_menu.visible = false
	_show_starter_select()


func _reset_state() -> void:
	GameState.party.clear()
	GameState.pc_box.clear()
	GameState.flags = { "starter_chosen": false, "intro_seen": false }
	GameState.seen = {}
	GameState.caught = {}
	GameState.current_map = "town"
	GameState.player_cell = Vector2i(12, 16)
	GameState.player_facing = "up"
	GameState.play_mode = "solo"


# ------------------------------------------------------------------ starter select
func _show_starter_select() -> void:
	_starter_panel = Panel.new()
	_starter_panel.position = Vector2.ZERO
	_starter_panel.size = Vector2(VIEW_W, VIEW_H)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.11, 0.94)
	_starter_panel.add_theme_stylebox_override("panel", sb)
	add_child(_starter_panel)

	var head := _label("Choose your first Echo", 12, Color("ffe08a"), Vector2(0, 8), Vector2(VIEW_W, 16), HORIZONTAL_ALIGNMENT_CENTER)
	_starter_panel.add_child(head)

	for i in STARTER_IDS.size():
		var id: String = STARTER_IDS[i]
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		col.position = Vector2(16 + i * 72, 30)
		col.custom_minimum_size = Vector2(64, 0)
		_starter_panel.add_child(col)

		var art := TextureRect.new()
		var def := EchoCatalog.get_echo(id)
		art.texture = load(def.sprite_path)
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.custom_minimum_size = Vector2(48, 48)
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		col.add_child(art)

		var nm := _label(def.name, 9, Color("ffffff"), Vector2.ZERO, Vector2(64, 12), HORIZONTAL_ALIGNMENT_CENTER)
		col.add_child(nm)

		var bl := _label(STARTER_BLURB[id], 6, Color("a8dadc"), Vector2.ZERO, Vector2(64, 20), HORIZONTAL_ALIGNMENT_CENTER)
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD
		col.add_child(bl)

		var pick := _button("Pick", _on_pick_starter.bind(id))
		pick.custom_minimum_size = Vector2(52, 16)
		pick.size = Vector2(52, 16)
		col.add_child(pick)


func _on_pick_starter(id: String) -> void:
	if GameState.choose_starter(id):
		SaveService.save_game()
		SceneRouter.go_to_map("town", Vector2i(12, 16), "up")
