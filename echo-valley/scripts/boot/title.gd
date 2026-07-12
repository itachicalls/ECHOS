extends Control

const TitleFonts := preload("res://scripts/ui/title_fonts.gd")
const PlayerAvatarScript := preload("res://scripts/core/player_avatar.gd")

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
var _create_panel: Control
var _chrome: Control
var _picked_avatar: String = "keeper"
var _name_field: LineEdit
var _avatar_frames: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(VIEW_W, VIEW_H)
	size = Vector2(VIEW_W, VIEW_H)
	SceneRouter.ensure_visible()
	_build_scene()
	_build_menu()


func _build_scene() -> void:
	var backdrop := preload("res://scripts/ui/title_backdrop.gd").new()
	backdrop.z_index = -1
	add_child(backdrop)

	# All title chrome lives here so cutscenes can hide it cleanly.
	_chrome = Control.new()
	_chrome.size = Vector2(VIEW_W, VIEW_H)
	_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chrome.z_index = 1
	add_child(_chrome)

	# Single clean title — no glow + shadow + outline stack (that garbles pixel fonts).
	TitleFonts.shadow_label(
		_chrome, GameStrings.TITLE, 8, Color("fff0b0"),
		Vector2(4, 10), Vector2(VIEW_W - 8, 16),
		HORIZONTAL_ALIGNMENT_CENTER, Color(), 0, 0
	)

	TitleFonts.shadow_label(
		_chrome, GameStrings.TAGLINE, 5, Color("e8f4ff"),
		Vector2(8, 28), Vector2(VIEW_W - 16, 12),
		HORIZONTAL_ALIGNMENT_CENTER, Color(), 0, 0
	)

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
		_chrome.add_child(tr)
		var t := create_tween().set_loops()
		var up := 0.55 + i * 0.12
		t.tween_property(tr, "position:y", base_y - 2.0, up).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(tr, "position:y", base_y, up).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var ver := Label.new()
	ver.text = "v0.14"
	ver.position = Vector2(6, 146)
	ver.size = Vector2(48, 10)
	TitleFonts.apply(ver, 5, Color("d8e8ff", 0.75))
	_chrome.add_child(ver)


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
	var btn_h := 18
	if TouchUtil != null and TouchUtil.is_touch_ui_enabled():
		btn_h = 22
	b.custom_minimum_size = Vector2(90, btn_h)
	b.size = Vector2(90, btn_h)
	b.pressed.connect(cb)
	return b


func _build_menu() -> void:
	var count := 2
	if SaveService.has_save():
		count = 3
	var btn_h := 18
	if TouchUtil != null and TouchUtil.is_touch_ui_enabled():
		btn_h = 22
	var panel_h := count * btn_h + (count - 1) * 4 + 12

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
	_chrome.add_child(panel)

	_menu = VBoxContainer.new()
	_menu.position = Vector2(8, 6)
	_menu.add_theme_constant_override("separation", 4)
	panel.add_child(_menu)

	if SaveService.has_save():
		_menu.add_child(_button("Continue", _on_continue))
	_menu.add_child(_button("New Adventure", _on_new_game))
	_menu.add_child(_button("Versus Battle", _on_versus))


func _on_continue() -> void:
	if not SaveService.load_game():
		EventBus.toast.emit("Could not load save file.")
		return
	GameState.play_mode = "solo"
	await SceneRouter.go_to_map_and_wait(GameState.current_map, GameState.player_cell, GameState.player_facing)


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
	_show_character_create()


func _reset_state() -> void:
	GameState.party.clear()
	GameState.pc_box.clear()
	GameState.flags = { "starter_chosen": false, "intro_seen": false }
	GameState.inventory = ItemCatalog.starter_inventory()
	GameState.seen = {}
	GameState.caught = {}
	GameState.current_map = "town"
	GameState.player_cell = Vector2i(12, 16)
	GameState.player_facing = "up"
	GameState.play_mode = "solo"
	GameState.player_name = "Ash"
	GameState.player_avatar = "keeper"


