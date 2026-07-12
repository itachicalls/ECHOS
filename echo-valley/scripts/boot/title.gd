extends Control

const TitleFonts := preload("res://scripts/ui/title_fonts.gd")

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


func _build_scene() -> void:
	var backdrop := preload("res://scripts/ui/title_backdrop.gd").new()
	add_child(backdrop)

	# Title stack: warm glow, then crisp pixel type.
	var glow := Label.new()
	glow.text = GameStrings.TITLE
	glow.position = Vector2(0, 10)
	glow.size = Vector2(VIEW_W, 24)
	glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	TitleFonts.apply(glow, 10, Color("7ee8d8", 0.35))
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var title := TitleFonts.shadow_label(
		self, GameStrings.TITLE, 10, Color("fff0b0"),
		Vector2(0, 8), Vector2(VIEW_W, 24),
		HORIZONTAL_ALIGNMENT_CENTER, Color("1a2848"), 3
	)
	title.clip_text = true

	var sub := TitleFonts.shadow_label(
		self, GameStrings.TAGLINE, 6, Color("e8f4ff"),
		Vector2(4, 30), Vector2(VIEW_W - 8, 14),
		HORIZONTAL_ALIGNMENT_CENTER, Color("1a3050"), 1
	)
	sub.clip_text = true

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

	var ver := Label.new()
	ver.text = "v0.14"
	ver.position = Vector2(6, 146)
	ver.size = Vector2(48, 10)
	TitleFonts.apply(ver, 6, Color("d8e8ff", 0.75), Color("1a2848"), 1)
	add_child(ver)


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
	TitleFonts.apply(b, 6, Color("f0f8ff"))
	b.add_theme_color_override("font_hover_color", Color("fff0b0"))
	b.add_theme_color_override("font_pressed_color", Color("7ee8d8"))
	b.add_theme_stylebox_override("normal", _button_style(Color("142038", 0.9), Color("5ad4c8", 0.7)))
	b.add_theme_stylebox_override("hover", _button_style(Color("1e3058", 0.95), Color("fff0b0")))
	b.add_theme_stylebox_override("pressed", _button_style(Color("0c1828", 0.95), Color("7ee8d8")))
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
	psb.bg_color = Color("0c1428", 0.72)
	psb.set_corner_radius_all(6)
	psb.set_border_width_all(2)
	psb.border_color = Color("5ad4c8", 0.45)
	psb.shadow_color = Color(0, 0, 0, 0.35)
	psb.shadow_size = 3
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
	await _play_cutscene("opening")
	if not is_inside_tree():
		return
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


func _show_starter_select() -> void:
	_starter_panel = Panel.new()
	_starter_panel.position = Vector2.ZERO
	_starter_panel.size = Vector2(VIEW_W, VIEW_H)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("060c18", 0.92)
	sb.set_border_width_all(2)
	sb.border_color = Color("5ad4c8", 0.35)
	_starter_panel.add_theme_stylebox_override("panel", sb)
	add_child(_starter_panel)

	var head := TitleFonts.shadow_label(
		_starter_panel, "Choose your first %s" % GameStrings.CREATURE, 8, Color("fff0b0"),
		Vector2(0, 8), Vector2(VIEW_W, 16), HORIZONTAL_ALIGNMENT_CENTER, Color("1a2848"), 2
	)

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

		var nm := Label.new()
		nm.text = def.name
		nm.custom_minimum_size = Vector2(64, 12)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		TitleFonts.apply(nm, 6, Color("f0f8ff"), Color("1a2848"), 1)
		col.add_child(nm)

		var bl := Label.new()
		bl.text = STARTER_BLURB[id]
		bl.custom_minimum_size = Vector2(64, 20)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD
		TitleFonts.apply(bl, 5, Color("a8e8dc"))
		col.add_child(bl)

		var pick := _button("Pick", _on_pick_starter.bind(id))
		pick.custom_minimum_size = Vector2(52, 16)
		pick.size = Vector2(52, 16)
		col.add_child(pick)


func _on_pick_starter(id: String) -> void:
	if not GameState.choose_starter(id):
		return
	if _starter_panel:
		_starter_panel.visible = false
	await _play_cutscene("arrival", id)
	if not is_inside_tree():
		return
	GameState.flags["intro_seen"] = true
	SaveService.save_game()
	SceneRouter.go_to_map("town", Vector2i(12, 16), "up")


func _play_cutscene(sequence_id: String, starter_id: String = "") -> void:
	var cut := preload("res://scripts/boot/intro_cutscene.gd").new()
	cut.sequence_id = sequence_id
	cut.starter_id = starter_id
	add_child(cut)
	await cut.finished
