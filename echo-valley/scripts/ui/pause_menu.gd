extends CanvasLayer

## Overworld menu: Party / Bag / Journal. Toggle with the "menu" action.

const RES_NAMES := ["Normal", "Fire", "Water", "Grass", "Rock", "Air", "Shadow"]
const ItemIcon := preload("res://scripts/ui/item_icon.gd")
const MENU_W := 228
const MENU_H := 148
const MENU_PAD := 5
const TAB_BLOCK_H := 28
const SECTION_Y := 35
const CONTENT_Y := 47
const LIST_H := MENU_H - CONTENT_Y - MENU_PAD

var _open: bool = false
var _tab: String = "party"
var _root: Control
var _content: VBoxContainer
var _dim: ColorRect
var _scroll: ScrollContainer
var _section_title: Label
var _list_frame: Panel


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
	_dim.gui_input.connect(_on_dim_input)
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

	_section_title = Label.new()
	_section_title.position = Vector2(MENU_PAD, SECTION_Y)
	_section_title.size = Vector2(MENU_W - MENU_PAD * 2, 10)
	_section_title.clip_text = true
	_section_title.add_theme_font_size_override("font_size", 7)
	_section_title.add_theme_color_override("font_color", Color("cfe8ff"))
	panel.add_child(_section_title)

	_list_frame = Panel.new()
	_list_frame.position = Vector2(MENU_PAD, CONTENT_Y)
	_list_frame.size = Vector2(MENU_W - MENU_PAD * 2, LIST_H)
	_list_frame.clip_contents = true
	_list_frame.add_theme_stylebox_override("panel", _list_frame_style())
	panel.add_child(_list_frame)

	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(3, 3)
	_scroll.size = Vector2(MENU_W - MENU_PAD * 2 - 6, LIST_H - 6)
	_scroll.clip_contents = true
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_list_frame.add_child(_scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 3)
	_scroll.add_child(_content)

	_root = panel


func _on_dim_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventScreenTouch and event.pressed:
		_hide_menu()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_menu()


func _tab_button(text: String, tab_id: String) -> Button:
	var b := Button.new()
	b.text = text
	var touch := TouchUtil != null and TouchUtil.is_touch_ui_enabled()
	b.custom_minimum_size = Vector2(68, 14 if touch else 12)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 7 if touch else 6)
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


func _list_frame_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("152433")
	sb.border_color = Color("3a556b")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 2
	sb.content_margin_right = 2
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	return sb


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
	var list_w := maxf(8.0, _scroll.size.x - 2.0)
	_content.custom_minimum_size = Vector2(list_w, 0)
	for c in _content.get_children():
		c.queue_free()
	match _tab:
		"party": _render_party()
		"bag": _render_bag()
		"box": _render_box()
		"journal": _render_journal()
	call_deferred("_fix_scroll_size")


func _fix_scroll_size() -> void:
	var w := maxf(8.0, _scroll.size.x - 2.0)
	var h := _content.get_combined_minimum_size().y
	_content.custom_minimum_size = Vector2(w, maxf(h, _scroll.size.y + 1))


# ---------------------------------------------------------------- Party
func _render_party() -> void:
	_section_title.text = "%s's PARTY (%d/%d)" % [GameState.player_name, GameState.party.size(), EchoTypes.PARTY_SIZE]
	if GameState.party.is_empty():
		_content.add_child(_label("You have no %s yet." % GameStrings.CREATURE_PLURAL_LOWER, 8))
		return
	for i in GameState.party.size():
		_content.add_child(_echo_card(GameState.party[i], true, i))


func _render_box() -> void:
	_section_title.text = "ECHO BOX"
	_content.add_child(_label("Tap Team to add to party", 6, Color("a8c0d8")))
	if GameState.pc_box.is_empty():
		_content.add_child(_label("No %s in storage yet." % GameStrings.CREATURE_PLURAL_LOWER, 8))
		_content.add_child(_label("Catch wild %s, then swap party members here." % GameStrings.CREATURE_PLURAL_LOWER, 6, Color("a8c0d8")))
		return
	for i in GameState.pc_box.size():
		_content.add_child(_echo_card(GameState.pc_box[i], false))


const CARD_W := 200
const CARD_H := 52
const ACTION_W := 34
const ACTION_H := 14
const ITEM_ROW_W := MENU_W - MENU_PAD * 2 - 6
const ITEM_ROW_H := 38
const ITEM_ICON_W := 14


