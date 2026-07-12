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
	_avatar_detail = null

	_create_panel = Control.new()
	_create_panel.position = Vector2.ZERO
	_create_panel.size = Vector2(VIEW_W, VIEW_H)
	_create_panel.z_index = 20
	_create_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_create_panel.clip_contents = true
	add_child(_create_panel)

	# Same warm valley sky as the title — inviting, not a dark void.
	var backdrop := preload("res://scripts/ui/title_backdrop.gd").new()
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.z_index = -2
	_create_panel.add_child(backdrop)

	# Soft scrim so text stays readable over animated hills.
	var scrim := ColorRect.new()
	scrim.color = Color("0a1830", 0.42)
	scrim.position = Vector2.ZERO
	scrim.size = Vector2(VIEW_W, VIEW_H)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.z_index = -1
	_create_panel.add_child(scrim)

	TitleFonts.shadow_label(
		_create_panel, "Who are you?", 8, Color("fff0b0"),
		Vector2(4, 6), Vector2(VIEW_W - 8, 14),
		HORIZONTAL_ALIGNMENT_CENTER, Color("1a1030"), 1, 0
	)
	TitleFonts.shadow_label(
		_create_panel, "Pick a look, then give yourself a name", 5, Color("cfe8ff"),
		Vector2(8, 22), Vector2(VIEW_W - 16, 10),
		HORIZONTAL_ALIGNMENT_CENTER, Color(), 0, 0
	)

	# Compact portraits — sprite-first, labels below (never clipped inside).
	const CARD_W := 56
	const CARD_H := 48
	const CARD_GAP := 10
	var accents := {
		"keeper": Color("ff7a6a"),
		"curly": Color("ffa0d0"),
		"cap": Color("5ad4c8"),
	}
	var row_w := PlayerAvatarScript.IDS.size() * CARD_W + (PlayerAvatarScript.IDS.size() - 1) * CARD_GAP
	var row_x := (VIEW_W - row_w) / 2
	var row_y := 36

	for i in PlayerAvatarScript.IDS.size():
		var id: String = PlayerAvatarScript.IDS[i]
		var accent: Color = accents.get(id, C_CREATE_GOLD)
		var pos := Vector2(row_x + i * (CARD_W + CARD_GAP), row_y)
		_avatar_card(id, pos, Vector2(CARD_W, CARD_H), accent)

	_update_avatar_selection()

	_avatar_detail = Label.new()
	_create_pin(_avatar_detail, Vector2(CREATE_PAD, 98), Vector2(CREATE_W, 10))
	_avatar_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_avatar_detail.clip_text = true
	_avatar_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_panel.add_child(_avatar_detail)

	TitleFonts.shadow_label(
		_create_panel, "Your name", 5, Color("fff0b0"),
		Vector2(8, 110), Vector2(VIEW_W - 16, 10),
		HORIZONTAL_ALIGNMENT_CENTER, Color(), 0, 0
	)

	_name_field = _create_name_field()
	_name_field.text = PlayerAvatarScript.DEFAULT_NAMES[_picked_avatar]
	_name_field.placeholder_text = "Name..."
	_create_panel.add_child(_name_field)

	var btn_h := 18
	if TouchUtil != null and TouchUtil.is_touch_ui_enabled():
		btn_h = 22
	var go := _create_action_btn("Let's go!", _on_confirm_character, Vector2(70, 142), Vector2(100, btn_h))
	_create_panel.add_child(go)


