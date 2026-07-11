extends Control

## Versus draft: CPU rival or online friend on another device.

const VIEW_W := 240
const VIEW_H := 160
const RIVAL_NAMES := ["Rival Sabo", "Ace Nova", "Champion Wren", "Duelist Kai", "Mystic Lune", "Brawler Rex"]
const RES_FILTER := [-1, EchoTypes.Resonance.FIRE, EchoTypes.Resonance.WATER, EchoTypes.Resonance.GRASS, EchoTypes.Resonance.ROCK, EchoTypes.Resonance.AIR, EchoTypes.Resonance.SHADOW]
const ECHO_BOX := Vector2i(54, 50)
const PAD := 4
const W := VIEW_W - PAD * 2
const HDR_Y := 2
const HDR_H := 15
const OPT_Y := 19
const OPT_H := 19
const FILTER_Y := 40
const FILTER_H := 18
const GRID_Y := 60
const GRID_H := 60
const STATUS_Y := 121
const FOOTER_Y := 137
const FOOTER_H := 20

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
	_header(parent, "VERSUS BATTLE")
	_caption(parent, "Pick solo CPU or online PvP.", 20)

	var card_y := 34
	var card_h := 64
	var card_w := 112

	parent.add_child(_mode_card(
		parent, "Player vs CPU", "Draft a team.\nFight a rival.",
		Vector2(PAD, card_y), Vector2(card_w, card_h),
		Color("142a4a"), C_CPU, _go_cpu
	))
	parent.add_child(_mode_card(
		parent, "Player vs Player", "Host or join\nwith a room code.",
		Vector2(VIEW_W - PAD - card_w, card_y), Vector2(card_w, card_h),
		Color("241a42"), C_PVP, _go_online
	))

	_build_footer(parent, _on_back)


func _build_online(parent: Control) -> void:
	_header(parent, "PLAYER VS PLAYER")
	_status = _caption(parent, "Connect, then share your room code.", 20)

	# left column: name + host/join
	_label_in(parent, Vector2(PAD, 32), Vector2(60, 10), "YOUR NAME", 5, Color("7c8aa0"), false)
	_join_field = _styled_field(Vector2(PAD, 43), Vector2(110, 18))
	_join_field.text = "Player"
	parent.add_child(_join_field)

	_btn_at(parent, Vector2(PAD, 66), Vector2(52, 19), "Host", _host_room)
	_btn_at(parent, Vector2(62, 66), Vector2(52, 19), "Join", _join_room)

	# right column: room code display + join field
	_label_in(parent, Vector2(122, 32), Vector2(110, 10), "ROOM CODE", 5, Color("7c8aa0"), false)
	_code_lbl = _label_in(parent, Vector2(122, 43), Vector2(110, 16), "------", 10, Color("ffd166"), true)
	var code_in := _styled_field(Vector2(122, 66), Vector2(110, 18))
	code_in.name = "code_in"
	code_in.placeholder_text = "ENTER CODE"
	code_in.max_length = 6
	parent.add_child(code_in)

	_action_btn = null
	_build_footer(parent, _on_back, Callable(), "", "Draft", _go_online_draft, true)