func _show_character_create() -> void:
	if _chrome:
		_chrome.visible = false
	_picked_avatar = "keeper"
	_avatar_frames.clear()

	_create_panel = Panel.new()
	_create_panel.position = Vector2.ZERO
	_create_panel.size = Vector2(VIEW_W, VIEW_H)
	_create_panel.z_index = 20
	_create_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("060c18", 0.97)
	sb.set_border_width_all(0)
	_create_panel.add_theme_stylebox_override("panel", sb)
	add_child(_create_panel)

	TitleFonts.shadow_label(
		_create_panel, "Create your Keeper", 7, Color("fff0b0"),
		Vector2(8, 8), Vector2(VIEW_W - 16, 14),
		HORIZONTAL_ALIGNMENT_CENTER, Color(), 0, 0
	)
	TitleFonts.shadow_label(
		_create_panel, "Choose your look", 5, Color("a8e8dc"),
		Vector2(8, 22), Vector2(VIEW_W - 16, 10),
		HORIZONTAL_ALIGNMENT_CENTER, Color(), 0, 0
	)

	for i in PlayerAvatarScript.IDS.size():
		var id: String = PlayerAvatarScript.IDS[i]
		_avatar_column(id, 14 + i * 72)

	_update_avatar_selection()

	TitleFonts.shadow_label(
		_create_panel, "Your name", 5, Color("cfe8ff"),
		Vector2(8, 104), Vector2(VIEW_W - 16, 10),
		HORIZONTAL_ALIGNMENT_CENTER, Color(), 0, 0
	)

	_name_field = _name_field_box()
	_name_field.text = PlayerAvatarScript.DEFAULT_NAMES[_picked_avatar]
	_name_field.placeholder_text = "Enter a name..."
	_create_panel.add_child(_name_field)

	var go := _button("Continue", _on_confirm_character)
	go.position = Vector2(75, 136)
	go.size = Vector2(90, 18)
	if TouchUtil != null and TouchUtil.is_touch_ui_enabled():
		go.size = Vector2(90, 22)
	_create_panel.add_child(go)


func _avatar_column(id: String, x: int) -> void:
	var frame := Panel.new()
	frame.position = Vector2(x, 34)
	frame.size = Vector2(64, 66)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_panel.add_child(frame)
	_avatar_frames[id] = frame

	var preview := TextureRect.new()
	preview.texture = PlayerAvatarScript.idle_preview_texture(id)
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	preview.custom_minimum_size = Vector2(28, 56)
	preview.size = Vector2(28, 56)
	preview.position = Vector2(18, 4)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(preview)

	var nm := Label.new()
	nm.text = PlayerAvatarScript.LABELS.get(id, id)
	nm.position = Vector2(0, 46)
	nm.size = Vector2(64, 8)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	TitleFonts.apply(nm, 6, Color("f0f8ff"))
	frame.add_child(nm)

	var blurb := Label.new()
	blurb.text = PlayerAvatarScript.BLURBS.get(id, "")
	blurb.position = Vector2(2, 54)
	blurb.size = Vector2(60, 10)
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD
	blurb.clip_text = true
	TitleFonts.apply(blurb, 4, Color("8ec8ff"))
	frame.add_child(blurb)

	var hit := Button.new()
	hit.position = Vector2.ZERO
	hit.size = frame.size
	hit.focus_mode = Control.FOCUS_NONE
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hit.pressed.connect(_on_pick_avatar.bind(id))
	frame.add_child(hit)


func _name_field_box() -> LineEdit:
	var f := LineEdit.new()
	f.position = Vector2(52, 116)
	f.size = Vector2(136, 16)
	f.max_length = PlayerAvatarScript.MAX_NAME_LEN
	f.alignment = HORIZONTAL_ALIGNMENT_CENTER
	f.virtual_keyboard_enabled = true
	f.focus_mode = Control.FOCUS_ALL
	f.add_theme_font_size_override("font_size", 7)
	f.add_theme_stylebox_override("normal", _field_style(Color("0c141c", 0.92), Color("3a5f8f")))
	f.add_theme_stylebox_override("focus", _field_style(Color("14202b"), Color("8ec8ff")))
	f.add_theme_color_override("font_color", Color("e8f4ff"))
	f.add_theme_color_override("font_placeholder_color", Color("5a7088"))
	return f


