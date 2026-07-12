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
var _avatar_detail: Label

const CREATE_PAD := 6
const CREATE_W := VIEW_W - CREATE_PAD * 2
const C_CREATE_GOLD := Color("ffe08a")
const C_CREATE_MINT := Color("52b788")
const C_CREATE_ICE := Color("cfe8ff")
const C_CREATE_LINE := Color("3a5a78", 0.55)
const C_CREATE_PANEL := Color("101a2c", 0.78)


func _ready() -> void:
	custom_minimum_size = Vector2(VIEW_W, VIEW_H)
	size = Vector2(VIEW_W, VIEW_H)
	SceneRouter.ensure_visible()
	_build_scene()
	_build_menu()


func _build_scene() -> void:
	var backdrop := preload("res://scripts/ui/title_backdrop.gd").new()
	backdrop.z_index = -1
	backdrop.name = "TitleBackdrop"
	add_child(backdrop)

	# All title chrome lives here so cutscenes can hide it cleanly.
	_chrome = Control.new()
	_chrome.size = Vector2(VIEW_W, VIEW_H)
	_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chrome.z_index = 1
	add_child(_chrome)

	# Single clean title - no glow + shadow + outline stack (that garbles pixel fonts).
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
	var title_bg := get_node_or_null("TitleBackdrop")
	if title_bg:
		title_bg.visible = false

	_picked_avatar = "keeper"
	_avatar_frames.clear()
	_avatar_detail = null
	if _create_panel and is_instance_valid(_create_panel):
		_create_panel.queue_free()
		_create_panel = null

	_create_panel = Control.new()
	_create_panel.position = Vector2.ZERO
	_create_panel.size = Vector2(VIEW_W, VIEW_H)
	_create_panel.z_index = 20
	_create_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_create_panel.clip_contents = true
	add_child(_create_panel)

	_paint_create_bg(_create_panel)

	var title := Label.new()
	title.text = "Who are you?"
	title.position = Vector2(0, 4)
	title.size = Vector2(VIEW_W, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TitleFonts.apply(title, 8, Color("fff0b0"), Color("1a1030"), 1)
	_create_panel.add_child(title)

	var sub := Label.new()
	sub.text = "Choose a look"
	sub.position = Vector2(0, 18)
	sub.size = Vector2(VIEW_W, 10)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TitleFonts.apply(sub, 5, Color("a8e8dc"))
	_create_panel.add_child(sub)

	const SLOT_W := 58
	const SLOT_H := 52
	const GAP := 8
	var accents := {
		"keeper": Color("ff8a7a"),
		"curly": Color("ff9ad0"),
		"cap": Color("5ad4c8"),
	}
	var total := PlayerAvatarScript.IDS.size() * SLOT_W + (PlayerAvatarScript.IDS.size() - 1) * GAP
	var x0 := (VIEW_W - total) / 2
	var y0 := 32

	for i in PlayerAvatarScript.IDS.size():
		var id: String = PlayerAvatarScript.IDS[i]
		_avatar_slot(
			id,
			Vector2(x0 + i * (SLOT_W + GAP), y0),
			Vector2(SLOT_W, SLOT_H),
			accents.get(id, C_CREATE_GOLD)
		)

	for i in PlayerAvatarScript.IDS.size():
		var id2: String = PlayerAvatarScript.IDS[i]
		var nl := Label.new()
		nl.position = Vector2(x0 + i * (SLOT_W + GAP) - 2, y0 + SLOT_H + 2)
		nl.size = Vector2(SLOT_W + 4, 10)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nl.clip_text = true
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		TitleFonts.apply(nl, 5, Color("f0f8ff"))
		nl.text = PlayerAvatarScript.LABELS.get(id2, id2)
		_create_panel.add_child(nl)
		_avatar_frames[id2].set_meta("name_label", nl)

	_avatar_detail = Label.new()
	_avatar_detail.position = Vector2(8, 98)
	_avatar_detail.size = Vector2(VIEW_W - 16, 10)
	_avatar_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_avatar_detail.clip_text = true
	_avatar_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TitleFonts.apply(_avatar_detail, 5, Color("cfe8ff"))
	_create_panel.add_child(_avatar_detail)

	var name_lbl := Label.new()
	name_lbl.text = "Your name"
	name_lbl.position = Vector2(0, 110)
	name_lbl.size = Vector2(VIEW_W, 10)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TitleFonts.apply(name_lbl, 5, Color("fff0b0"))
	_create_panel.add_child(name_lbl)

	_name_field = LineEdit.new()
	_name_field.position = Vector2(60, 122)
	_name_field.size = Vector2(120, 14)
	_name_field.custom_minimum_size = Vector2(120, 14)
	_name_field.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_name_field.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_name_field.max_length = PlayerAvatarScript.MAX_NAME_LEN
	_name_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_field.virtual_keyboard_enabled = true
	_name_field.focus_mode = Control.FOCUS_ALL
	_name_field.text = PlayerAvatarScript.DEFAULT_NAMES[_picked_avatar]
	_name_field.placeholder_text = "Name"
	TitleFonts.apply(_name_field, 6, Color("fff8e8"))
	_name_field.add_theme_stylebox_override("normal", _create_box(Color("102030", 0.95), Color("5ad4c8")))
	_name_field.add_theme_stylebox_override("focus", _create_box(Color("183848", 0.98), Color("fff0b0")))
	_name_field.add_theme_color_override("font_color", Color("fff8e8"))
	_name_field.add_theme_color_override("font_placeholder_color", Color("6a88a0"))
	_name_field.add_theme_color_override("caret_color", Color("fff0b0"))
	_create_panel.add_child(_name_field)

	var go := Button.new()
	go.position = Vector2(70, 140)
	go.size = Vector2(100, 16)
	go.custom_minimum_size = Vector2(100, 16)
	go.focus_mode = Control.FOCUS_NONE
	go.clip_text = true
	TitleFonts.apply(go, 6, Color("1a2030"))
	go.text = "Let's go!"
	go.add_theme_color_override("font_hover_color", Color("1a2030"))
	go.add_theme_color_override("font_pressed_color", Color("0c141c"))
	go.add_theme_stylebox_override("normal", _create_box(Color("ffe08a"), Color("fff6c8")))
	go.add_theme_stylebox_override("hover", _create_box(Color("fff0b0"), Color("ffffff")))
	go.add_theme_stylebox_override("pressed", _create_box(Color("5ad4c8"), Color("c0fff0")))
	go.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	go.pressed.connect(_on_confirm_character)
	_create_panel.add_child(go)

	_update_avatar_selection()


func _paint_create_bg(parent: Control) -> void:
	for y in VIEW_H:
		var t := float(y) / float(VIEW_H - 1)
		var col: Color
		if t < 0.55:
			col = Color("1a2858").lerp(Color("6a90d0"), t / 0.55)
		elif t < 0.72:
			col = Color("6a90d0").lerp(Color("f0b878"), (t - 0.55) / 0.17)
		else:
			col = Color("3a8a48").lerp(Color("2a6a38"), (t - 0.72) / 0.28)
		var row := ColorRect.new()
		row.color = col
		row.position = Vector2(0, y)
		row.size = Vector2(VIEW_W, 1)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(row)
	var top_dim := ColorRect.new()
	top_dim.color = Color(0.02, 0.05, 0.12, 0.35)
	top_dim.position = Vector2.ZERO
	top_dim.size = Vector2(VIEW_W, 30)
	top_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(top_dim)
	var bot_dim := ColorRect.new()
	bot_dim.color = Color(0.02, 0.05, 0.1, 0.4)
	bot_dim.position = Vector2(0, 108)
	bot_dim.size = Vector2(VIEW_W, 52)
	bot_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bot_dim)