func _build_draft(parent: Control, title: String) -> void:
	_header(parent, title)
	_btn_at(parent, Vector2(PAD, OPT_Y), Vector2(40, OPT_H), "1v1", func(): _set_team_size(1), _team_size == 1)
	_btn_at(parent, Vector2(46, OPT_Y), Vector2(40, OPT_H), "3v3", func(): _set_team_size(3), _team_size == 3)
	_btn_at(parent, Vector2(90, OPT_Y), Vector2(46, OPT_H), "Lv15", func(): _set_level(15), _level == 15)
	_btn_at(parent, Vector2(138, OPT_Y), Vector2(46, OPT_H), "Lv30", func(): _set_level(30), _level == 30)
	_btn_at(parent, Vector2(186, OPT_Y), Vector2(50, OPT_H), "Lv50", func(): _set_level(50), _level == 50)
	_btn_at(parent, Vector2(PAD, FILTER_Y), Vector2(W, FILTER_H), _filter_label(), _cycle_filter, true)

	var grid_panel := Panel.new()
	_pin(grid_panel, Vector2(PAD, GRID_Y), Vector2(W, GRID_H))
	grid_panel.clip_contents = true
	grid_panel.add_theme_stylebox_override("panel", _box(Color("0a1218"), Color("3a5f8f")))
	parent.add_child(grid_panel)

	var scroll := ScrollContainer.new()
	_pin(scroll, Vector2(1, 1), Vector2(W - 2, GRID_H - 2))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	grid_panel.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	scroll.add_child(grid)

	for id in _filtered_ids():
		grid.add_child(_echo_box(id))

	_status = _label_in(parent, Vector2(PAD, STATUS_Y), Vector2(W, 9), "", 5, Color("a8dadc"), false)
	_build_footer(parent, _on_back, _random_team, "Random", "Battle!" if not _online else "Ready!", _on_action, true)
	_update_status()


func _echo_box(id: String) -> Control:
	var def := EchoCatalog.get_echo(id)
	var selected := id in _selected
	var box := Panel.new()
	box.custom_minimum_size = Vector2(ECHO_BOX.x, ECHO_BOX.y)
	box.size = Vector2(ECHO_BOX.x, ECHO_BOX.y)
	var border_col := Color("7dffb8") if selected else Color("2e4a60")
	var bg_col := Color("1a3d32", 0.7) if selected else Color("111a22")
	box.add_theme_stylebox_override("panel", _box(bg_col, border_col))

	if def:
		var emblem := TypeEmblem.create(int(def.resonance), 10)
		emblem.position = Vector2(2, 2)
		box.add_child(emblem)

	var icon_slot := Panel.new()
	icon_slot.position = Vector2(14, 4)
	icon_slot.size = Vector2(34, 30)
	icon_slot.clip_contents = true
	icon_slot.add_theme_stylebox_override("panel", _box(Color("060c10"), Color("1e3040")))
	box.add_child(icon_slot)

	var icon := TextureRect.new()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.position = Vector2(2, 2)
	icon.size = Vector2(32, 32)
	if def and ResourceLoader.exists(def.sprite_path):
		icon.texture = load(def.sprite_path)
	icon_slot.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = def.name if def else id
	name_lbl.position = Vector2(2, 38)
	name_lbl.size = Vector2(ECHO_BOX.x - 4, 10)
	name_lbl.add_theme_font_size_override("font_size", 5)
	name_lbl.add_theme_color_override("font_color", Color("cfe8ff"))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	box.add_child(name_lbl)

	var hit := Button.new()
	hit.position = Vector2.ZERO
	hit.size = Vector2(ECHO_BOX.x, ECHO_BOX.y)
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


