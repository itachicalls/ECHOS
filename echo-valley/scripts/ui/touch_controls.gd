extends CanvasLayer

## Global on-screen D-pad + A button for touch / mobile. Autoloaded so every scene
## (overworld, battle, menus) can advance dialogue and move on phones.

const DIRS := ["move_up", "move_down", "move_left", "move_right"]

var _dir_btns: Dictionary = {}
var _a_btn: Button
var _held: Dictionary = {}


func _ready() -> void:
	layer = 9
	if not TouchUtil.is_touch_ui_enabled():
		queue_free()
		return
	_build()


const KEY := 22
const GAP := 2


func _build() -> void:
	# Compact D-pad, lower-left — sized for comfortable mobile thumbs.
	var cx := 24
	var cy := 118
	_dir_btns["move_up"] = _dir_btn(Vector2(cx, cy - KEY - GAP), "up")
	_dir_btns["move_left"] = _dir_btn(Vector2(cx - KEY - GAP, cy), "left")
	_dir_btns["move_right"] = _dir_btn(Vector2(cx + KEY + GAP, cy), "right")
	_dir_btns["move_down"] = _dir_btn(Vector2(cx, cy + KEY + GAP), "down")
	for a in DIRS:
		_held[a] = false

	_a_btn = Button.new()
	_a_btn.position = Vector2(200, 118)
	_a_btn.size = Vector2(34, 26)
	_a_btn.custom_minimum_size = _a_btn.size
	_a_btn.text = "A"
	_a_btn.focus_mode = Control.FOCUS_NONE
	_a_btn.add_theme_font_size_override("font_size", 11)
	_a_btn.add_theme_color_override("font_color", Color("eaf4ff"))
	_style_btn(_a_btn)
	_a_btn.button_down.connect(_on_a_down)
	_a_btn.button_up.connect(_on_a_up)
	add_child(_a_btn)


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
	add_child(b)
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
	b.add_theme_stylebox_override("normal", _style(Color(0.11, 0.17, 0.24, 0.6), Color(0.55, 0.72, 0.9, 0.65)))
	b.add_theme_stylebox_override("hover", _style(Color(0.16, 0.26, 0.35, 0.72), Color(0.7, 0.85, 1.0, 0.85)))
	b.add_theme_stylebox_override("pressed", _style(Color(0.08, 0.36, 0.4, 0.85), Color("ffd166")))
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
	var show_pad := _in_overworld() and not EventBus.dialogue_active and not EventBus.menu_active
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
	# A stays visible except during menus and dialogue (dialogue has its own tap target).
	if _a_btn:
		_a_btn.visible = not EventBus.menu_active and not EventBus.dialogue_active


func _exit_tree() -> void:
	for a in DIRS:
		if bool(_held.get(a, false)):
			Input.action_release(a)
