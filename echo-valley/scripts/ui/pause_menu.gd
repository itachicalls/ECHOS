extends CanvasLayer

## Overworld menu: Party / Bag / Journal. Toggle with the "menu" action.

const RES_NAMES := ["Normal", "Fire", "Water", "Grass", "Rock", "Air", "Shadow"]
const MENU_W := 228
const MENU_H := 148
const MENU_PAD := 5
const TAB_BLOCK_H := 28
const CONTENT_Y := 34
const CONTENT_H := MENU_H - CONTENT_Y - MENU_PAD

var _open: bool = false
var _tab: String = "party"
var _root: Control
var _content: VBoxContainer
var _dim: ColorRect
var _scroll: ScrollContainer


func _ready() -> void:
	layer = 20
	_build()
	visible = false
	EventBus.menu_requested.connect(_on_menu_requested)


func _on_menu_requested(tab: String) -> void:
	if EventBus.dialogue_active:
		return
	if _open:
		_tab = tab
		_render()
		return
	_tab = tab
	_show_menu()


func _process(_delta: float) -> void:
	if not _open:
		if not EventBus.dialogue_active:
			if Input.is_action_just_pressed("bag"):
				_on_menu_requested("bag")
			elif Input.is_action_just_pressed("menu"):
				_on_menu_requested("party")
	else:
		if Input.is_action_just_pressed("menu") or Input.is_action_just_pressed("cancel"):
			_hide_menu()
		elif Input.is_action_just_pressed("bag"):
			_tab = "bag"
			_render()


func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)

	var panel := Panel.new()
	panel.position = Vector2(6, 6)
	panel.size = Vector2(MENU_W, MENU_H)
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _style())
	_dim.add_child(panel)

	var tabs_block := VBoxContainer.new()
	tabs_block.position = Vector2(MENU_PAD, 4)
	tabs_block.size = Vector2(MENU_W - MENU_PAD * 2, TAB_BLOCK_H)
	tabs_block.add_theme_constant_override("separation", 2)
	panel.add_child(tabs_block)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 2)
	tabs_block.add_child(row1)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 2)
	tabs_block.add_child(row2)

	for t in [["Party", "party"], ["Bag", "bag"], ["Box", "box"]]:
		row1.add_child(_tab_button(String(t[0]), String(t[1])))
	for t in [["Journal", "journal"], ["Save", "save"], ["Close", "close"]]:
		row2.add_child(_tab_button(String(t[0]), String(t[1])))

	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(MENU_PAD, CONTENT_Y)
	_scroll.size = Vector2(MENU_W - MENU_PAD * 2 - 4, CONTENT_H)
	_scroll.clip_contents = true
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(_scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 2)
	_scroll.add_child(_content)

	_root = panel


func _tab_button(text: String, tab_id: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(68, 12)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 6)
	b.focus_mode = Control.FOCUS_NONE
	b.clip_text = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("24384a")
	sb.border_color = Color("4a6888")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.set_content_margin_all(1)
	b.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate()
	hover.bg_color = Color("2d4a62")
	hover.border_color = Color("8ec8ff")
	b.add_theme_stylebox_override("hover", hover)
	var pressed := sb.duplicate()
	pressed.bg_color = Color("1a2f42")
	b.add_theme_stylebox_override("pressed", pressed)
	b.pressed.connect(_on_tab.bind(tab_id))
	return b


func _style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1d2b3a")
	sb.border_color = Color("cfe8ff")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 4; sb.content_margin_right = 4
	sb.content_margin_top = 3; sb.content_margin_bottom = 3
	return sb


func _show_menu() -> void:
	_open = true
	visible = true
	EventBus.menu_active = true
	_lock_players(true)
	_render()


func _hide_menu() -> void:
	_open = false
	visible = false
	EventBus.menu_active = false
	_lock_players(false)