func _field_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	return sb


func _on_pick_avatar(id: String) -> void:
	_picked_avatar = id
	_update_avatar_selection()
	if _name_field == null:
		return
	var current := _name_field.text.strip_edges()
	for default_name in PlayerAvatarScript.DEFAULT_NAMES.values():
		if current == default_name:
			_name_field.text = PlayerAvatarScript.DEFAULT_NAMES.get(id, "Keeper")
			return
	if current == "":
		_name_field.text = PlayerAvatarScript.DEFAULT_NAMES.get(id, "Keeper")


func _update_avatar_selection() -> void:
	for id in PlayerAvatarScript.IDS:
		var frame: Panel = _avatar_frames.get(id, null)
		if frame == null:
			continue
		var sel := id == _picked_avatar
		var box := StyleBoxFlat.new()
		box.bg_color = Color("1a3050", 0.88) if sel else Color("0c1428", 0.55)
		box.border_color = Color("fff0b0") if sel else Color("3a5f8f", 0.6)
		box.set_border_width_all(2 if sel else 1)
		box.set_corner_radius_all(4)
		frame.add_theme_stylebox_override("panel", box)


func _on_confirm_character() -> void:
	var typed := _name_field.text if _name_field else ""
	GameState.set_player_identity(typed, _picked_avatar)
	if _create_panel:
		_create_panel.visible = false
	_show_starter_select()


func _show_starter_select() -> void:
	# Keep title chrome hidden — it was bleeding over this panel.
	if _chrome:
		_chrome.visible = false

	_starter_panel = Panel.new()
	_starter_panel.position = Vector2.ZERO
	_starter_panel.size = Vector2(VIEW_W, VIEW_H)
	_starter_panel.z_index = 20
	_starter_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("060c18", 0.97)
	sb.set_border_width_all(0)
	_starter_panel.add_theme_stylebox_override("panel", sb)
	add_child(_starter_panel)

	TitleFonts.shadow_label(
		_starter_panel, "%s — choose your first %s" % [GameState.player_name, GameStrings.CREATURE], 7, Color("fff0b0"),
		Vector2(8, 10), Vector2(VIEW_W - 16, 14),
		HORIZONTAL_ALIGNMENT_CENTER, Color(), 0, 0
	)

	for i in STARTER_IDS.size():
		var id: String = STARTER_IDS[i]
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 3)
		col.position = Vector2(12 + i * 72, 32)
		col.custom_minimum_size = Vector2(64, 0)
		_starter_panel.add_child(col)

		var art := TextureRect.new()
		var def := EchoCatalog.get_echo(id)
		art.texture = load(def.sprite_path)
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.custom_minimum_size = Vector2(48, 48)
		art.size = Vector2(48, 48)
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		col.add_child(art)

		var nm := Label.new()
		nm.text = def.name
		nm.custom_minimum_size = Vector2(64, 10)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		TitleFonts.apply(nm, 6, Color("f0f8ff"))
		col.add_child(nm)

		var bl := Label.new()
		bl.text = STARTER_BLURB[id]
		bl.custom_minimum_size = Vector2(64, 22)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD
		bl.clip_text = true
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
	await SceneRouter.go_to_map_and_wait("town", Vector2i(12, 16), "up")


func _play_cutscene(sequence_id: String, starter_id: String = "") -> void:
	# Hide overlays so nothing paints over the cutscene.
	if _chrome:
		_chrome.visible = false
	if _starter_panel and is_instance_valid(_starter_panel):
		_starter_panel.visible = false
	if _create_panel and is_instance_valid(_create_panel):
		_create_panel.visible = false
	var cut := preload("res://scripts/boot/intro_cutscene.gd").new()
	cut.sequence_id = sequence_id
	cut.starter_id = starter_id
	cut.z_index = 40
	add_child(cut)
	await cut.finished
	# Do NOT restore chrome here — caller decides what screen comes next.
