extends Control

## Versus draft: CPU rival or online friend on another device.

const TitleFonts := preload("res://scripts/ui/title_fonts.gd")

const VIEW_W := 240
const VIEW_H := 160
const RIVAL_NAMES := ["Rival Sabo", "Ace Nova", "Champion Wren", "Duelist Kai", "Mystic Lune", "Brawler Rex"]
const RES_FILTER := [-1, EchoTypes.Resonance.FIRE, EchoTypes.Resonance.WATER, EchoTypes.Resonance.GRASS, EchoTypes.Resonance.ROCK, EchoTypes.Resonance.AIR, EchoTypes.Resonance.SHADOW]
const ECHO_BOX_H := 48
const ECHO_NAME_H := 12
const ECHO_COLS := 4
const ECHO_GAP := 2
const PAD := 6
const W := VIEW_W - PAD * 2

# Echo Valley versus palette (matches title screen)
const C_SKY_TOP := Color("1a1030")
const C_SKY_MID := Color("2a2858")
const C_SKY_BOT := Color("0d1520")
const C_GOLD := Color("ffe08a")
const C_GOLD_DIM := Color("ffd166")
const C_MINT := Color("52b788")
const C_ICE := Color("cfe8ff")
const C_CPU := Color("4a9eff")
const C_PVP := Color("c49bff")
const C_SOFT := Color("0c1424")
const C_PANEL := Color("101a2c", 0.78)
const C_LINE := Color("3a5a78", 0.55)

enum Screen { MODE, CPU, ONLINE, DRAFT }

var _screen: int = Screen.MODE
var _online: bool = false
var _team_size: int = 3
var _level: int = 15
var _filter_idx: int = 0
var _selected: Array[String] = []
var _buttons: Dictionary = {}
var _room_code: String = ""

var _root: Control
var _status: Label
var _action_btn: Button
var _code_lbl: Label
var _join_field: LineEdit


func _ready() -> void:
	clip_contents = true
	custom_minimum_size = Vector2(VIEW_W, VIEW_H)
	size = Vector2(VIEW_W, VIEW_H)
	SceneRouter.ensure_visible()
	VersusNet.room_updated.connect(_on_room_updated)
	VersusNet.battle_start.connect(_on_battle_start)
	VersusNet.net_error.connect(_on_net_error)
	call_deferred("_rebuild")


func _exit_tree() -> void:
	pass


func _disconnect_lobby() -> void:
	if VersusNet.lobby_open():
		VersusNet.disconnect_lobby()


func _rebuild() -> void:
	if _root:
		_root.queue_free()
		_root = null
	_buttons.clear()

	var bg := Control.new()
	_pin(bg, Vector2.ZERO, Vector2(VIEW_W, VIEW_H))
	bg.clip_contents = true
	add_child(bg)
	_root = bg
	_paint_backdrop(bg)

	match _screen:
		Screen.MODE:
			_build_mode(bg)
		Screen.CPU:
			_online = false
			_build_draft(bg, "PLAYER VS CPU")
		Screen.ONLINE:
			_build_online(bg)
		Screen.DRAFT:
			_build_draft(bg, "PLAYER VS PLAYER")


func _build_mode(parent: Control) -> void:
	# Animated showdown: two Harmons squaring off with a pulsing VS.
	var showdown := preload("res://scripts/boot/versus_mode_backdrop.gd").new()
	showdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(showdown)

	# Title with warm glow, above the arena.
	var glow := Label.new()
	glow.text = "VERSUS"
	_pin(glow, Vector2(0, 5), Vector2(VIEW_W, 18))
	glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TitleFonts.apply(glow, 13, Color("ffd166", 0.35))
	parent.add_child(glow)
	var title := Label.new()
	title.text = "VERSUS"
	_pin(title, Vector2(0, 4), Vector2(VIEW_W, 18))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TitleFonts.apply(title, 13, Color("ffe8a8"), Color("2a1030"), 2)
	parent.add_child(title)

	var tag := Label.new()
	tag.text = "choose your arena"
	_pin(tag, Vector2(0, 22), Vector2(VIEW_W, 8))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TitleFonts.apply(tag, 5, Color("a8dcff", 0.8))
	parent.add_child(tag)

	# Choice cards along the bottom, colour-matched to each fighter's side.
	var cw := 112
	var ch := 32
	var cy := 104
	parent.add_child(_showdown_card(
		"VS CPU", "draft & duel",
		Vector2(PAD, cy), Vector2(cw, ch), C_CPU, _go_cpu
	))
	parent.add_child(_showdown_card(
		"ONLINE", "play a friend",
		Vector2(VIEW_W - PAD - cw, cy), Vector2(cw, ch), C_PVP, _go_online
	))

	_btn_at(parent, Vector2(PAD, 141), Vector2(52, 16), "Back", _on_back)