func _on_tab(tab: String) -> void:
	if tab == "close":
		_hide_menu()
		return
	if tab == "save":
		SaveService.save_game()
		EventBus.toast.emit("Game saved.")
		return
	_tab = tab
	_render()


func _render() -> void:
	_scroll.scroll_vertical = 0
	for c in _content.get_children():
		c.queue_free()
	match _tab:
		"party": _render_party()
		"bag": _render_bag()
		"box": _render_box()
		"journal": _render_journal()
	call_deferred("_fix_scroll_size")


func _fix_scroll_size() -> void:
	var w := _scroll.size.x
	var h := _content.get_combined_minimum_size().y
	_content.custom_minimum_size = Vector2(w, maxf(h, _scroll.size.y + 1))


# ---------------------------------------------------------------- Party
func _render_party() -> void:
	_content.add_child(_label("ACTIVE PARTY (%d/%d)" % [GameState.party.size(), EchoTypes.PARTY_SIZE], 7, Color("cfe8ff")))
	if GameState.party.is_empty():
		_content.add_child(_label("You have no Echoes yet.", 8))
		return
	for i in GameState.party.size():
		_content.add_child(_echo_card(GameState.party[i], true))


func _render_box() -> void:
	_content.add_child(_label("ECHO BOX — tap \u25B6Team to add to your party", 6, Color("cfe8ff")))
	if GameState.pc_box.is_empty():
		_content.add_child(_label("No Echoes in storage yet.", 8))
		_content.add_child(_label("Catch wild Echoes, then swap party members here.", 6, Color("a8c0d8")))
		return
	for i in GameState.pc_box.size():
		_content.add_child(_echo_card(GameState.pc_box[i], false))


const CARD_BTN_W := 42


func _echo_card(e: EchoInstance, in_party: bool) -> Control:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(0, 56)
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", _card_style())

	var h := HBoxContainer.new()
	h.position = Vector2(4, 3)
	h.size = Vector2(MENU_W - MENU_PAD * 2 - 16 - CARD_BTN_W, 50)
	h.add_theme_constant_override("separation", 5)
	card.add_child(h)

	var def := e.get_definition()
	if def and def.sprite_path != "":
		h.add_child(_echo_icon(def.sprite_path))

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	col.clip_contents = true
	h.add_child(col)

	var res_name: String = RES_NAMES[int(def.resonance)] if def else "Normal"
	var title := _label("%s  Lv%d  [%s]" % [e.display_name(), e.level, res_name], 7)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(title)
	col.add_child(_hp_row(e))
	col.add_child(_xp_row(e))
	var move_names: Array = []
	for c in e.get_chimes():
		move_names.append(c.name)
	var moves := _label("Moves: " + (", ".join(move_names) if not move_names.is_empty() else "-"), 5, Color("a8c0d8"))
	moves.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	moves.max_lines_visible = 2
	moves.clip_text = true
	col.add_child(moves)

	_add_swap_button(card, e, in_party)
	return card


func _add_swap_button(card: Control, e: EchoInstance, in_party: bool) -> void:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.clip_text = true
	btn.add_theme_font_size_override("font_size", 6)
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.offset_left = -(CARD_BTN_W + 4)
	btn.offset_right = -4
	btn.offset_top = 18
	btn.offset_bottom = 38

	var enabled: bool
	if in_party:
		btn.text = "\u25B6Box"
		enabled = GameState.party.size() > 1
		btn.pressed.connect(func(): _do_swap(e, true))
	else:
		btn.text = "\u25B6Team"
		enabled = GameState.party.size() < EchoTypes.PARTY_SIZE
		btn.pressed.connect(func(): _do_swap(e, false))

	btn.disabled = not enabled
	var base := Color("2c6e49") if in_party else Color("1d4e6b")
	var sb := StyleBoxFlat.new()
	sb.bg_color = base if enabled else Color("2a3644")
	sb.border_color = Color("8ec8ff") if enabled else Color("3d5066")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate()
	hover.bg_color = base.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := sb.duplicate()
	pressed.bg_color = base.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)
	var disabled_sb := sb.duplicate()
	btn.add_theme_stylebox_override("disabled", disabled_sb)
	btn.add_theme_color_override("font_color", Color("eaf7ff") if enabled else Color("6b7890"))
	btn.add_theme_color_override("font_disabled_color", Color("6b7890"))
	card.add_child(btn)