func _mode_card(parent: Control, title: String, subtitle: String, pos: Vector2, sz: Vector2, bg: Color, accent: Color, cb: Callable) -> Panel:
	var card := Panel.new()
	card.position = pos
	card.size = sz
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", _box(bg, accent))

	var t := Label.new()
	t.text = title
	t.position = Vector2(4, 6)
	t.size = Vector2(sz.x - 8, 12)
	t.add_theme_font_size_override("font_size", 7)
	t.add_theme_color_override("font_color", Color("ffffff"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.clip_text = true
	card.add_child(t)

	var s := Label.new()
	s.text = subtitle
	s.position = Vector2(4, 20)
	s.size = Vector2(sz.x - 8, sz.y - 26)
	s.add_theme_font_size_override("font_size", 5)
	s.add_theme_color_override("font_color", Color("a8c0d8"))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.max_lines_visible = 3
	s.clip_text = true
	card.add_child(s)

	var hit := Button.new()
	hit.position = Vector2.ZERO
	hit.size = sz
	hit.custom_minimum_size = sz
	hit.focus_mode = Control.FOCUS_NONE
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", _box(Color(accent.r, accent.g, accent.b, 0.15), accent))
	hit.add_theme_stylebox_override("pressed", _box(Color(0, 0, 0, 0.2), accent))
	hit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hit.pressed.connect(cb)
	card.add_child(hit)
	return card


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
		await SceneRouter.start_online_versus_battle(
			host_ids, guest_ids, String(payload.get("guest_name", "Guest")), true, lv)
	else:
		await SceneRouter.start_online_versus_battle(
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
	var txt := ", ".join(names) if names.size() > 0 else "tap echoes to select"
	if _status:
		_status.text = "Team %d/%d — %s" % [_selected.size(), _team_size, txt]
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
	await SceneRouter.start_versus_battle(_selected, enemy_ids, rival, _level)


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


# ---- ui (manual pixel layout — no grids on chrome) ----
func _pin(node: Control, pos: Vector2, sz: Vector2) -> void:
	node.position = pos
	node.size = sz
	node.custom_minimum_size = sz


func _paint_backdrop(parent: Control) -> void:
	var bg := ColorRect.new()
	bg.color = Color("0d1520")
	_pin(bg, Vector2.ZERO, Vector2(VIEW_W, VIEW_H))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)


func _header(parent: Control, text: String) -> void:
	var p := Panel.new()
	_pin(p, Vector2(PAD, HDR_Y), Vector2(W, HDR_H))
	p.clip_contents = true
	p.add_theme_stylebox_override("panel", _box(Color("152433"), C_MINT))
	parent.add_child(p)
	_label_in(p, Vector2.ZERO, Vector2(W, HDR_H), text, 6, C_GOLD, true)


func _caption(parent: Control, text: String, y: int) -> Label:
	return _label_in(parent, Vector2(PAD, y), Vector2(W, 9), text, 5, C_ICE, true)


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
	f.add_theme_font_size_override("font_size", 7)
	f.add_theme_stylebox_override("normal", _box(Color("0c141c"), Color("3a5f8f")))
	f.add_theme_stylebox_override("focus", _box(Color("14202b"), Color("8ec8ff")))
	f.add_theme_color_override("font_color", Color("e8f4ff"))
	f.add_theme_color_override("font_placeholder_color", Color("5a7088"))
	return f


func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.set_content_margin_all(0)
	sb.set_expand_margin_all(0)
	return sb


func _btn_at(parent: Control, pos: Vector2, sz: Vector2, text: String, cb: Callable, on: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	_pin(b, pos, sz)
	b.clip_text = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 6)
	var bg := Color("264d73") if on else Color("1e2d42")
	var border := C_GOLD_DIM if on else Color("5a7a9a")
	b.add_theme_stylebox_override("normal", _box(bg, border))
	b.add_theme_stylebox_override("hover", _box(Color("3d597a"), Color("ffffff")))
	b.add_theme_stylebox_override("pressed", _box(Color("14263f"), C_GOLD_DIM))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color("f2f7ff"))
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _build_footer(
	parent: Control,
	back_cb: Callable,
	mid_cb: Callable = Callable(),
	mid_text: String = "Random",
	action_text: String = "",
	action_cb: Callable = Callable(),
	action_disabled: bool = false
) -> void:
	_btn_at(parent, Vector2(PAD, FOOTER_Y), Vector2(52, FOOTER_H), "Back", back_cb)
	if mid_cb.is_valid():
		_btn_at(parent, Vector2(60, FOOTER_Y), Vector2(52, FOOTER_H), mid_text, mid_cb)
	if action_cb.is_valid() and action_text != "":
		_action_btn = _btn_at(parent, Vector2(178, FOOTER_Y), Vector2(58, FOOTER_H), action_text, action_cb)
		if action_disabled:
			_action_btn.disabled = true
			_action_btn.add_theme_stylebox_override("disabled", _box(Color("263140"), Color("55637a")))