func _showdown_card(title: String, subtitle: String, pos: Vector2, sz: Vector2, accent: Color, cb: Callable) -> Panel:
	var card := Panel.new()
	card.position = pos
	card.size = sz
	card.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r * 0.16, accent.g * 0.16, accent.b * 0.22, 0.86)
	sb.border_color = accent
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.4)
	sb.shadow_size = 3
	card.add_theme_stylebox_override("panel", sb)

	# Accent glow strip along the top edge.
	var strip := ColorRect.new()
	strip.color = Color(accent.r, accent.g, accent.b, 0.85)
	strip.position = Vector2(0, 0)
	strip.size = Vector2(sz.x, 2)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(strip)

	var t := Label.new()
	t.position = Vector2(2, 7)
	t.size = Vector2(sz.x - 4, 10)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	TitleFonts.fit_label(t, title, sz.x - 4, Color("ffffff"), 5, 4)
	card.add_child(t)

	var s := Label.new()
	s.text = subtitle
	s.position = Vector2(4, 20)
	s.size = Vector2(sz.x - 8, 10)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.clip_text = true
	TitleFonts.apply(s, 5, Color(accent.r + 0.35, accent.g + 0.35, accent.b + 0.35, 0.95))
	card.add_child(s)

	var hit := Button.new()
	hit.position = Vector2.ZERO
	hit.size = sz
	hit.custom_minimum_size = sz
	hit.focus_mode = Control.FOCUS_NONE
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", _box(Color(accent.r, accent.g, accent.b, 0.22), Color(1, 1, 1)))
	hit.add_theme_stylebox_override("pressed", _box(Color(0, 0, 0, 0.25), accent))
	hit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hit.pressed.connect(cb)
	card.add_child(hit)
	return card


func _build_online(parent: Control) -> void:
	_soft_title(parent, "PLAYER VS PLAYER", "host or join a room")
	_status = _caption(parent, "Connect, then share your room code.", 28)

	_label_in(parent, Vector2(PAD, 42), Vector2(60, 10), "YOUR NAME", 5, Color("7c8aa0"), false)
	_join_field = _styled_field(Vector2(PAD, 52), Vector2(110, 18))
	_join_field.text = "Player"
	parent.add_child(_join_field)

	_chip(parent, Vector2(PAD, 76), Vector2(52, 16), "Host", _host_room, false, C_PVP)
	_chip(parent, Vector2(62, 76), Vector2(52, 16), "Join", _join_room, false, C_CPU)

	_label_in(parent, Vector2(122, 42), Vector2(110, 10), "ROOM CODE", 5, Color("7c8aa0"), false)
	_code_lbl = Label.new()
	_code_lbl.text = "------"
	_pin(_code_lbl, Vector2(122, 52), Vector2(110, 18))
	_code_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	TitleFonts.apply(_code_lbl, 10, C_GOLD, Color("1a1030"), 1)
	parent.add_child(_code_lbl)

	var code_in := _styled_field(Vector2(122, 76), Vector2(110, 18))
	code_in.name = "code_in"
	code_in.placeholder_text = "ENTER CODE"
	code_in.max_length = 6
	parent.add_child(code_in)

	_action_btn = null
	_draft_footer(parent, _on_back, Callable(), "", "Draft", _go_online_draft, true)