func _avatar_card(id: String, pos: Vector2, sz: Vector2, accent: Color) -> void:
	var wrap := Control.new()
	wrap.position = pos
	wrap.size = Vector2(sz.x, sz.y + 12)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_panel.add_child(wrap)

	var frame := Panel.new()
	frame.position = Vector2.ZERO
	frame.size = sz
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_meta("accent", accent)
	wrap.add_child(frame)
	_avatar_frames[id] = frame

	# Soft floor glow under the figure.
	var glow := ColorRect.new()
	glow.color = Color(accent.r, accent.g, accent.b, 0.22)
	glow.position = Vector2(8, sz.y - 14)
	glow.size = Vector2(sz.x - 16, 6)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(glow)

	var preview := TextureRect.new()
	preview.texture = PlayerAvatarScript.idle_preview_texture(id)
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.position = Vector2((sz.x - 20) / 2.0, 4)
	preview.size = Vector2(20, 36)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(preview)

	# Name sits below the card — never overlapping the border.
	var nm := Label.new()
	nm.position = Vector2(-2, sz.y + 1)
	nm.size = Vector2(sz.x + 4, 10)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.clip_text = true
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nm.set_meta("name_label", true)
	TitleFonts.fit_label(nm, PlayerAvatarScript.LABELS.get(id, id), sz.x + 4, Color("f0f8ff"), 5, 4)
	wrap.add_child(nm)
	frame.set_meta("name_label", nm)

	var hit := Button.new()
	hit.position = Vector2.ZERO
	hit.size = Vector2(sz.x, sz.y + 12)
	hit.focus_mode = Control.FOCUS_NONE
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hit.pressed.connect(_on_pick_avatar.bind(id))
	wrap.add_child(hit)


func _create_name_field() -> LineEdit:
	var f := LineEdit.new()
	_create_pin(f, Vector2(48, 122), Vector2(144, 16))
	f.max_length = PlayerAvatarScript.MAX_NAME_LEN
	f.alignment = HORIZONTAL_ALIGNMENT_CENTER
	f.virtual_keyboard_enabled = true
	f.focus_mode = Control.FOCUS_ALL
	TitleFonts.apply(f, 7, Color("fff8e8"))
	f.add_theme_stylebox_override("normal", _create_box(Color("142838", 0.88), Color("5ad4c8", 0.85)))
	f.add_theme_stylebox_override("focus", _create_box(Color("1a3850", 0.95), Color("fff0b0")))
	f.add_theme_color_override("font_color", Color("fff8e8"))
	f.add_theme_color_override("font_placeholder_color", Color("7aa0b8"))
	f.add_theme_color_override("caret_color", Color("fff0b0"))
	return f


func _create_action_btn(text: String, cb: Callable, pos: Vector2, sz: Vector2) -> Button:
	var b := Button.new()
	_create_pin(b, pos, sz)
	b.clip_text = true
	b.focus_mode = Control.FOCUS_NONE
	TitleFonts.fit_label(b, text, sz.x - 6, Color("142028"), 6, 5)
	b.add_theme_color_override("font_hover_color", Color("142028"))
	b.add_theme_color_override("font_pressed_color", Color("0c1820"))
	var normal := _create_box(Color("ffe08a"), Color("fff0b0"))
	normal.set_corner_radius_all(5)
	var hover := _create_box(Color("fff0b0"), Color("ffffff"))
	hover.set_corner_radius_all(5)
	var pressed := _create_box(Color("5ad4c8"), Color("a8f0e0"))
	pressed.set_corner_radius_all(5)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(cb)
	return b


func _create_pin(node: Control, pos: Vector2, sz: Vector2) -> void:
	node.position = pos
	node.size = sz
	node.custom_minimum_size = sz


func _create_box(bg: Color, border: Color) -> StyleBoxFlat:
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
			box.bg_color = Color(accent.r * 0.35, accent.g * 0.28, accent.b * 0.22, 0.82)
			box.border_color = accent
			box.set_border_width_all(2)
			box.shadow_color = Color(accent.r, accent.g, accent.b, 0.45)
			box.shadow_size = 3
		else:
			box.bg_color = Color("0c2030", 0.55)
			box.border_color = Color(accent.r, accent.g, accent.b, 0.45)
			box.set_border_width_all(1)
		box.set_corner_radius_all(6)
		frame.add_theme_stylebox_override("panel", box)
		var nm: Label = frame.get_meta("name_label", null)
		if nm:
			TitleFonts.fit_label(
				nm,
				PlayerAvatarScript.LABELS.get(id, id),
				nm.size.x,
				Color("fff0b0") if sel else Color("d8e8f8"),
				5,
				4
			)
	if _avatar_detail:
		TitleFonts.fit_label(
			_avatar_detail,
			PlayerAvatarScript.BLURBS.get(_picked_avatar, ""),
			CREATE_W,
			Color("a8e8dc"),
			5,
			4
		)


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