func _echo_card(e: EchoInstance, in_party: bool, party_index: int = -1) -> Control:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	card.size = Vector2(CARD_W, CARD_H)
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", _card_style())

	const ICON_W := 28
	const ICON_H := 40
	const PAD := 3
	var info_x := PAD + ICON_W + 3
	var actions_w := ACTION_W
	var info_w := CARD_W - info_x - actions_w - PAD - 2

	var def := e.get_definition()
	if def and def.sprite_path != "":
		var icon_slot := _echo_icon(def.sprite_path, ICON_W, ICON_H)
		icon_slot.position = Vector2(PAD, 6)
		card.add_child(icon_slot)

	var col := VBoxContainer.new()
	col.position = Vector2(info_x, 3)
	col.size = Vector2(info_w, CARD_H - 6)
	col.custom_minimum_size = Vector2(info_w, CARD_H - 6)
	col.add_theme_constant_override("separation", 0)
	col.clip_contents = true
	card.add_child(col)

	var res_name: String = RES_NAMES[int(def.resonance)] if def else "Normal"
	var title := _label("%s  Lv%d  [%s]" % [e.display_name(), e.level, res_name], 7)
	title.custom_minimum_size = Vector2(info_w, 9)
	title.size = Vector2(info_w, 9)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(title)
	col.add_child(_hp_row(e, mini(info_w - 36, 68)))
	col.add_child(_xp_row(e, mini(info_w - 36, 68)))
	var move_names: Array = []
	for c in e.get_chimes():
		move_names.append(c.name)
	var moves := _label("Moves: " + (", ".join(move_names) if not move_names.is_empty() else "-"), 5, Color("a8c0d8"))
	moves.custom_minimum_size = Vector2(info_w, 0)
	moves.size = Vector2(info_w, 0)
	moves.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	moves.max_lines_visible = 2
	moves.clip_text = true
	col.add_child(moves)

	if in_party and party_index == 0:
		title.add_theme_color_override("font_color", Color("ffe08a"))

	var actions := VBoxContainer.new()
	actions.position = Vector2(CARD_W - ACTION_W - PAD, 8)
	actions.size = Vector2(ACTION_W, CARD_H - 16)
	actions.add_theme_constant_override("separation", 2)
	card.add_child(actions)

	if in_party:
		if party_index == 0:
			actions.add_child(_mini_button("LEAD", false, Color("ffe08a")))
		elif not e.is_fainted():
			actions.add_child(_mini_button("Lead", true, Color("f2f7ff"), func(): _set_lead(e)))
		else:
			actions.add_child(_mini_button("Lead", false, Color("6b7890")))
		var box_enabled := GameState.party.size() > 1
		actions.add_child(_mini_button("Box", box_enabled, Color("f2f7ff"), func(): _do_swap(e, true) if box_enabled else Callable()))
	else:
		var team_enabled := GameState.party.size() < EchoTypes.PARTY_SIZE
		actions.add_child(_mini_button("Team", team_enabled, Color("f2f7ff"), func(): _do_swap(e, false) if team_enabled else Callable()))
	return card


func _mini_button(text: String, enabled: bool, col: Color, cb: Callable = Callable()) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(ACTION_W, ACTION_H)
	b.size = Vector2(ACTION_W, ACTION_H)
	b.focus_mode = Control.FOCUS_NONE
	b.clip_text = true
	b.disabled = not enabled
	b.add_theme_font_size_override("font_size", 6)
	b.add_theme_color_override("font_color", col)
	b.add_theme_color_override("font_disabled_color", Color("6b7890"))
	var sb := _mini_btn_style(Color("2b3f56") if enabled else Color("263140"), Color("8ec8ff") if enabled else Color("3d5066"))
	b.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate()
	hover.bg_color = Color("3d597a")
	hover.border_color = Color("ffffff")
	b.add_theme_stylebox_override("hover", hover)
	var pressed := sb.duplicate()
	pressed.bg_color = Color("1d2b3a")
	pressed.border_color = Color("ffd166")
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if enabled and cb.is_valid():
		b.pressed.connect(cb)
	return b


func _set_lead(e: EchoInstance) -> void:
	if GameState.set_party_lead(e):
		EventBus.toast.emit("%s is now your lead %s!" % [e.display_name(), GameStrings.CREATURE_LOWER])
		_render()


func _mini_btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	return sb


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


func _echo_icon(sprite_path: String, icon_w: int = 28, icon_h: int = 40) -> Control:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(icon_w, icon_h)
	slot.size = Vector2(icon_w, icon_h)
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
	icon.size = Vector2(icon_w - 4, icon_h - 4)
	if ResourceLoader.exists(sprite_path):
		icon.texture = load(sprite_path)
	slot.add_child(icon)
	return slot


func _hp_row(e: EchoInstance, bar_w: int = 68) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 8)
	var maxhp := e.max_hp()
	var ratio := 0.0 if maxhp <= 0 else clampf(float(e.current_hp) / float(maxhp), 0.0, 1.0)
	var bg := ColorRect.new()
	bg.color = Color("22303c")
	bg.position = Vector2(0, 1)
	bg.size = Vector2(bar_w, 3)
	wrap.add_child(bg)
	var fill := ColorRect.new()
	fill.color = Color("52b788") if ratio > 0.2 else Color("e63946")
	fill.position = Vector2(0, 1)
	fill.size = Vector2(float(bar_w) * ratio, 3)
	wrap.add_child(fill)
	var lbl := _label("%d/%d" % [e.current_hp, maxhp], 5, Color("cfe8ff"))
	lbl.position = Vector2(bar_w + 2, 0)
	wrap.add_child(lbl)
	return wrap