func _build_draft(parent: Control, title: String) -> void:
	var accent := C_CPU if not _online else C_PVP
	_soft_title(parent, title, "")

	# Team tray — shows selected Harmons as the focal composition.
	_build_team_tray(parent, accent)

	# Option chips — auto-laid out so labels never overlap.
	_build_chip_row(parent, accent)

	# Harmon picker grid — sized to fit exactly inside the panel.
	var grid_y := 68
	var grid_h := 58
	var grid_inner := W - 6
	var echo_w := _echo_card_width(grid_inner)
	var echo_box := Vector2i(echo_w, ECHO_BOX_H)
	var grid_panel := Panel.new()
	_pin(grid_panel, Vector2(PAD, grid_y), Vector2(W, grid_h))
	grid_panel.clip_contents = true
	var gsb := StyleBoxFlat.new()
	gsb.bg_color = C_PANEL
	gsb.border_color = C_LINE
	gsb.set_border_width_all(1)
	gsb.set_corner_radius_all(4)
	grid_panel.add_theme_stylebox_override("panel", gsb)
	parent.add_child(grid_panel)

	var scroll := ScrollContainer.new()
	_pin(scroll, Vector2(3, 3), Vector2(grid_inner, grid_h - 6))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	grid_panel.add_child(scroll)

	var ids := _filtered_ids()
	var rows := ceili(float(ids.size()) / float(ECHO_COLS))
	var content_h := maxi(echo_box.y, rows * (echo_box.y + ECHO_GAP) - ECHO_GAP)
	var content := Control.new()
	_pin(content, Vector2.ZERO, Vector2(grid_inner, content_h))
	content.custom_minimum_size = Vector2(grid_inner, content_h)
	scroll.add_child(content)

	for i in ids.size():
		var col := i % ECHO_COLS
		var row := i / ECHO_COLS
		var box := _echo_box(ids[i], echo_box)
		box.position = Vector2(col * (echo_box.x + ECHO_GAP), row * (echo_box.y + ECHO_GAP))
		content.add_child(box)

	_status = Label.new()
	_pin(_status, Vector2(PAD, 128), Vector2(W, 8))
	TitleFonts.apply(_status, 5, Color("a8c8dc"))
	parent.add_child(_status)

	_draft_footer(parent, _on_back, _random_team, "Random", "Battle!" if not _online else "Ready!", _on_action, true)
	_update_status()


func _echo_card_width(inner_w: int) -> int:
	return (inner_w - (ECHO_COLS - 1) * ECHO_GAP) / ECHO_COLS


func _build_chip_row(parent: Control, accent: Color) -> void:
	var row := HBoxContainer.new()
	_pin(row, Vector2(PAD, 50), Vector2(W, 14))
	row.add_theme_constant_override("separation", 3)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	parent.add_child(row)

	_chip_in(row, "1v1", func(): _set_team_size(1), _team_size == 1, accent, 26)
	_chip_in(row, "3v3", func(): _set_team_size(3), _team_size == 3, accent, 26)
	_chip_in(row, "Lv15", func(): _set_level(15), _level == 15, C_GOLD_DIM, 30)
	_chip_in(row, "Lv30", func(): _set_level(30), _level == 30, C_GOLD_DIM, 30)
	_chip_in(row, "Lv50", func(): _set_level(50), _level == 50, C_GOLD_DIM, 30)
	_chip_in(row, _filter_short(), _cycle_filter, true, C_MINT, 0)


