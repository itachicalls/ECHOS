extends Control

## GBA-style turn-based battle scene.

const VIEW_W := 240
const VIEW_H := 160
const ECHO_PX := 52  # scaled down so stat panels never cover opposing sprites
const SPRITE_Z := 2
const PANEL_Z := 1

enum Phase { INTRO, CHOOSING, RESOLVING, ENDED }

var request: Dictionary = {}
var player_party: Array[EchoInstance] = []
var enemy_party: Array[EchoInstance] = []
var state: Dictionary = {}
var phase: int = Phase.INTRO
var can_flee: bool = true
var can_catch: bool = true
var _online: bool = false
var _online_host: bool = false

# UI refs
var enemy_sprite: TextureRect
var player_sprite: TextureRect
var enemy_base: Control
var player_base: Control
var enemy_info: Dictionary = {}
var player_info: Dictionary = {}
var msg: Label
var menu_root: Control
var main_menu: Control
var sub_menu: Control
var _stage: Control
var _msg_panel: Panel
var _home: Dictionary = {}
var _visual_active: Dictionary = {}  # stage index per side — may lag state.active during animations
var _idle_tweens: Dictionary = {}
signal _forced_switch_picked(index: int)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	custom_minimum_size = Vector2(VIEW_W, VIEW_H)
	size = Vector2(VIEW_W, VIEW_H)
	SceneRouter.ensure_visible()
	request = SceneRouter.get_battle_request()
	can_flee = bool(request.get("can_flee", true))
	can_catch = bool(request.get("can_catch", true))
	_online = bool(request.get("online", false))
	_online_host = String(request.get("online_role", "")) == "host"
	_load_teams_from_request()
	if player_party.is_empty() or enemy_party.is_empty():
		push_error("Battle missing team (player=%d enemy=%d kind=%s)" % [
			player_party.size(), enemy_party.size(), request.get("kind", "?")])
		call_deferred("_abort_empty_battle")
		return
	state = CombatResolver.build_state(player_party, enemy_party)
	_visual_active = { "player": int(state.player.active), "enemy": int(state.enemy.active) }
	_build_ui()
	_refresh_all()
	call_deferred("_begin_intro")


func _load_teams_from_request() -> void:
	var level := int(request.get("level", 10))
	var pids: Variant = request.get("player_team_ids", [])
	if pids is Array and pids.size() > 0:
		for id in pids:
			player_party.append(EchoCatalog.create_instance(String(id), level))
	elif request.get("player_override") is Array:
		for e in request.player_override:
			if e is EchoInstance:
				player_party.append(e)
	if player_party.is_empty() and GameState.party.size() > 0:
		player_party = GameState.party

	var eids: Variant = request.get("enemy_team_ids", [])
	if eids is Array and eids.size() > 0:
		for id in eids:
			enemy_party.append(EchoCatalog.create_instance(String(id), level))
	elif request.get("enemies") is Array:
		for e in request.enemies:
			if e is EchoInstance:
				enemy_party.append(e)


func _abort_empty_battle() -> void:
	await SceneRouter.finish_battle({ "result": "flee" })


func _begin_intro() -> void:
	await _intro()


# ------------------------------------------------------------------ UI build
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("bfe3a0")
	bg.position = Vector2.ZERO
	bg.size = Vector2(VIEW_W, VIEW_H)
	add_child(bg)
	var sky := ColorRect.new()
	sky.color = Color("dff2c6")
	sky.position = Vector2.ZERO
	sky.size = Vector2(VIEW_W, 72)
	add_child(sky)

	_stage = Control.new()
	_stage.position = Vector2.ZERO
	_stage.size = Vector2(VIEW_W, VIEW_H)
	add_child(_stage)

	# Classic GBA layout — panels in corners, sprites in front (higher z_index).
	enemy_base = _terrain_base(Vector2(146, 50), Vector2(86, 16))
	enemy_info = _info_panel(Vector2(6, 6), false)
	enemy_sprite = _echo_sprite(Vector2(170, 6))
	player_base = _terrain_base(Vector2(4, 88), Vector2(92, 18))
	player_sprite = _echo_sprite(Vector2(10, 50))
	player_info = _info_panel(Vector2(126, 68), true)

	# full-width bottom bar (message + command / move menus overlay it)
	_msg_panel = Panel.new()
	_msg_panel.position = Vector2(2, 106)
	_msg_panel.size = Vector2(236, 52)
	_msg_panel.add_theme_stylebox_override("panel", _box_style())
	add_child(_msg_panel)
	msg = Label.new()
	msg.add_theme_font_size_override("font_size", 8)
	msg.add_theme_color_override("font_color", Color("f2f7ff"))
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.position = Vector2(7, 5)
	msg.size = Vector2(108, 42)
	msg.clip_text = true
	_msg_panel.add_child(msg)

	# action buttons — clipped to right side of bottom bar
	menu_root = Control.new()
	menu_root.position = Vector2(116, 106)
	menu_root.size = Vector2(120, 52)
	menu_root.clip_contents = true
	add_child(menu_root)

	_home[enemy_sprite.get_instance_id()] = enemy_sprite.position
	_home[player_sprite.get_instance_id()] = player_sprite.position


# ---- battle menu layout (GBA-style 2x2 grids, fixed cell sizes) ----
const _MENU_GAP := 2
const _CMD_CELL := Vector2i(58, 22)
const _MOVE_CELL := Vector2i(58, 20)
const _ACTION_W := 120


func _platform(pos: Vector2, sz: Vector2) -> void:
	var p := ColorRect.new()
	p.color = Color(0.4, 0.6, 0.35, 0.5)
	p.position = pos
	p.size = sz
	_stage.add_child(p)