func _xp_row(e: EchoInstance, bar_w: int = 68) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 8)
	var need := EchoTypes.xp_to_next(e.level)
	var ratio := 1.0 if e.level >= EchoTypes.MAX_LEVEL else float(e.xp) / maxf(1.0, float(need))
	var bg := ColorRect.new()
	bg.color = Color("22303c")
	bg.position = Vector2(0, 1)
	bg.size = Vector2(bar_w, 3)
	wrap.add_child(bg)
	var fill := ColorRect.new()
	fill.color = Color("7dffb8")
	fill.position = Vector2(0, 1)
	fill.size = Vector2(float(bar_w) * clampf(ratio, 0.0, 1.0), 3)
	wrap.add_child(fill)
	var txt := "MAX" if e.level >= EchoTypes.MAX_LEVEL else "%d/%d" % [e.xp, need]
	var lbl := _label("XP " + txt, 5, Color("a8c0d8"))
	lbl.position = Vector2(bar_w + 2, 0)
	wrap.add_child(lbl)
	return wrap


# ---------------------------------------------------------------- Bag
func _render_bag() -> void:
	_section_title.text = "ITEMS"
	var row_w := ITEM_ROW_W
	var any := false
	for key in GameState.inventory.keys():
		var item_id := String(key)
		var count := int(GameState.inventory[item_id])
		if count <= 0 or not ItemCatalog.has(item_id):
			continue
		any = true
		_content.add_child(_item_row(item_id, count, row_w))
	if not any:
		_content.add_child(_fixed_label("Your bag is empty.", row_w, 8))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(row_w, 6)
	spacer.size = Vector2(row_w, 6)
	_content.add_child(spacer)
	var foot := _fixed_label(
		"Captured %s are stored in the Box tab." % GameStrings.CREATURE_PLURAL_LOWER,
		row_w, 6, Color("7c8aa0")
	)
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.custom_minimum_size = Vector2(row_w, 22)
	foot.size = Vector2(row_w, 22)
	_content.add_child(foot)


func _item_row(item_id: String, count: int, row_w: int) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(row_w, ITEM_ROW_H)
	card.size = Vector2(row_w, ITEM_ROW_H)
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", _card_style())

	var pad := 4
	var icon_x := pad
	var text_x := pad + ITEM_ICON_W + 4
	var usable := ItemCatalog.usable_in_field(item_id)
	var btn_slot := ACTION_W + pad if usable else pad
	var text_w := row_w - text_x - btn_slot

	var icon := ItemIcon.make(item_id, ITEM_ICON_W)
	icon.position = Vector2(icon_x, 6)
	card.add_child(icon)

	var name_lbl := _fixed_label("%s  x%d" % [ItemCatalog.display_name(item_id), count], text_w, 8)
	name_lbl.position = Vector2(text_x, 4)
	name_lbl.size = Vector2(text_w, 10)
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card.add_child(name_lbl)

	if usable:
		var use_btn := _mini_button("Use", true, Color("f2f7ff"), _use_bag_item.bind(item_id))
		use_btn.position = Vector2(row_w - ACTION_W - pad, 4)
		card.add_child(use_btn)

	var desc := _fixed_label(ItemCatalog.description(item_id), text_w, 6, Color("a8c0d8"))
	desc.position = Vector2(text_x, 16)
	desc.size = Vector2(text_w, ITEM_ROW_H - 18)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.max_lines_visible = 2
	desc.clip_text = true
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card.add_child(desc)
	return card


func _use_bag_item(item_id: String) -> void:
	match item_id:
		"heart_salve":
			_use_salve()
		"revive_capsule":
			_use_revive_bag()
		"evo_capsule":
			_use_evo_bag()


func _use_revive_bag() -> void:
	if not ItemCatalog.consume_item("revive_capsule", 1):
		return
	var target: EchoInstance = null
	for e in GameState.party:
		if e and e.is_fainted():
			target = e
			break
	if target == null:
		ItemCatalog.add_item("revive_capsule", 1)
		EventBus.toast.emit("No fainted %s to revive." % GameStrings.CREATURE_PLURAL_LOWER)
		return
	target.revive_from_capsule()
	EventBus.toast.emit("%s was revived!" % target.display_name())
	EventBus.party_changed.emit()
	_render()


func _use_evo_bag() -> void:
	if not ItemCatalog.consume_item("evo_capsule", 1):
		return
	var target: EchoInstance = null
	for e in GameState.party:
		if e and e.can_evolve_now():
			target = e
			break
	if target == null:
		ItemCatalog.add_item("evo_capsule", 1)
		EventBus.toast.emit("No %s is ready to evolve." % GameStrings.CREATURE_PLURAL_LOWER)
		return
	var evo := target.evolve_with_capsule()
	if evo.is_empty():
		ItemCatalog.add_item("evo_capsule", 1)
		EventBus.toast.emit("Evolution failed.")
		return
	EventBus.toast.emit("%s evolved into %s!" % [String(evo.from), String(evo.to)])
	EventBus.party_changed.emit()
	_render()


func _use_salve() -> void:
	if not ItemCatalog.consume_item("heart_salve", 1):
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
	_section_title.text = "JOURNAL"
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


func _fixed_label(text: String, width: int, size: int, color: Color = Color("ffffff")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.custom_minimum_size = Vector2(width, 0)
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