func _chip_in(parent: BoxContainer, text: String, cb: Callable, on: bool, accent: Color, min_w: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(min_w, 14)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL if min_w <= 0 else Control.SIZE_SHRINK_CENTER
	b.clip_text = true
	b.focus_mode = Control.FOCUS_NONE
	var text_w := maxf(8.0, float(min_w) - 4.0) if min_w > 0 else 40.0
	TitleFonts.fit_label(b, text, text_w, Color("f2f7ff") if on else Color("a8b8c8"), 5, 4)
	var bg := Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.4, 0.95) if on else Color("121c2c", 0.85)
	var border := accent if on else Color("2a3a50")
	b.add_theme_stylebox_override("normal", _soft_box(bg, border))
	b.add_theme_stylebox_override("hover", _soft_box(Color(accent.r, accent.g, accent.b, 0.25), Color.WHITE))
	b.add_theme_stylebox_override("pressed", _soft_box(Color("0a1220"), accent))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _build_team_tray(parent: Control, accent: Color) -> void:
	var tray_y := 14
	var slot_w := 36
	var slot_h := 22
	var gap := 4
	var total_w := _team_size * slot_w + (_team_size - 1) * gap
	var start_x := (VIEW_W - total_w) / 2.0

	var label := Label.new()
	label.text = "YOUR TEAM"
	_pin(label, Vector2(PAD, tray_y), Vector2(60, 8))
	TitleFonts.apply(label, 5, Color(accent.r, accent.g, accent.b, 0.85))
	parent.add_child(label)

	var count := Label.new()
	count.text = "%d / %d" % [_selected.size(), _team_size]
	_pin(count, Vector2(VIEW_W - PAD - 40, tray_y), Vector2(40, 8))
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	TitleFonts.apply(count, 5, C_GOLD)
	parent.add_child(count)

	for i in _team_size:
		var slot := Panel.new()
		slot.position = Vector2(start_x + i * (slot_w + gap), tray_y + 8)
		slot.size = Vector2(slot_w, slot_h)
		slot.clip_contents = true
		var filled := i < _selected.size()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("142438", 0.9) if filled else Color("0a1220", 0.65)
		sb.border_color = accent if filled else Color("2a3a50", 0.7)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(3)
		slot.add_theme_stylebox_override("panel", sb)
		parent.add_child(slot)

		if filled:
			var id: String = _selected[i]
			var def := EchoCatalog.get_echo(id)
			if def and ResourceLoader.exists(def.sprite_path):
				var icon := TextureRect.new()
				icon.texture = load(def.sprite_path)
				icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.position = Vector2(4, 1)
				icon.size = Vector2(28, 20)
				slot.add_child(icon)
			var num := Label.new()
			num.text = str(i + 1)
			num.position = Vector2(1, 1)
			num.size = Vector2(10, 8)
			TitleFonts.apply(num, 5, C_GOLD)
			slot.add_child(num)
		else:
			var dash := Label.new()
			dash.text = "+"
			dash.position = Vector2.ZERO
			dash.size = Vector2(slot_w, slot_h)
			dash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dash.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			TitleFonts.apply(dash, 8, Color("3a5070"))
			slot.add_child(dash)