func _echo_sprite(pos: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.custom_minimum_size = Vector2(ECHO_PX, ECHO_PX)
	tr.size = Vector2(ECHO_PX, ECHO_PX)
	tr.pivot_offset = Vector2(ECHO_PX * 0.5, ECHO_PX * 0.5)
	tr.position = pos
	tr.z_index = SPRITE_Z
	_stage.add_child(tr)
	return tr


## Player sees the enemy's FRONT and its own echo's BACK (classic RPG framing).
func _echo_texture(u: Dictionary, is_player: bool) -> Texture2D:
	var def := EchoCatalog.get_echo(String(u.definition_id))
	if def == null:
		return null
	var path := def.sprite_back_path if is_player else def.sprite_path
	if path == "" or not ResourceLoader.exists(path):
		path = def.sprite_path
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _info_panel(pos: Vector2, show_xp: bool = false) -> Dictionary:
	var panel := Panel.new()
	panel.position = pos
	panel.size = Vector2(104, 36 if show_xp else 30)
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _box_style())
	panel.z_index = PANEL_Z
	_stage.add_child(panel)

	var name_lbl := Label.new()
	name_lbl.add_theme_font_size_override("font_size", 8)
	name_lbl.add_theme_color_override("font_color", Color("ffffff"))
	name_lbl.position = Vector2(5, 2)
	name_lbl.size = Vector2(52, 10)
	name_lbl.clip_text = true
	panel.add_child(name_lbl)

	var type_badge := TypeEmblem.create(EchoTypes.Resonance.NONE, 14)
	type_badge.position = Vector2(56, 2)
	panel.add_child(type_badge)

	var level_lbl := Label.new()
	level_lbl.add_theme_font_size_override("font_size", 7)
	level_lbl.add_theme_color_override("font_color", Color("cfe8ff"))
	level_lbl.position = Vector2(74, 3)
	panel.add_child(level_lbl)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color("22303c")
	bar_bg.position = Vector2(5, 15)
	bar_bg.size = Vector2(94, 5)
	panel.add_child(bar_bg)

	var bar := ColorRect.new()
	bar.color = Color("52b788")
	bar.position = Vector2(6, 16)
	bar.size = Vector2(92, 3)
	panel.add_child(bar)

	var hp_lbl := Label.new()
	hp_lbl.add_theme_font_size_override("font_size", 6)
	hp_lbl.add_theme_color_override("font_color", Color("cfe8ff"))
	hp_lbl.position = Vector2(58, 20)
	panel.add_child(hp_lbl)

	var out := { "name": name_lbl, "level": level_lbl, "type_badge": type_badge, "bar": bar, "hp": hp_lbl, "show_xp": show_xp }
	if show_xp:
		var xp_bg := ColorRect.new()
		xp_bg.color = Color("22303c")
		xp_bg.position = Vector2(5, 27)
		xp_bg.size = Vector2(94, 3)
		panel.add_child(xp_bg)
		var xp_bar := ColorRect.new()
		xp_bar.color = Color("7dffb8")
		xp_bar.position = Vector2(6, 28)
		xp_bar.size = Vector2(0, 1)
		panel.add_child(xp_bar)
		var xp_lbl := Label.new()
		xp_lbl.add_theme_font_size_override("font_size", 5)
		xp_lbl.add_theme_color_override("font_color", Color("a8c0d8"))
		xp_lbl.position = Vector2(58, 26)
		panel.add_child(xp_lbl)
		out["xp_bar"] = xp_bar
		out["xp_lbl"] = xp_lbl
	return out


func _swap_type_badge(info: Dictionary, resonance: int) -> void:
	if not info.has("type_badge"):
		return
	var old: Control = info.type_badge
	if not is_instance_valid(old):
		return
	var parent: Node = old.get_parent()
	if parent == null:
		return
	var pos: Vector2 = old.position
	parent.remove_child(old)
	old.queue_free()
	var emblem := TypeEmblem.create(resonance, 14)
	emblem.position = pos
	parent.add_child(emblem)
	info.type_badge = emblem


func _terrain_base(pos: Vector2, sz: Vector2) -> Control:
	var base := Control.new()
	base.position = pos
	base.size = sz
	base.z_index = 0
	_stage.add_child(base)
	_paint_terrain(base, EchoTypes.Resonance.NONE, sz)
	return base


func _paint_terrain(base: Control, resonance: int, sz: Vector2) -> void:
	for c in base.get_children():
		c.queue_free()
	var res := resonance as EchoTypes.Resonance
	var col: Color = EchoTypes.RESONANCE_COLORS.get(res, Color("6cbf6a"))
	var dark := col.darkened(0.45)
	var light := col.lightened(0.2)

	var shadow := ColorRect.new()
	shadow.color = Color(dark.r, dark.g, dark.b, 0.55)
	shadow.position = Vector2(2, sz.y - 5)
	shadow.size = Vector2(sz.x - 4, 4)
	base.add_child(shadow)

	var slab := ColorRect.new()
	slab.color = Color(col.r, col.g, col.b, 0.72)
	slab.position = Vector2(0, sz.y * 0.35)
	slab.size = Vector2(sz.x, sz.y * 0.55)
	base.add_child(slab)

	var top := ColorRect.new()
	top.color = Color(light.r, light.g, light.b, 0.85)
	top.position = Vector2(4, sz.y * 0.28)
	top.size = Vector2(sz.x - 8, 3)
	base.add_child(top)

	match res:
		EchoTypes.Resonance.FIRE:
			for i in 3:
				var crack := ColorRect.new()
				crack.color = Color(0.15, 0.05, 0.02, 0.5)
				crack.position = Vector2(8 + i * 22, sz.y * 0.5)
				crack.size = Vector2(2, 5)
				base.add_child(crack)
		EchoTypes.Resonance.WATER:
			for i in 4:
				var ripple := ColorRect.new()
				ripple.color = Color(1, 1, 1, 0.15)
				ripple.position = Vector2(6 + i * 18, sz.y * 0.55)
				ripple.size = Vector2(10, 1)
				base.add_child(ripple)
		EchoTypes.Resonance.GRASS:
			for i in 6:
				var blade := ColorRect.new()
				blade.color = Color("3d8a4a")
				blade.position = Vector2(4 + i * 13, sz.y * 0.22)
				blade.size = Vector2(2, 4)
				base.add_child(blade)
		EchoTypes.Resonance.ROCK:
			for i in 3:
				var chip := ColorRect.new()
				chip.color = Color("5a6478")
				chip.position = Vector2(10 + i * 24, sz.y * 0.38)
				chip.size = Vector2(8, 4)
				base.add_child(chip)
		EchoTypes.Resonance.AIR:
			for i in 3:
				var puff := ColorRect.new()
				puff.color = Color(1, 1, 1, 0.18)
				puff.position = Vector2(8 + i * 20, sz.y * 0.32)
				puff.size = Vector2(12, 3)
				base.add_child(puff)
		EchoTypes.Resonance.SHADOW:
			var mist := ColorRect.new()
			mist.color = Color(0.1, 0.02, 0.2, 0.35)
			mist.position = Vector2(2, sz.y * 0.4)
			mist.size = Vector2(sz.x - 4, sz.y * 0.45)
			base.add_child(mist)
		_:
			pass


func _box_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1d2b3a")
	sb.border_color = Color("cfe8ff")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	return sb


# ------------------------------------------------------------------ refresh
func _unit_at(side: String, index: int) -> Dictionary:
	return state[side].units[index]


func _visual_index(side: String) -> int:
	return int(_visual_active[side])


func _pin_stage(side: String, index: int, hp_display: int = -1) -> void:
	_visual_active[side] = index
	_refresh_side(side, _side_info(side), _side_sprite(side), index, hp_display)


func _side_sprite(side: String) -> TextureRect:
	return player_sprite if side == "player" else enemy_sprite