func _do_swap(e: EchoInstance, from_party: bool) -> void:
	var ok := false
	if from_party:
		ok = GameState.move_to_box(e)
		if not ok:
			EventBus.toast.emit("Can't box your last Echo.")
	else:
		ok = GameState.move_to_party(e)
		if not ok:
			EventBus.toast.emit("Party is full (max %d)." % EchoTypes.PARTY_SIZE)
	if ok:
		EventBus.toast.emit("%s moved to %s." % [e.display_name(), "Box" if from_party else "Party"])
		_render()


func _echo_icon(sprite_path: String) -> Control:
	const ICON_W := 36
	const ICON_H := 48
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(ICON_W, ICON_H)
	slot.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.11, 0.15, 0.65)
	sb.border_color = Color("2e4a60")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	slot.add_theme_stylebox_override("panel", sb)

	var icon := TextureRect.new()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.position = Vector2(2, 2)
	icon.size = Vector2(ICON_W - 4, ICON_H - 4)
	if ResourceLoader.exists(sprite_path):
		icon.texture = load(sprite_path)
	slot.add_child(icon)
	return slot


func _hp_row(e: EchoInstance) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 8)
	var maxhp := e.max_hp()
	var ratio := 0.0 if maxhp <= 0 else clampf(float(e.current_hp) / float(maxhp), 0.0, 1.0)
	var bg := ColorRect.new()
	bg.color = Color("22303c")
	bg.position = Vector2(0, 1)
	bg.size = Vector2(90, 3)
	wrap.add_child(bg)
	var fill := ColorRect.new()
	fill.color = Color("52b788") if ratio > 0.2 else Color("e63946")
	fill.position = Vector2(0, 1)
	fill.size = Vector2(90.0 * ratio, 3)
	wrap.add_child(fill)
	var lbl := _label("%d/%d" % [e.current_hp, maxhp], 5, Color("cfe8ff"))
	lbl.position = Vector2(94, 0)
	wrap.add_child(lbl)
	return wrap


func _xp_row(e: EchoInstance) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 8)
	var need := EchoTypes.xp_to_next(e.level)
	var ratio := 1.0 if e.level >= EchoTypes.MAX_LEVEL else float(e.xp) / maxf(1.0, float(need))
	var bg := ColorRect.new()
	bg.color = Color("22303c")
	bg.position = Vector2(0, 1)
	bg.size = Vector2(90, 3)
	wrap.add_child(bg)
	var fill := ColorRect.new()
	fill.color = Color("7dffb8")
	fill.position = Vector2(0, 1)
	fill.size = Vector2(90.0 * clampf(ratio, 0.0, 1.0), 3)
	wrap.add_child(fill)
	var txt := "MAX" if e.level >= EchoTypes.MAX_LEVEL else "%d/%d" % [e.xp, need]
	var lbl := _label("XP " + txt, 5, Color("a8c0d8"))
	lbl.position = Vector2(94, 0)
	wrap.add_child(lbl)
	return wrap