func _echo_box(id: String, box_sz: Vector2i) -> Control:
	var def := EchoCatalog.get_echo(id)
	var selected := id in _selected
	var box := Panel.new()
	box.custom_minimum_size = Vector2(box_sz.x, box_sz.y)
	box.size = Vector2(box_sz.x, box_sz.y)
	box.clip_contents = true
	var sb := StyleBoxFlat.new()
	if selected:
		sb.bg_color = Color("1a3a30", 0.85)
		sb.border_color = C_GOLD
		sb.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
		sb.shadow_size = 2
	else:
		sb.bg_color = Color("0c1420", 0.55)
		sb.border_color = Color("243848", 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	box.add_theme_stylebox_override("panel", sb)

	var art_w := box_sz.x - 10
	var art_h := box_sz.y - ECHO_NAME_H - 4
	var icon := TextureRect.new()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.position = Vector2((box_sz.x - art_w) / 2, 2)
	icon.size = Vector2(art_w, art_h)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if def and ResourceLoader.exists(def.sprite_path):
		icon.texture = load(def.sprite_path)
	box.add_child(icon)

	if def:
		var emblem := TypeEmblem.create(int(def.resonance), 9)
		emblem.position = Vector2(2, 2)
		emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(emblem)

	if selected:
		var check := Label.new()
		check.text = str(_selected.find(id) + 1)
		check.position = Vector2(box_sz.x - 12, 1)
		check.size = Vector2(10, 8)
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		TitleFonts.apply(check, 5, C_GOLD)
		box.add_child(check)

	var name_y := box_sz.y - ECHO_NAME_H - 2
	var name_lbl := Label.new()
	name_lbl.position = Vector2(1, name_y)
	name_lbl.size = Vector2(box_sz.x - 2, ECHO_NAME_H)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	name_lbl.clip_text = false
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.z_index = 1
	TitleFonts.fit_label(name_lbl, def.name if def else id, box_sz.x - 2, Color("e8f4ff") if selected else Color("a8c0d8"), 5, 3)
	box.add_child(name_lbl)

	var hit := Button.new()
	hit.position = Vector2.ZERO
	hit.size = Vector2(box_sz.x, name_y + 2)
	hit.custom_minimum_size = hit.size
	hit.toggle_mode = true
	hit.button_pressed = selected
	hit.focus_mode = Control.FOCUS_NONE
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hit.pressed.connect(_on_toggle.bind(id, hit))
	box.add_child(hit)
	_buttons[id] = hit
	return box


func _filter_short() -> String:
	if _filter_idx == 0:
		return "All"
	var res := RES_FILTER[_filter_idx] as EchoTypes.Resonance
	return String(EchoTypes.RESONANCE_NAMES.get(res, "?"))


func _filter_label() -> String:
	if _filter_idx == 0:
		return "All (%d)" % _count_for_filter(0)
	var res := RES_FILTER[_filter_idx] as EchoTypes.Resonance
	var name: String = EchoTypes.RESONANCE_NAMES.get(res, "?")
	return "%s (%d)" % [name, _count_for_filter(_filter_idx)]


func _count_for_filter(idx: int) -> int:
	var want: int = RES_FILTER[idx]
	var n := 0
	for id in EchoCatalog.all_echo_ids():
		var def := EchoCatalog.get_echo(id)
		if def == null:
			continue
		if want >= 0 and int(def.resonance) != want:
			continue
		n += 1
	return n


func _filtered_ids() -> Array[String]:
	var out: Array[String] = []
	var want: int = RES_FILTER[_filter_idx]
	for id in EchoCatalog.all_echo_ids():
		var def := EchoCatalog.get_echo(id)
		if def == null:
			continue
		if want >= 0 and int(def.resonance) != want:
			continue
		out.append(id)
	out.sort_custom(func(a, b): return EchoCatalog.get_echo(a).name < EchoCatalog.get_echo(b).name)
	return out


func _set_team_size(n: int) -> void:
	_team_size = n
	_selected.clear()
	if _online and VersusNet.role == "host":
		VersusNet.set_options(_team_size, _level)
	_rebuild()


func _set_level(lv: int) -> void:
	_level = lv
	_selected.clear()
	if _online and VersusNet.role == "host":
		VersusNet.set_options(_team_size, _level)
	_rebuild()


func _cycle_filter() -> void:
	_filter_idx = (_filter_idx + 1) % RES_FILTER.size()
	_selected.clear()
	_rebuild()


func _go_cpu() -> void:
	_screen = Screen.CPU
	_selected.clear()
	_rebuild()


func _go_online() -> void:
	_screen = Screen.ONLINE
	_rebuild()


func _go_online_draft() -> void:
	_screen = Screen.DRAFT
	_online = true
	_selected.clear()
	_rebuild()


func _host_room() -> void:
	if not await _ensure_net():
		return
	VersusNet.create_room(_player_name())
	VersusNet.role = "host"
	_status.text = "Room created — share the code!"


func _join_room() -> void:
	if not await _ensure_net():
		return
	var code_in: LineEdit = _root.get_node_or_null("code_in") as LineEdit
	var code := code_in.text.to_upper().strip_edges() if code_in else ""
	if code.length() < 4:
		_status.text = "Enter a room code first."
		return
	VersusNet.join_room(code, _player_name())
	VersusNet.role = "guest"


func _ensure_net() -> bool:
	if VersusNet.lobby_open():
		return true
	var err := VersusNet.connect_lobby()
	if err != OK:
		_status.text = "Could not reach lobby server."
		return false
	return await VersusNet.wait_connected()


func _player_name() -> String:
	if GameState.player_name != "":
		return GameState.player_name.substr(0, 16)
	if _join_field:
		var n := _join_field.text.strip_edges()
		if n != "":
			return n.substr(0, 16)
	return "Player"


func _on_room_updated(r: Dictionary) -> void:
	_room_code = String(r.get("code", ""))
	if _code_lbl:
		_code_lbl.text = _room_code if _room_code != "" else "--------"
	_team_size = int(r.get("team_size", _team_size))
	_level = int(r.get("level", _level))
	if _status:
		if not bool(r.get("has_guest", false)):
			_status.text = "Waiting for friend to join..."
		else:
			_status.text = "%s vs %s — draft teams!" % [r.get("host_name", "Host"), r.get("guest_name", "Guest")]
	if _action_btn:
		_action_btn.disabled = not bool(r.get("has_guest", false))


func _on_battle_start(payload: Dictionary) -> void:
	var host_ids: Array = []
	var guest_ids: Array = []
	for id in payload.get("host_team", []):
		host_ids.append(String(id))
	for id in payload.get("guest_team", []):
		guest_ids.append(String(id))
	var lv := int(payload.get("level", 15))
	var role := String(payload.get("role", ""))
	if role == "host":
		SceneRouter.start_online_versus_battle(
			host_ids, guest_ids, String(payload.get("guest_name", "Guest")), true, lv)
	else:
		SceneRouter.start_online_versus_battle(
			guest_ids, host_ids, String(payload.get("host_name", "Host")), false, lv)


func _on_net_error(msg: String) -> void:
	if _status:
		_status.text = msg


func _on_toggle(id: String, btn: Button) -> void:
	if btn.button_pressed:
		if _selected.size() >= _team_size:
			btn.button_pressed = false
			return
		if id not in _selected:
			_selected.append(id)
	else:
		_selected.erase(id)
	if _online:
		VersusNet.set_team(_selected)
	_rebuild()


func _random_team() -> void:
	_selected.clear()
	var pool := _filtered_ids()
	pool.shuffle()
	for id in pool:
		if _selected.size() >= _team_size:
			break
		_selected.append(id)
	if _online:
		VersusNet.set_team(_selected)
	_rebuild()


func _update_status() -> void:
	var names: Array[String] = []
	for id in _selected:
		var d := EchoCatalog.get_echo(id)
		if d:
			names.append(d.name)
	var txt := ", ".join(names) if names.size() > 0 else "tap a Harmon to add"
	if _status:
		_status.text = txt
	if _action_btn:
		_action_btn.disabled = _selected.size() != _team_size


func _on_action() -> void:
	if _online:
		VersusNet.set_team(_selected)
		VersusNet.send_ready()
		if _status:
			_status.text = "Ready! Waiting for opponent..."
		_action_btn.disabled = true
		return
	var pool := _filtered_ids()
	if pool.is_empty():
		pool = EchoCatalog.all_echo_ids()
	pool.shuffle()
	var enemy_ids: Array[String] = []
	for id in pool:
		if enemy_ids.size() >= _team_size:
			break
		if id in _selected:
			continue
		enemy_ids.append(id)
	while enemy_ids.size() < _team_size:
		for id in pool:
			enemy_ids.append(id)
			if enemy_ids.size() >= _team_size:
				break
	var rival: String = RIVAL_NAMES[randi() % RIVAL_NAMES.size()]
	if _action_btn:
		_action_btn.disabled = true
	SceneRouter.start_versus_battle(_selected, enemy_ids, rival, _level)


func _on_back() -> void:
	match _screen:
		Screen.MODE:
			SceneRouter.go_to_title()
		Screen.CPU:
			_screen = Screen.MODE
			_selected.clear()
			_rebuild()
		Screen.ONLINE:
			_disconnect_lobby()
			_screen = Screen.MODE
			_rebuild()
		Screen.DRAFT:
			_screen = Screen.ONLINE
			_selected.clear()
			_rebuild()


# ---- ui helpers ------------------------------------------------------------
func _pin(node: Control, pos: Vector2, sz: Vector2) -> void:
	node.position = pos
	node.size = sz
	node.custom_minimum_size = sz


func _paint_backdrop(parent: Control) -> void:
	# Soft night gradient — not a flat navy void.
	var bg := Control.new()
	_pin(bg, Vector2.ZERO, Vector2(VIEW_W, VIEW_H))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_script(preload("res://scripts/boot/versus_draft_backdrop.gd"))
	parent.add_child(bg)


func _soft_title(parent: Control, text: String, sub: String) -> void:
	var title := Label.new()
	title.text = text
	_pin(title, Vector2(0, 2), Vector2(VIEW_W, 12))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TitleFonts.apply(title, 7, C_GOLD, Color("1a1030"), 1)
	parent.add_child(title)
	if sub != "":
		var s := Label.new()
		s.text = sub
		_pin(s, Vector2(0, 12), Vector2(VIEW_W, 8))
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		TitleFonts.apply(s, 5, Color("8ab0c8"))
		parent.add_child(s)


func _caption(parent: Control, text: String, y: int) -> Label:
	var l := Label.new()
	l.text = text
	_pin(l, Vector2(PAD, y), Vector2(W, 9))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	TitleFonts.apply(l, 5, C_ICE)
	parent.add_child(l)
	return l


func _label_in(parent: Control, pos: Vector2, sz: Vector2, text: String, font: int, col: Color, center: bool) -> Label:
	var l := Label.new()
	l.text = text
	_pin(l, pos, sz)
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", col)
	l.clip_text = true
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l


func _styled_field(pos: Vector2, sz: Vector2) -> LineEdit:
	var f := LineEdit.new()
	_pin(f, pos, sz)
	f.virtual_keyboard_enabled = true
	f.focus_mode = Control.FOCUS_ALL
	f.add_theme_font_size_override("font_size", 7)
	f.add_theme_stylebox_override("normal", _soft_box(Color("0c141c", 0.9), Color("3a5f8f")))
	f.add_theme_stylebox_override("focus", _soft_box(Color("14202b"), Color("8ec8ff")))
	f.add_theme_color_override("font_color", Color("e8f4ff"))
	f.add_theme_color_override("font_placeholder_color", Color("5a7088"))
	return f


func _soft_box(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(0)
	return sb


func _box(bg: Color, border: Color) -> StyleBoxFlat:
	return _soft_box(bg, border)


func _chip(parent: Control, pos: Vector2, sz: Vector2, text: String, cb: Callable, on: bool, accent: Color) -> Button:
	var b := Button.new()
	b.text = text
	_pin(b, pos, sz)
	b.clip_text = true
	b.focus_mode = Control.FOCUS_NONE
	TitleFonts.apply(b, 5, Color("f2f7ff") if on else Color("a8b8c8"))
	var bg := Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.4, 0.95) if on else Color("121c2c", 0.85)
	var border := accent if on else Color("2a3a50")
	b.add_theme_stylebox_override("normal", _soft_box(bg, border))
	b.add_theme_stylebox_override("hover", _soft_box(Color(accent.r, accent.g, accent.b, 0.25), Color.WHITE))
	b.add_theme_stylebox_override("pressed", _soft_box(Color("0a1220"), accent))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _btn_at(parent: Control, pos: Vector2, sz: Vector2, text: String, cb: Callable, on: bool = false) -> Button:
	return _chip(parent, pos, sz, text, cb, on, C_GOLD_DIM if on else Color("5a7a9a"))


func _draft_footer(
	parent: Control,
	back_cb: Callable,
	mid_cb: Callable = Callable(),
	mid_text: String = "Random",
	action_text: String = "",
	action_cb: Callable = Callable(),
	action_disabled: bool = false
) -> void:
	var fy := 138
	_chip(parent, Vector2(PAD, fy), Vector2(44, 16), "Back", back_cb, false, Color("5a7a9a"))
	if mid_cb.is_valid():
		_chip(parent, Vector2(54, fy), Vector2(52, 16), mid_text, mid_cb, false, C_MINT)
	if action_cb.is_valid() and action_text != "":
		_action_btn = _chip(parent, Vector2(VIEW_W - PAD - 72, fy), Vector2(72, 16), action_text, action_cb, true, C_GOLD)
		if action_disabled:
			_action_btn.disabled = true
			_action_btn.add_theme_stylebox_override("disabled", _soft_box(Color("1a2230"), Color("3a4658")))
			TitleFonts.apply(_action_btn, 5, Color("6a7888"))


func _build_footer(
	parent: Control,
	back_cb: Callable,
	mid_cb: Callable = Callable(),
	mid_text: String = "Random",
	action_text: String = "",
	action_cb: Callable = Callable(),
	action_disabled: bool = false
) -> void:
	_draft_footer(parent, back_cb, mid_cb, mid_text, action_text, action_cb, action_disabled)