func _side_info(side: String) -> Dictionary:
	return player_info if side == "player" else enemy_info


func _active(side: String) -> Dictionary:
	var sd: Dictionary = state[side]
	return sd.units[int(sd.active)]


func _refresh_all() -> void:
	_refresh_side("enemy", enemy_info, enemy_sprite)
	_refresh_side("player", player_info, player_sprite)


func _refresh_side(side: String, info: Dictionary, spr: TextureRect, index: int = -1, hp_display: int = -1) -> void:
	if index < 0:
		index = _visual_index(side)
	var u := _unit_at(side, index)
	info.name.text = String(u.name)
	info.level.text = "Lv%d" % int(u.level)
	_swap_type_badge(info, int(u.get("resonance", 0)))
	var base := player_base if side == "player" else enemy_base
	_paint_terrain(base, int(u.get("resonance", 0)), base.size)
	var hp := hp_display if hp_display >= 0 else int(u.current_hp)
	_set_hp_bar(info, hp, int(u.max_hp))
	if bool(info.get("show_xp", false)) and info.has("xp_bar"):
		_set_xp_bar(info, int(u.get("xp", 0)), int(u.level))
	var tex := _echo_texture(u, side == "player")
	if tex:
		spr.texture = tex
	spr.modulate = Color(1, 1, 1, 1)
	spr.scale = Vector2(1, 1)
	spr.position = _home.get(spr.get_instance_id(), spr.position)


func _set_xp_bar(info: Dictionary, xp: int, level: int) -> void:
	var need := EchoTypes.xp_to_next(level)
	if level >= EchoTypes.MAX_LEVEL:
		info.xp_bar.size.x = 92.0
		info.xp_lbl.text = "MAX"
	else:
		var ratio := clampf(float(xp) / maxf(1.0, float(need)), 0.0, 1.0)
		info.xp_bar.size.x = 92.0 * ratio
		info.xp_lbl.text = "%d/%d" % [xp, need]