func _avatar_slot(id: String, pos: Vector2, sz: Vector2, accent: Color) -> void:
	var frame := Panel.new()
	frame.position = pos
	frame.size = sz
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_meta("accent", accent)
	var base := StyleBoxFlat.new()
	base.bg_color = Color("102438", 0.92)
	base.border_color = accent
	base.set_border_width_all(2)
	base.set_corner_radius_all(5)
	frame.add_theme_stylebox_override("panel", base)
	_create_panel.add_child(frame)
	_avatar_frames[id] = frame

	var floor := ColorRect.new()
	floor.color = Color(accent.r, accent.g, accent.b, 0.28)
	floor.position = Vector2(6, sz.y - 10)
	floor.size = Vector2(sz.x - 12, 5)
	floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(floor)

	var spr := Sprite2D.new()
	spr.texture = PlayerAvatarScript.idle_preview_texture(id)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.centered = true
	spr.position = Vector2(sz.x * 0.5, sz.y * 0.42)
	spr.scale = Vector2(2.0, 2.0)
	frame.add_child(spr)

	var hit := Button.new()
	hit.position = Vector2.ZERO
	hit.size = sz
	hit.focus_mode = Control.FOCUS_NONE
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hit.pressed.connect(_on_pick_avatar.bind(id))
	frame.add_child(hit)


func _create_box(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
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
		var accent: Color = frame.get_meta("accent", C_CREATE_GOLD)
		var box := StyleBoxFlat.new()
		if sel:
			box.bg_color = Color(accent.r * 0.4, accent.g * 0.3, accent.b * 0.25, 0.95)
			box.border_color = Color("fff0b0")
			box.set_border_width_all(2)
			box.shadow_color = Color(accent.r, accent.g, accent.b, 0.5)
			box.shadow_size = 3
		else:
			box.bg_color = Color("102438", 0.88)
			box.border_color = Color(accent.r, accent.g, accent.b, 0.7)
			box.set_border_width_all(2)
		box.set_corner_radius_all(5)
		frame.add_theme_stylebox_override("panel", box)
		var nm: Label = frame.get_meta("name_label", null)
		if nm:
			nm.text = PlayerAvatarScript.LABELS.get(id, id)
			TitleFonts.apply(nm, 5, Color("fff0b0") if sel else Color("e8f4ff"))
	if _avatar_detail:
		_avatar_detail.text = PlayerAvatarScript.BLURBS.get(_picked_avatar, "")
		TitleFonts.apply(_avatar_detail, 5, Color("cfe8ff"))


func _on_confirm_character() -> void:
	var typed := _name_field.text if _name_field else ""
	GameState.set_player_identity(typed, _picked_avatar)
	if _create_panel:
		_create_panel.visible = false
	_show_starter_select()



func _show_starter_select() -> void:
	# Keep title chrome hidden - it was bleeding over this panel.
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
		_starter_panel, "%s - choose your first %s" % [GameState.player_name, GameStrings.CREATURE], 7, Color("fff0b0"),
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
	# Do NOT restore chrome here - caller decides what screen comes next.
