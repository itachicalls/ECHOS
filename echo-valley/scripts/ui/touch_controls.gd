extends CanvasLayer

## Global on-screen D-pad + A button for touch / mobile. Autoloaded so every scene
## can move and interact on phones without overlapping battle menus.

const DIRS := ["move_up", "move_down", "move_left", "move_right"]
const GAME_W := 240.0
const GAME_H := 160.0

var _root: Control
var _dir_btns: Dictionary = {}
var _a_btn: Button
var _held: Dictionary = {}


func _ready() -> void:
	layer = 9
	if not TouchUtil.is_touch_ui_enabled():
		queue_free()
		return
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build()


const KEY := 20
const GAP := 2
const A_W := 28
const A_H := 22
const PAD_EXTRA := 6


func _build() -> void:
	_layout_controls()
	for a in DIRS:
		_held[a] = false


func _layout_controls() -> void:
	var m := TouchUtil.get_game_margins()
	if m == Vector4.ZERO:
		m = Vector4(4, 2, 4, 8)
	var pad_l := int(m.x) + PAD_EXTRA
	var pad_r := int(m.z) + PAD_EXTRA
	var pad_b := int(m.w) + PAD_EXTRA

	# D-pad center inset so left + down arms stay inside 240x160.
	var cx := pad_l + KEY + GAP
	var cy := int(GAME_H) - pad_b - (KEY + GAP + KEY)

	_reposition_dpad(cx, cy)

	if _a_btn == null:
		_a_btn = Button.new()
		_a_btn.size = Vector2(A_W, A_H)
		_a_btn.custom_minimum_size = _a_btn.size
		_a_btn.text = "A"
		_a_btn.focus_mode = Control.FOCUS_NONE
		_a_btn.add_theme_font_size_override("font_size", 9)
		_a_btn.add_theme_color_override("font_color", Color("eaf4ff"))
		_style_btn(_a_btn)
		_a_btn.button_down.connect(_on_a_down)
		_a_btn.button_up.connect(_on_a_up)
		_root.add_child(_a_btn)

	# A on the right thumb — opposite side from movement.
	_a_btn.position = Vector2(int(GAME_W) - pad_r - A_W, cy - 1)


func _reposition_dpad(cx: int, cy: int) -> void:
	if _dir_btns.is_empty():
		_dir_btns["move_up"] = _dir_btn(Vector2(cx, cy - KEY - GAP), "up")
		_dir_btns["move_left"] = _dir_btn(Vector2(cx - KEY - GAP, cy), "left")
		_dir_btns["move_right"] = _dir_btn(Vector2(cx + KEY + GAP, cy), "right")
		_dir_btns["move_down"] = _dir_btn(Vector2(cx, cy + KEY + GAP), "down")
		return
	var up: Button = _dir_btns.get("move_up", null)
	var left: Button = _dir_btns.get("move_left", null)
	var right: Button = _dir_btns.get("move_right", null)
	var down: Button = _dir_btns.get("move_down", null)
	if up:
		up.position = Vector2(cx, cy - KEY - GAP)
	if left:
		left.position = Vector2(cx - KEY - GAP, cy)
	if right:
		right.position = Vector2(cx + KEY + GAP, cy)
	if down:
		down.position = Vector2(cx, cy + KEY + GAP)


func _on_a_down() -> void:
	TouchUtil.register_tap()
	if EventBus.dialogue_active or EventBus.awaiting_continue:
		return
	Input.action_press("interact")


func _on_a_up() -> void:
	if EventBus.dialogue_active or EventBus.awaiting_continue:
		return
	Input.action_release("interact")


func _dir_btn(pos: Vector2, dir: String) -> Button:
	var b := Button.new()
	b.position = pos
	b.size = Vector2(KEY, KEY)
	b.custom_minimum_size = Vector2(KEY, KEY)
	b.focus_mode = Control.FOCUS_NONE
	_style_btn(b)
	b.draw.connect(_draw_arrow.bind(b, dir))
	_root.add_child(b)
	return b


func _draw_arrow(b: Button, dir: String) -> void:
	var c := b.size * 0.5
	var a := 6.0
	var pts: PackedVector2Array
	match dir:
		"up":
			pts = PackedVector2Array([Vector2(c.x, c.y - a), Vector2(c.x - a, c.y + a), Vector2(c.x + a, c.y + a)])
		"down":
			pts = PackedVector2Array([Vector2(c.x, c.y + a), Vector2(c.x - a, c.y - a), Vector2(c.x + a, c.y - a)])
		"left":
			pts = PackedVector2Array([Vector2(c.x - a, c.y), Vector2(c.x + a, c.y - a), Vector2(c.x + a, c.y + a)])
		"right":
			pts = PackedVector2Array([Vector2(c.x + a, c.y), Vector2(c.x - a, c.y - a), Vector2(c.x - a, c.y + a)])
	var col := Color("ffd166") if bool(_held.get(_dir_of(dir), false)) else Color("eaf4ff")
	b.draw_colored_polygon(pts, col)


func _dir_of(dir: String) -> String:
	return "move_" + dir


func _style_btn(b: Button) -> void:
	b.add_theme_stylebox_override("normal", _style(Color(0.11, 0.17, 0.24, 0.72), Color(0.55, 0.72, 0.9, 0.75)))
	b.add_theme_stylebox_override("hover", _style(Color(0.16, 0.26, 0.35, 0.82), Color(0.7, 0.85, 1.0, 0.9)))
	b.add_theme_stylebox_override("pressed", _style(Color(0.08, 0.36, 0.4, 0.9), Color("ffd166")))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	return sb


func _in_overworld() -> bool:
	return get_tree().get_first_node_in_group("player") != null


func _process(_delta: float) -> void:
	var show_pad := (
		_in_overworld()
		and not EventBus.dialogue_active
		and not EventBus.menu_active
		and not EventBus.battle_active
	)
	for a in DIRS:
		var btn: Button = _dir_btns.get(a, null)
		if btn == null:
			continue
		btn.visible = show_pad
		var want: bool = show_pad and btn.button_pressed
		if want and not bool(_held[a]):
			Input.action_press(a)
			_held[a] = true
			btn.queue_redraw()
		elif not want and bool(_held[a]):
			Input.action_release(a)
			_held[a] = false
			btn.queue_redraw()
	if _a_btn:
		_a_btn.visible = show_pad and not EventBus.battle_menu_active


func _exit_tree() -> void:
	for a in DIRS:
		if bool(_held.get(a, false)):
			Input.action_release(a)