func _tween_xp_bar_to(info: Dictionary, xp: int, level: int, duration: float = 0.4) -> void:
	if not info.has("xp_bar"):
		return
	if level >= EchoTypes.MAX_LEVEL:
		_set_xp_bar(info, xp, level)
		return
	var need := EchoTypes.xp_to_next(level)
	var target_w := 92.0 * clampf(float(xp) / maxf(1.0, float(need)), 0.0, 1.0)
	var tw := create_tween()
	tw.tween_property(info.xp_bar, "size:x", target_w, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(info.xp_bar, "color", Color("b8ffe0"), duration * 0.35)
	tw.chain().tween_property(info.xp_bar, "color", Color("7dffb8"), 0.12)
	info.xp_lbl.text = "%d/%d" % [xp, need]
	await tw.finished


func _xp_level_ping(info: Dictionary) -> void:
	if not info.has("xp_bar"):
		return
	var tw := create_tween()
	tw.tween_property(info.xp_bar, "color", Color("ffffff"), 0.08)
	tw.tween_property(info.xp_bar, "size:x", 92.0, 0.1)
	tw.parallel().tween_property(info.name, "modulate", Color("fff3b0"), 0.1)
	await tw.finished
	info.name.modulate = Color.WHITE
	info.xp_bar.color = Color("7dffb8")
	info.xp_bar.size.x = 0.0


func _animate_xp_fill(info: Dictionary, echo_name: String, start_xp: int, start_level: int, amount: int) -> void:
	if amount <= 0 or not info.has("xp_bar"):
		return
	var xp := start_xp
	var level := start_level
	var left := amount
	_set_xp_bar(info, xp, level)
	info.name.text = echo_name
	info.level.text = "Lv%d" % level
	while left > 0 and level < EchoTypes.MAX_LEVEL:
		var need := EchoTypes.xp_to_next(level)
		var room := need - xp
		var chunk := mini(left, room)
		xp += chunk
		left -= chunk
		await _tween_xp_bar_to(info, xp, level, 0.38 if chunk > need * 0.5 else 0.28)
		if xp >= need:
			await _xp_level_ping(info)
			level += 1
			xp = 0
			info.level.text = "Lv%d" % level
			_set_xp_bar(info, 0, level)
	if level >= EchoTypes.MAX_LEVEL:
		_set_xp_bar(info, xp, level)


func _sync_party_xp_to_state() -> void:
	for u in state.player.units:
		for e in GameState.party:
			if String(e.instance_id) == String(u.instance_id):
				u.xp = e.xp
				u.level = e.level
				u.max_hp = e.max_hp()
				u.name = e.display_name()
				break


func _set_hp_bar(info: Dictionary, current: int, maximum: int) -> void:
	var ratio := clampf(float(current) / maxf(1.0, float(maximum)), 0.0, 1.0)
	info.bar.size.x = 92.0 * ratio
	info.bar.color = Color("52b788") if ratio > 0.5 else (Color("ffd166") if ratio > 0.2 else Color("e63946"))
	info.hp.text = "%d/%d" % [current, maximum]


func _tween_hp_bar(info: Dictionary, current: int, maximum: int) -> void:
	var ratio := clampf(float(current) / maxf(1.0, float(maximum)), 0.0, 1.0)
	var tw := create_tween()
	tw.tween_property(info.bar, "size:x", 92.0 * ratio, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	info.bar.color = Color("52b788") if ratio > 0.5 else (Color("ffd166") if ratio > 0.2 else Color("e63946"))
	info.hp.text = "%d/%d" % [current, maximum]


# ------------------------------------------------------------------ flow
func _intro() -> void:
	phase = Phase.INTRO
	menu_root.visible = false
	await _entry_animation()
	_start_idle_bob(enemy_sprite)
	_start_idle_bob(player_sprite)
	var kind := String(request.get("kind", "wild"))
	if kind == "trainer" or kind == "versus":
		await _say("%s wants to battle!" % String(request.get("trainer_name", "Rival")))
	else:
		await _say("A wild %s appeared!" % _active("enemy").name)
	await _say("Go, %s!" % _active("player").name)
	_open_main_menu()


func _entry_animation() -> void:
	# opening wipe + sprites slide/pop in from the sides
	var enemy_home := _home_pos(enemy_sprite)
	var player_home := _home_pos(player_sprite)
	enemy_sprite.position = enemy_home + Vector2(90, 0)
	player_sprite.position = player_home - Vector2(100, 0)
	enemy_sprite.modulate = Color(1, 1, 1, 0)
	player_sprite.modulate = Color(1, 1, 1, 0)
	msg.text = ""
	await get_tree().process_frame

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(enemy_sprite, "position", enemy_home, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(enemy_sprite, "modulate:a", 1.0, 0.3)
	await t.finished
	# enemy landing bob
	var bob := create_tween()
	bob.tween_property(enemy_sprite, "position:y", enemy_home.y - 4.0, 0.12)
	bob.tween_property(enemy_sprite, "position:y", enemy_home.y, 0.12).set_trans(Tween.TRANS_BOUNCE)

	var t2 := create_tween()
	t2.set_parallel(true)
	t2.tween_property(player_sprite, "position", player_home, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t2.tween_property(player_sprite, "modulate:a", 1.0, 0.3)
	await t2.finished


func _start_idle_bob(spr: TextureRect) -> void:
	var id := spr.get_instance_id()
	if _idle_tweens.has(id):
		var old: Tween = _idle_tweens[id]
		if old and old.is_valid():
			old.kill()
	var home := _home_pos(spr)
	var tw := create_tween().set_loops()
	tw.tween_property(spr, "position:y", home.y - 2.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(spr, "position:y", home.y, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tweens[id] = tw


func _stop_idle_bob(spr: TextureRect) -> void:
	var id := spr.get_instance_id()
	if _idle_tweens.has(id):
		var old: Tween = _idle_tweens[id]
		if old and old.is_valid():
			old.kill()
		_idle_tweens.erase(id)
	spr.position = _home_pos(spr)


func _say(text: String) -> void:
	menu_root.visible = false
	msg.visible = true
	msg.size = Vector2(226, 44)
	msg.text = text
	await get_tree().create_timer(0.85).timeout


func _btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.set_content_margin_all(0)
	sb.set_expand_margin_all(0)
	return sb


func _clear_menu() -> void:
	for c in menu_root.get_children():
		menu_root.remove_child(c)
		c.free()


func _menu_cell(w: int, h: int) -> Control:
	var cell := Control.new()
	cell.custom_minimum_size = Vector2(w, h)
	cell.size = Vector2(w, h)
	cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return cell


func _fill_btn(cell: Control, text: String, cb: Callable, font_size: int = 7, enabled: bool = true) -> Button:
	var b := Button.new()
	b.text = text
	b.position = Vector2.ZERO
	b.size = cell.size
	b.custom_minimum_size = cell.size
	b.clip_text = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_stylebox_override("normal", _btn_style(Color("2b3f56"), Color("cfe8ff")))
	b.add_theme_stylebox_override("hover", _btn_style(Color("3d597a"), Color("ffffff")))
	b.add_theme_stylebox_override("pressed", _btn_style(Color("1d2b3a"), Color("ffd166")))
	b.add_theme_stylebox_override("disabled", _btn_style(Color("263140"), Color("55637a")))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color("f2f7ff"))
	b.add_theme_color_override("font_disabled_color", Color("6b7890"))
	if enabled:
		b.pressed.connect(cb)
	else:
		b.disabled = true
	cell.add_child(b)
	return b


func _grid_size(cols: int, rows: int, cell: Vector2i) -> Vector2:
	return Vector2(
		cols * cell.x + maxi(0, cols - 1) * _MENU_GAP,
		rows * cell.y + maxi(0, rows - 1) * _MENU_GAP
	)


func _spawn_grid(pos: Vector2, cols: int, rows: int, cell: Vector2i) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = cols
	grid.position = pos
	grid.size = _grid_size(cols, rows, cell)
	grid.custom_minimum_size = grid.size
	grid.add_theme_constant_override("h_separation", _MENU_GAP)
	grid.add_theme_constant_override("v_separation", _MENU_GAP)
	menu_root.add_child(grid)
	return grid


func _grid_add(grid: GridContainer, text: String, cb: Callable, cell: Vector2i, font_size: int = 7, enabled: bool = true) -> void:
	var slot := _menu_cell(cell.x, cell.y)
	_fill_btn(slot, text, cb, font_size, enabled)
	grid.add_child(slot)


func _spawn_back(cb: Callable) -> void:
	var slot := _menu_cell(58, 20)
	slot.position = Vector2(60, 24)
	_fill_btn(slot, "Back", cb, 6)
	menu_root.add_child(slot)


func _open_main_menu() -> void:
	phase = Phase.CHOOSING
	menu_root.visible = true
	menu_root.position = Vector2(116, 106)
	menu_root.size = Vector2(_ACTION_W, 52)
	msg.visible = true
	msg.size = Vector2(108, 42)
	msg.text = "What will you do?"
	_clear_menu()
	var grid := _spawn_grid(Vector2(2, 4), 2, 2, _CMD_CELL)
	var show_bag := String(request.get("kind", "wild")) != "versus"
	_grid_add(grid, "Fight", _on_fight, _CMD_CELL, 7)
	_grid_add(grid, "Bag", _on_bag, _CMD_CELL, 7, show_bag)
	_grid_add(grid, "Echoes", _on_switch_menu, _CMD_CELL, 7)
	_grid_add(grid, "Run" if can_flee else "—", _on_run, _CMD_CELL, 7, can_flee)


func _spawn_move_grid() -> GridContainer:
	menu_root.position = Vector2(2, 106)
	menu_root.size = Vector2(234, 52)
	return _spawn_grid(Vector2(2, 4), 2, 2, _MOVE_CELL)


func _on_fight() -> void:
	_clear_menu()
	msg.visible = false
	var grid := _spawn_move_grid()
	var u := _active("player")
	for i in u.chimes.size():
		if i >= 4:
			break
		var c: Dictionary = u.chimes[i]
		_grid_add(grid, String(c.name), _use_chime.bind(String(c.id)), _MOVE_CELL, 8)
	_spawn_back(_open_main_menu)


func _on_bag() -> void:
	_clear_menu()
	msg.visible = false
	var grid := _spawn_move_grid()
	var salves := int(GameState.inventory.get("heart_salve", 0))
	_grid_add(grid, "Heart Salve x%d" % salves, _use_salve, _MOVE_CELL, 7, salves > 0)
	if can_catch:
		var cap := int(GameState.inventory.get("echo_capsule", 0))
		_grid_add(grid, "Echo Capsule x%d" % cap, _on_catch, _MOVE_CELL, 7, cap > 0)
	_spawn_back(_open_main_menu)


func _use_salve() -> void:
	_clear_menu()
	phase = Phase.RESOLVING
	var salves := int(GameState.inventory.get("heart_salve", 0))
	if salves <= 0:
		await _say("You have no Heart Salves!")
		_open_main_menu()
		return
	var u := _active("player")
	if int(u.current_hp) >= int(u.max_hp):
		await _say("%s is already at full HP." % u.name)
		_open_main_menu()
		return
	GameState.inventory["heart_salve"] = salves - 1
	var heal := int(round(float(u.max_hp) * 0.6))
	u.current_hp = mini(int(u.max_hp), int(u.current_hp) + heal)
	_tween_hp_bar(player_info, int(u.current_hp), int(u.max_hp))
	await _say("You used a Heart Salve. %s recovered %d HP!" % [u.name, heal])
	await _enemy_only_turn()


func _on_switch_menu() -> void:
	_clear_menu()
	msg.visible = false
	var grid := _spawn_move_grid()
	var sd: Dictionary = state["player"]
	var units: Array = sd.units
	for i in units.size():
		if i >= 4:
			break
		var u: Dictionary = units[i]
		var ko: bool = int(u.current_hp) <= 0
		var label: String = "%s L%d" % [u.name, int(u.level)]
		if ko:
			label += " KO"
		var can_pick: bool = (not ko) and (i != int(sd.active))
		_grid_add(grid, label, _do_switch.bind(i), _MOVE_CELL, 7, can_pick)
	_spawn_back(_open_main_menu)


func _use_chime(chime_id: String) -> void:
	_resolve({ "type": EchoTypes.ActionType.CHIME, "chime_id": chime_id })


func _do_switch(index: int) -> void:
	_resolve({ "type": EchoTypes.ActionType.SWITCH, "index": index })


func _on_run() -> void:
	if not can_flee:
		return
	_resolve({ "type": EchoTypes.ActionType.FLEE })


func _on_catch() -> void:
	if not can_catch:
		return
	_clear_menu()
	phase = Phase.RESOLVING
	var capsules := int(GameState.inventory.get("echo_capsule", 0))
	if capsules <= 0:
		await _say("You have no Echo Capsules left!")
		_open_main_menu()
		return
	GameState.inventory["echo_capsule"] = capsules - 1
	var u := _active("enemy")
	await _say("You toss an Echo Capsule!")
	var def := EchoCatalog.get_echo(String(u.definition_id))
	var ratio := 1.0 - float(u.current_hp) / maxf(1.0, float(u.max_hp))
	var chance := clampf((def.catch_rate if def else 0.3) + ratio * 0.55 + 0.08, 0.05, 0.96)
	var success := randf() < chance
	var shakes := 3 if success else randi_range(1, 2)
	await _play_catch_animation(success, shakes)
	if success:
		var caught := EchoCatalog.create_instance(String(u.definition_id), int(u.level))
		caught.current_hp = int(u.current_hp)
		GameState.add_echo(caught)
		await _say("Gotcha! %s joined your team!" % u.name)
		_end_battle("caught")
	else:
		await _say("Oh no! %s broke free!" % u.name)
		await _enemy_only_turn()


# ------------------------------------------------------------------ catch FX
func _play_catch_animation(success: bool, shakes: int) -> void:
	var capsule := TextureRect.new()
	capsule.texture = load(Tiles.ECHO_CAPSULE)
	capsule.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	capsule.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	capsule.custom_minimum_size = Vector2(12, 16)
	capsule.size = Vector2(12, 16)
	capsule.pivot_offset = Vector2(6, 8)
	capsule.position = Vector2(50, 112)
	capsule.z_index = 20
	add_child(capsule)

	var target := Vector2(170, 30)
	var arc := create_tween()
	arc.tween_property(capsule, "position", Vector2((50 + target.x) * 0.5, 2), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	arc.tween_property(capsule, "position", target, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await arc.finished

	await _flash(0.14)
	var suck := create_tween()
	suck.set_parallel(true)
	suck.tween_property(enemy_sprite, "scale", Vector2(0.15, 0.15), 0.16)
	suck.tween_property(enemy_sprite, "modulate", Color(1, 1, 1, 0.0), 0.16)
	await suck.finished

	var drop := create_tween()
	drop.tween_property(capsule, "position", Vector2(target.x, 52), 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await drop.finished

	for i in shakes:
		await get_tree().create_timer(0.28).timeout
		var sh := create_tween()
		sh.tween_property(capsule, "rotation_degrees", -18.0, 0.08)
		sh.tween_property(capsule, "rotation_degrees", 18.0, 0.12)
		sh.tween_property(capsule, "rotation_degrees", 0.0, 0.08)
		await sh.finished

	if success:
		await get_tree().create_timer(0.15).timeout
		_sparkle(Vector2(target.x + 8, 60))
		await get_tree().create_timer(0.35).timeout
		capsule.queue_free()
	else:
		await _flash(0.1)
		enemy_sprite.scale = Vector2(1, 1)
		var pop := create_tween()
		pop.tween_property(enemy_sprite, "modulate", Color(1, 1, 1, 1.0), 0.16)
		await pop.finished
		capsule.queue_free()


func _res_color(res: int) -> Color:
	match res:
		1: return Color("ff7b39")
		2: return Color("4cc9f0")
		3: return Color("6cc551")
		4: return Color("b98a4a")
		5: return Color("d9f2f5")
		6: return Color("9b5de5")
		_: return Color("f2f2f2")


func _sprite_center(spr: TextureRect) -> Vector2:
	return spr.position + Vector2(ECHO_PX * 0.5, ECHO_PX * 0.5)


func _home_pos(spr: TextureRect) -> Vector2:
	return _home.get(spr.get_instance_id(), spr.position)


func _animate_attack(
	actor_side: String, actor_index: int, target_side: String, target_index: int,
	resonance: int, dmg: int, mult: float,
	target_hp_before: int, target_hp: int, target_max: int,
	actor_hp_before: int, actor_max: int
) -> void:
	_pin_stage(actor_side, actor_index, actor_hp_before)
	_pin_stage(target_side, target_index, target_hp_before)
	var attacker := _side_sprite(actor_side)
	var target := _side_sprite(target_side)
	_stop_idle_bob(attacker)
	_stop_idle_bob(target)
	var target_info := _side_info(target_side)
	var home_a := _home_pos(attacker)
	var home_t := _home_pos(target)
	var toward := (home_t - home_a).normalized()
	var col := _res_color(resonance)

	# Step 1: wind-up (squash back) then lunge forward
	var lunge := create_tween()
	lunge.tween_property(attacker, "position", home_a - toward * 4.0, 0.08).set_trans(Tween.TRANS_SINE)
	lunge.tween_property(attacker, "position", home_a + toward * 8.0, 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await lunge.finished

	# Step 2: elemental projectile with trail
	await _fire_projectile(_sprite_center(attacker), _sprite_center(target), col, resonance)

	# snap attacker home
	var back_tw := create_tween()
	back_tw.tween_property(attacker, "position", home_a, 0.10).set_trans(Tween.TRANS_SINE)

	# Step 3: impact — flash target, burst, HP drain, damage number
	_impact_burst(_sprite_center(target), col, mult)
	target.modulate = Color(1, 0.45, 0.45)
	_tween_hp_bar(target_info, target_hp, target_max)
	_damage_popup(_sprite_center(target), dmg, mult)
	if mult > 1.1:
		_stage_shake()

	# Step 4: recoil shake on target
	var shake := create_tween()
	shake.tween_property(target, "position", home_t + Vector2(4, -1), 0.04)
	shake.tween_property(target, "position", home_t + Vector2(-4, 1), 0.05)
	shake.tween_property(target, "position", home_t + Vector2(2, 0), 0.04)
	shake.tween_property(target, "position", home_t, 0.04)
	await shake.finished
	target.modulate = Color.WHITE
	_start_idle_bob(attacker)
	_start_idle_bob(target)


func _fire_projectile(from: Vector2, to: Vector2, col: Color, resonance: int) -> void:
	var proj := ColorRect.new()
	proj.color = col
	var sz := 6.0 if resonance == 4 else 5.0  # rock is chunkier
	proj.size = Vector2(sz, sz)
	proj.pivot_offset = Vector2(sz * 0.5, sz * 0.5)
	proj.position = from - proj.size * 0.5
	proj.z_index = 22
	proj.rotation_degrees = 45.0
	_stage.add_child(proj)
	# trail spawner
	var steps := 7
	var t := create_tween()
	for i in range(1, steps + 1):
		var p := from.lerp(to, float(i) / float(steps))
		t.tween_callback(_spawn_trail.bind(p, col))
		t.tween_property(proj, "position", p - proj.size * 0.5, 0.028).set_trans(Tween.TRANS_LINEAR)
	await t.finished
	proj.queue_free()


func _spawn_trail(pos: Vector2, col: Color) -> void:
	var s := ColorRect.new()
	s.color = Color(col.r, col.g, col.b, 0.6)
	s.size = Vector2(3, 3)
	s.position = pos - Vector2(1.5, 1.5)
	s.z_index = 21
	_stage.add_child(s)
	var t := create_tween()
	t.tween_property(s, "modulate:a", 0.0, 0.22)
	t.parallel().tween_property(s, "scale", Vector2(0.3, 0.3), 0.22)
	t.chain().tween_callback(s.queue_free)


func _impact_burst(center: Vector2, col: Color, mult: float) -> void:
	_flash_ring(center, col)
	var n := 10 if mult > 1.1 else 7
	for i in n:
		var s := ColorRect.new()
		s.color = col
		s.size = Vector2(3, 3)
		s.position = center - Vector2(1.5, 1.5)
		s.z_index = 25
		_stage.add_child(s)
		var ang := i * TAU / float(n) + randf() * 0.5
		var dist := randf_range(10.0, 20.0) * (1.3 if mult > 1.1 else 1.0)
		var dest := center + Vector2(cos(ang), sin(ang)) * dist
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(s, "position", dest - Vector2(1.5, 1.5), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(s, "color", Color(col.r, col.g, col.b, 0.0), 0.26)
		t.tween_property(s, "scale", Vector2(0.4, 0.4), 0.26)
		t.chain().tween_callback(s.queue_free)


func _flash_ring(center: Vector2, col: Color) -> void:
	var ring := ColorRect.new()
	ring.color = Color(col.r, col.g, col.b, 0.85)
	ring.size = Vector2(8, 8)
	ring.pivot_offset = Vector2(4, 4)
	ring.position = center - Vector2(4, 4)
	ring.z_index = 24
	_stage.add_child(ring)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(ring, "scale", Vector2(3.5, 3.5), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(ring, "modulate:a", 0.0, 0.2)
	t.chain().tween_callback(ring.queue_free)


func _stage_shake() -> void:
	var orig := _stage.position
	var tw := create_tween()
	for i in 3:
		tw.tween_property(_stage, "position", orig + Vector2(randf_range(-2, 2), randf_range(-2, 2)), 0.03)
	tw.tween_property(_stage, "position", orig, 0.03)


func _impact_spark(center: Vector2, col: Color) -> void:
	for i in 4:
		var s := ColorRect.new()
		s.color = col
		s.size = Vector2(2, 2)
		s.position = center
		s.z_index = 24
		_stage.add_child(s)
		var ang := i * TAU / 4.0
		var dest := center + Vector2(cos(ang), sin(ang)) * 10.0
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(s, "position", dest, 0.18)
		t.tween_property(s, "color", Color(col.r, col.g, col.b, 0.0), 0.18)
		t.chain().tween_callback(s.queue_free)


func _damage_popup(center: Vector2, dmg: int, mult: float) -> void:
	var lbl := Label.new()
	lbl.text = str(dmg)
	lbl.add_theme_font_size_override("font_size", 9 if mult > 1.1 else 8)
	lbl.add_theme_color_override("font_color", Color("ffd166") if mult > 1.1 else Color("ffffff"))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.position = center + Vector2(-6, -10)
	lbl.z_index = 26
	_stage.add_child(lbl)
	var t := create_tween()
	t.tween_property(lbl, "position:y", lbl.position.y - 12.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(lbl, "modulate:a", 0.0, 0.35)
	t.chain().tween_callback(lbl.queue_free)


func _animate_heal(side: String) -> void:
	var spr := player_sprite if side == "player" else enemy_sprite
	var center := _sprite_center(spr)
	for i in 4:
		var s := ColorRect.new()
		s.color = Color("7dffb8")
		s.size = Vector2(2, 2)
		s.position = center + Vector2(randf_range(-8, 8), randf_range(0, 8))
		s.z_index = 24
		_stage.add_child(s)
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(s, "position:y", s.position.y - 14.0, 0.4)
		t.tween_property(s, "color", Color(0.49, 1, 0.72, 0), 0.4)
		t.chain().tween_callback(s.queue_free)
		await get_tree().create_timer(0.06).timeout


func _animate_buff(side: String) -> void:
	var spr := player_sprite if side == "player" else enemy_sprite
	var pre := spr.modulate
	var t := create_tween()
	t.tween_property(spr, "modulate", Color("ffe08a"), 0.12)
	t.tween_property(spr, "modulate", pre, 0.2)
	await t.finished


func _animate_faint(side: String, index: int) -> void:
	_pin_stage(side, index)
	var spr := _side_sprite(side)
	_stop_idle_bob(spr)
	var info := _side_info(side)
	var home := _home_pos(spr)
	_set_hp_bar(info, 0, int(_unit_at(side, index).max_hp))
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(spr, "position:y", home.y + 10.0, 0.28)
	t.tween_property(spr, "scale", Vector2(0.75, 0.75), 0.28)
	t.tween_property(spr, "modulate:a", 0.0, 0.28)
	await t.finished


func _animate_switch(side: String, in_name: String, out_name: String = "", auto: bool = false, out_index: int = -1, in_index: int = -1) -> void:
	var spr := _side_sprite(side)
	var info := _side_info(side)
	var home := _home_pos(spr)
	_stop_idle_bob(spr)

	if out_index >= 0:
		_pin_stage(side, out_index)
	elif out_name != "":
		pass  # keep current on-stage echo for recall

	if out_name != "" and spr.modulate.a > 0.05:
		var recall := create_tween()
		recall.set_parallel(true)
		recall.tween_property(spr, "position:y", home.y + 14.0, 0.22)
		recall.tween_property(spr, "scale", Vector2(0.7, 0.7), 0.22)
		recall.tween_property(spr, "modulate:a", 0.0, 0.22)
		await recall.finished

	var next_idx := in_index if in_index >= 0 else int(state[side].active)
	_visual_active[side] = next_idx
	_refresh_side(side, info, spr, next_idx)

	var enter_from := home + Vector2(-24, 16) if side == "player" else home + Vector2(36, -8)
	spr.position = enter_from
	spr.scale = Vector2(0.55, 0.55)
	spr.modulate = Color(1, 1, 1, 0)

	var send := create_tween()
	send.set_parallel(true)
	send.tween_property(spr, "position", home, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	send.tween_property(spr, "scale", Vector2(1, 1), 0.38)
	send.tween_property(spr, "modulate:a", 1.0, 0.28)
	await send.finished

	var bob := create_tween()
	bob.tween_property(spr, "position:y", home.y - 4.0, 0.1)
	bob.tween_property(spr, "position:y", home.y, 0.12).set_trans(Tween.TRANS_BOUNCE)
	await bob.finished
	_start_idle_bob(spr)


func _prompt_switch() -> void:
	phase = Phase.CHOOSING
	menu_root.visible = true
	msg.visible = true
	msg.size = Vector2(226, 42)
	msg.text = "Choose your next Echo!"
	_clear_menu()
	var grid := _spawn_move_grid()
	var sd: Dictionary = state["player"]
	for i in sd.units.size():
		var u: Dictionary = sd.units[i]
		if int(u.current_hp) <= 0:
			continue
		if i == int(sd.active):
			continue
		_grid_add(grid, "%s L%d" % [u.name, int(u.level)], _pick_forced_switch.bind(i), _MOVE_CELL, 8)
	var index: int = await _forced_switch_picked
	_clear_menu()
	phase = Phase.RESOLVING
	state.player.active = index
	var out_idx := _visual_index("player")
	var out_name := String(_unit_at("player", out_idx).name)
	await _say("%s, come back! Go, %s!" % [out_name, _active("player").name])
	await _animate_switch("player", _active("player").name, out_name, false, out_idx, index)


func _pick_forced_switch(index: int) -> void:
	_forced_switch_picked.emit(index)


func _flash(dur: float) -> void:
	var f := ColorRect.new()
	f.color = Color(1, 1, 1, 0)
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.z_index = 30
	add_child(f)
	var t := create_tween()
	t.tween_property(f, "color", Color(1, 1, 1, 0.7), dur * 0.4)
	t.tween_property(f, "color", Color(1, 1, 1, 0.0), dur * 0.6)
	await t.finished
	f.queue_free()


func _sparkle(center: Vector2) -> void:
	for i in 6:
		var s := ColorRect.new()
		s.color = Color("ffd166")
		s.size = Vector2(2, 2)
		s.position = center
		s.z_index = 25
		add_child(s)
		var ang := i * TAU / 6.0
		var dest := center + Vector2(cos(ang), sin(ang)) * 14.0
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(s, "position", dest, 0.32)
		t.tween_property(s, "color", Color(1, 1, 1, 0), 0.32)
		t.chain().tween_callback(s.queue_free)


# ------------------------------------------------------------------ resolve
func _resolve(player_action: Dictionary) -> void:
	phase = Phase.RESOLVING
	_clear_menu()
	if _online:
		if _online_host:
			var guest_action: Dictionary = await VersusNet.wait_guest_action()
			if guest_action.is_empty():
				guest_action = { "type": EchoTypes.ActionType.WAIT }
			state = CombatResolver.resolve_turn(state, player_action, guest_action)
			await _play_log(state.get("log", []))
			VersusNet.send_turn_result(state)
			if state.get("finished", false):
				VersusNet.send_battle_end(String(state.get("winner", "")))
		else:
			VersusNet.send_guest_action(player_action)
			var pkt: Dictionary = await VersusNet.wait_turn_result()
			state = pkt.get("state", state)
			state["log"] = []
			await _play_log(pkt.get("log", []))
			if bool(pkt.get("finished", false)):
				state["finished"] = true
				state["winner"] = String(pkt.get("winner", ""))
		_after_turn()
		return
	var enemy_action := _pick_enemy_action()
	state = CombatResolver.resolve_turn(state, player_action, enemy_action)
	await _play_log(state.get("log", []))
	_after_turn()


func _enemy_only_turn() -> void:
	state = CombatResolver.resolve_turn(state, { "type": EchoTypes.ActionType.WAIT }, _pick_enemy_action())
	await _play_log(state.get("log", []))
	_after_turn()


func _pick_enemy_action() -> Dictionary:
	var u := _active("enemy")
	if u.chimes.is_empty():
		return { "type": EchoTypes.ActionType.WAIT }
	# Prefer attacks; only heal when hurt, buff occasionally.
	var attacks: Array = []
	var heals: Array = []
	for c in u.chimes:
		match String(c.get("category", "attack")):
			"heal": heals.append(c)
			"buff": if randf() < 0.25: attacks.append(c)
			_: attacks.append(c)
	var hurt := float(u.current_hp) / maxf(1.0, float(u.max_hp)) < 0.35
	if hurt and not heals.is_empty() and randf() < 0.6:
		return { "type": EchoTypes.ActionType.CHIME, "chime_id": String(heals[0].id) }
	if attacks.is_empty():
		attacks = u.chimes
	var pick: Dictionary = attacks[randi() % attacks.size()]
	return { "type": EchoTypes.ActionType.CHIME, "chime_id": String(pick.id) }


func _play_log(log: Array) -> void:
	for ev in log:
		match String(ev.get("type", "")):
			"turn_order":
				var first := String(ev.get("first_name", ""))
				var second := String(ev.get("second_name", ""))
				var reason := String(ev.get("reason", "swift"))
				var line := ""
				if String(ev.get("first_side", "")) == "player":
					if reason == "priority":
						line = "%s moves first! (priority)" % first
					else:
						line = "%s is faster than %s!" % [first, second]
				else:
					if reason == "priority":
						line = "Foe %s moves first! (priority)" % first
					else:
						line = "Foe %s is faster than %s!" % [first, second]
				await _say(line)
			"damage":
				var m := float(ev.get("multiplier", 1.0))
				var extra := ""
				if m > 1.1: extra = " It resonates hard!"
				elif m < 0.9: extra = " It fizzles a little."
				msg.text = "%s used %s!%s" % [ev.actor, ev.chime, extra]
				menu_root.visible = false
				msg.visible = true
				msg.size = Vector2(226, 42)
				await get_tree().create_timer(0.35).timeout
				await _animate_attack(
					String(ev.side), int(ev.get("actor_index", _visual_index(String(ev.side)))),
					String(ev.get("target_side", "enemy" if ev.side == "player" else "player")),
					int(ev.get("target_index", _visual_index(String(ev.get("target_side", "enemy" if ev.side == "player" else "player"))))),
					int(ev.get("resonance", 0)), int(ev.get("damage", 0)), m,
					int(ev.get("target_hp_before", int(ev.get("target_hp", 0)) + int(ev.get("damage", 0)))),
					int(ev.get("target_hp", 0)), int(ev.get("target_max_hp", 1)),
					int(ev.get("actor_hp_before", int(ev.get("actor_hp", 0)))),
					int(ev.get("actor_max_hp", 1))
				)
				await _say("%s took %d damage!" % [String(ev.get("target", "Foe")), int(ev.get("damage", 0))])
			"heal":
				var heal_info := _side_info(String(ev.side))
				_set_hp_bar(
					heal_info,
					int(ev.get("actor_hp_before", int(ev.get("actor_hp", 0)))),
					int(ev.get("actor_max_hp", 1))
				)
				await _animate_heal(String(ev.side))
				_tween_hp_bar(heal_info, int(ev.get("actor_hp", 0)), int(ev.get("actor_max_hp", 1)))
				await get_tree().create_timer(0.15).timeout
				await _say("%s used %s and recovered HP!" % [ev.actor, ev.chime])
			"buff":
				await _animate_buff(String(ev.side))
				await _say("%s used %s! Its %s rose!" % [ev.actor, ev.chime, String(ev.get("stat", "power"))])
			"drain":
				var drain_info := _side_info(String(ev.side))
				_set_hp_bar(
					drain_info,
					int(ev.get("actor_hp_before", int(ev.get("actor_hp", 0)) - int(ev.get("amount", 0)))),
					int(ev.get("actor_max_hp", 1))
				)
				_tween_hp_bar(drain_info, int(ev.get("actor_hp", 0)), int(ev.get("actor_max_hp", 1)))
				await get_tree().create_timer(0.22).timeout
			"learn":
				await _say("%s learned %s!" % [ev.name, ev.move])
			"miss":
				await _say("%s used %s but missed!" % [ev.actor, ev.chime])
			"message":
				await _say(String(ev.get("text", "")))
			"faint":
				var fside := String(ev.get("side", "enemy"))
				await _animate_faint(fside, int(ev.get("index", _visual_index(fside))))
				await _say("%s fainted!" % ev.name)
			"need_switch":
				if not (_online and not _online_host):
					await _prompt_switch()
			"switch":
				var side := String(ev.side)
				var out_name := String(ev.get("out_name", ""))
				if bool(ev.get("auto", false)):
					var who := "Foe" if side == "enemy" else "You"
					await _say("%s sends out %s!" % [who, ev.name])
				elif out_name != "":
					await _say("%s, come back! Go, %s!" % [out_name, ev.name])
				else:
					await _say("Go, %s!" % ev.name)
				await _animate_switch(
					side, String(ev.name), out_name, bool(ev.get("auto", false)),
					int(ev.get("out_index", -1)), int(ev.get("in_index", -1))
				)
			"flee_ok":
				await _say("You got away safely!")
			"flee_fail":
				await _say("Couldn't escape!")
			"battle_end":
				pass


func _after_turn() -> void:
	if not state.get("finished", false):
		_visual_active["player"] = int(state.player.active)
		_visual_active["enemy"] = int(state.enemy.active)
		_refresh_all()
	if state.get("finished", false):
		var winner := String(state.get("winner", ""))
		if winner == "flee":
			_end_battle("flee")
		elif winner == "player":
			await _victory()
		else:
			await _defeat()
	else:
		_open_main_menu()


func _victory() -> void:
	var kind := String(request.get("kind", "wild"))
	if kind == "versus":
		await _say("You won! %s was defeated!" % String(request.get("trainer_name", "Rival")))
		_end_battle("win")
		return

	await _say("You won the battle!")
	GameState.flags["first_win"] = true
	var xp_events := CombatResolver.award_xp(state)
	GameState.sync_from_battle(state.player.units)

	var active := _unit_at("player", _visual_index("player"))
	for ev in xp_events:
		if String(ev.get("instance_id", "")) != String(active.instance_id):
			continue
		var amt := int(ev.get("amount", 0))
		if amt <= 0:
			break
		menu_root.visible = false
		msg.visible = false
		await _say("%s gained %d EXP!" % [active.name, amt])
		await _animate_xp_fill(player_info, String(active.name), int(active.xp), int(active.level), amt)
		break

	var growth := GameState.apply_xp(xp_events)
	_sync_party_xp_to_state()
	_refresh_side("player", player_info, player_sprite, _visual_index("player"))
	for g in growth:
		match String(g.get("type", "")):
			"level_up":
				await _say("%s grew to Lv%d!" % [g.name, int(g.level)])
			"learn":
				await _say("%s learned %s!" % [g.name, g.move])
			"evolve":
				await _say("What? %s evolved into %s!" % [g.from, g.to])

	if kind == "trainer":
		var tid := String(request.get("trainer_id", ""))
		if tid != "":
			GameState.flags["trainer_" + tid] = true
		var reward := int(request.get("reward", 0))
		if reward > 0:
			GameState.inventory["echo_capsule"] = int(GameState.inventory.get("echo_capsule", 0)) + reward
			await _say("%s handed you %d Echo Capsules!" % [String(request.get("trainer_name", "Rival")), reward])
		var wl := String(request.get("win_line", ""))
		if wl != "":
			await _say(wl)

	_end_battle("win")


func _defeat() -> void:
	if String(request.get("kind", "wild")) == "versus":
		await _say("Your team was defeated! %s wins." % String(request.get("trainer_name", "Rival")))
		_end_battle("loss")
		return
	GameState.sync_from_battle(state.player.units)
	await _say("Your Echoes are worn out...")
	GameState.heal_party()
	await _say("The nurse at Echo Rest nursed your team back to health.")
	GameState.current_map = "town"
	GameState.player_cell = Vector2i(17, 7)
	GameState.player_facing = "up"
	_end_battle("loss")


func _end_battle(result: String) -> void:
	phase = Phase.ENDED
	if _online and VersusNet.lobby_open():
		VersusNet.disconnect_lobby()
	if String(request.get("kind", "wild")) != "versus":
		GameState.sync_from_battle(state.player.units)
		SaveService.save_game(true)
	await SceneRouter.finish_battle({ "result": result })
