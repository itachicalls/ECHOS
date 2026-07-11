extends CanvasLayer

## Overworld HUD: transient toasts + a GBA-style dialogue box.

const VIEW_W := 240
const VIEW_H := 160

var _toast: Label
var _toast_timer: float = 0.0

var _box: Panel
var _text: Label
var _arrow: Label
var _bag_btn: Control
var _menu_btn: Control
var _lines: Array = []
var _index: int = 0
var _open: bool = false


func _ready() -> void:
	layer = 10
	_build()
	EventBus.toast.connect(_on_toast)
	EventBus.dialogue_requested.connect(_on_dialogue)


func _build() -> void:
	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 8)
	_toast.add_theme_color_override("font_color", Color("fefae0"))
	_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_toast.add_theme_constant_override("outline_size", 4)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(0, 4)
	_toast.size = Vector2(VIEW_W, 12)
	_toast.modulate.a = 0.0
	add_child(_toast)

	# Fixed coordinates — no anchors (anchors break when the window is scaled on PC/web).
	_box = Panel.new()
	_box.position = Vector2(4, 106)
	_box.size = Vector2(VIEW_W - 8, 50)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1d2b3a")
	sb.border_color = Color("cfe8ff")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 6
	sb.content_margin_top = 4
	sb.content_margin_right = 6
	sb.content_margin_bottom = 4
	_box.add_theme_stylebox_override("panel", sb)
	_box.visible = false
	add_child(_box)

	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 8)
	_text.add_theme_color_override("font_color", Color("f2f7ff"))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.position = Vector2(6, 4)
	_text.size = Vector2(VIEW_W - 28, 38)
	_text.clip_text = true
	_box.add_child(_text)

	_arrow = Label.new()
	_arrow.text = "\u25BC"
	_arrow.add_theme_font_size_override("font_size", 7)
	_arrow.add_theme_color_override("font_color", Color("cfe8ff"))
	_arrow.position = Vector2(VIEW_W - 28, 34)
	_box.add_child(_arrow)

	_build_quick_bar()


func _build_quick_bar() -> void:
	var bar := Panel.new()
	bar.position = Vector2(194, 144)
	bar.size = Vector2(42, 14)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_sb := StyleBoxFlat.new()
	bar_sb.bg_color = Color(0.09, 0.14, 0.20, 0.78)
	bar_sb.border_color = Color("4a6888")
	bar_sb.set_border_width_all(1)
	bar_sb.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("panel", bar_sb)
	add_child(bar)

	_menu_btn = _make_quick_btn(Vector2(196, 146), _icon_menu, "Menu (M)", func(): EventBus.menu_requested.emit("party"))
	_bag_btn = _make_quick_btn(Vector2(214, 146), _icon_bag, "Bag (E)", func(): EventBus.menu_requested.emit("bag"))


func _make_quick_btn(pos: Vector2, icon_fn: Callable, tip: String, cb: Callable) -> Control:
	var wrap := Control.new()
	wrap.position = pos
	wrap.size = Vector2(16, 12)
	wrap.custom_minimum_size = Vector2(16, 12)
	wrap.clip_contents = true

	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.tooltip_text = tip
	btn.pressed.connect(cb)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.15, 0.24, 0.33, 0.95)
	normal.border_color = Color("3d5a74")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)
	normal.set_content_margin_all(0)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color("2a4560")
	hover.border_color = Color("8ec8ff")
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate()
	pressed.bg_color = Color("142433")
	btn.add_theme_stylebox_override("pressed", pressed)
	wrap.add_child(btn)

	var icon := Control.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_fn.call(icon)
	wrap.add_child(icon)

	add_child(wrap)
	return wrap


func _icon_menu(parent: Control) -> void:
	for i in 3:
		var line := ColorRect.new()
		line.color = Color("d8ecff")
		line.position = Vector2(4, 3 + i * 3)
		line.size = Vector2(8, 1)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(line)


func _icon_bag(parent: Control) -> void:
	var body := ColorRect.new()
	body.color = Color("c9a45a")
	body.position = Vector2(4, 5)
	body.size = Vector2(8, 6)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(body)
	var flap := ColorRect.new()
	flap.color = Color("e8c878")
	flap.position = Vector2(3, 3)
	flap.size = Vector2(10, 2)
	flap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(flap)
	var dot := ColorRect.new()
	dot.color = Color("fff3c4")
	dot.position = Vector2(7, 7)
	dot.size = Vector2(2, 2)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(dot)


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast.modulate.a = clampf(_toast_timer, 0.0, 1.0)
	var hud_visible := not EventBus.dialogue_active and not EventBus.menu_active
	_bag_btn.visible = hud_visible
	_menu_btn.visible = hud_visible
	if _open:
		_arrow.visible = int(Time.get_ticks_msec() / 350) % 2 == 0
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("cancel"):
			_advance()


func _on_toast(text: String) -> void:
	_toast.text = text
	_toast_timer = 2.0
	_toast.modulate.a = 1.0


func _on_dialogue(lines: Array) -> void:
	_lines = lines
	_index = 0
	_open = true
	_box.visible = true
	EventBus.dialogue_active = true
	_lock_player(true)
	_show_current()


func _show_current() -> void:
	if _index < _lines.size():
		_text.text = String(_lines[_index])


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_open = false
		_box.visible = false
		EventBus.dialogue_active = false
		_lock_player(false)
		EventBus.dialogue_closed.emit()
	else:
		_show_current()


func _lock_player(v: bool) -> void:
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_method("set_input_locked"):
			p.set_input_locked(v)