# ---------------------------------------------------------------- Bag
func _render_bag() -> void:
	_content.add_child(_label("ITEMS", 7, Color("cfe8ff")))
	var names := { "echo_capsule": "Echo Capsule", "heart_salve": "Heart Salve" }
	var descs := {
		"echo_capsule": "Toss at a weakened wild Echo to catch it.",
		"heart_salve": "Restores 60% HP to your most hurt Echo.",
	}
	var any := false
	for key in GameState.inventory.keys():
		var count := int(GameState.inventory[key])
		if count <= 0:
			continue
		any = true
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 6)
		top.add_child(_label("%s  x%d" % [String(names.get(key, String(key).capitalize())), count], 8))
		if key == "heart_salve":
			var use := Button.new()
			use.text = "Use"
			use.add_theme_font_size_override("font_size", 7)
			use.custom_minimum_size = Vector2(36, 13)
			use.pressed.connect(_use_salve)
			top.add_child(use)
		row.add_child(top)
		var desc := _label(String(descs.get(key, "")), 6, Color("a8c0d8"))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(MENU_W - MENU_PAD * 2 - 12, 0)
		row.add_child(desc)
		_content.add_child(row)
	if not any:
		_content.add_child(_label("Your bag is empty.", 8))
	var foot := _label("Captured Echoes are stored in the Box tab.", 6, Color("7c8aa0"))
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.custom_minimum_size = Vector2(MENU_W - MENU_PAD * 2 - 12, 0)
	_content.add_child(foot)


func _use_salve() -> void:
	if int(GameState.inventory.get("heart_salve", 0)) <= 0:
		return
	var target: EchoInstance = null
	var worst := 2.0
	for e in GameState.party:
		if e == null or e.is_fainted():
			continue
		var ratio := float(e.current_hp) / maxf(1.0, float(e.max_hp()))
		if e.current_hp < e.max_hp() and ratio < worst:
			worst = ratio
			target = e
	if target == null:
		EventBus.toast.emit("No Echo needs healing.")
		return
	GameState.inventory["heart_salve"] = int(GameState.inventory["heart_salve"]) - 1
	var heal := int(round(float(target.max_hp()) * 0.6))
	target.current_hp = mini(target.max_hp(), target.current_hp + heal)
	EventBus.toast.emit("%s recovered %d HP!" % [target.display_name(), heal])
	EventBus.party_changed.emit()
	_render()


# ---------------------------------------------------------------- Journal
func _render_journal() -> void:
	var cur := StoryService.current_stage()
	var head := Panel.new()
	head.custom_minimum_size = Vector2(0, 40)
	head.add_theme_stylebox_override("panel", _card_style())
	var hv := VBoxContainer.new()
	hv.position = Vector2(4, 2)
	hv.size = Vector2(MENU_W - MENU_PAD * 2 - 16, 36)
	hv.add_theme_constant_override("separation", 1)
	head.add_child(hv)
	hv.add_child(_label("CURRENT: " + String(cur.get("title", "-")), 7, Color("ffd166")))
	var obj := _label(String(cur.get("objective", "")), 6, Color("f2f7ff"))
	obj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	obj.custom_minimum_size = Vector2(MENU_W - MENU_PAD * 2 - 20, 0)
	hv.add_child(obj)
	var hint := _label("Hint: " + String(cur.get("hint", "")), 5, Color("a8c0d8"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(MENU_W - MENU_PAD * 2 - 20, 0)
	hv.add_child(hint)
	_content.add_child(head)

	_content.add_child(_label("QUEST LOG (%d/%d)" % [StoryService.completed_count(), StoryService.stages.size()], 7, Color("cfe8ff")))
	var cur_idx := StoryService.current_index()
	for i in StoryService.stages.size():
		var s: Dictionary = StoryService.stages[i]
		var mark := "[x]" if i < cur_idx else ("[>]" if i == cur_idx else "[ ]")
		var col := Color("7dffb8") if i < cur_idx else (Color("ffd166") if i == cur_idx else Color("7c8aa0"))
		var line := _label("%s %s" % [mark, String(s.get("title", ""))], 6, col)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(MENU_W - MENU_PAD * 2 - 12, 0)
		_content.add_child(line)


# ---------------------------------------------------------------- helpers
func _label(text: String, size: int, color: Color = Color("ffffff")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _card_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("24384a")
	sb.border_color = Color("3a556b")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	return sb


func _lock_players(v: bool) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("set_input_locked"):
			p.set_input_locked(v)
