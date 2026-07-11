extends CanvasLayer

## On-screen D-pad + action button for touch / mobile play. Arrows are drawn as
## vector triangles (the pixel font has no arrow glyphs), the pad is compact, and
## the whole overlay only appears on touch devices — never on desktop / CPU play.

const DIRS := ["move_up", "move_down", "move_left", "move_right"]

var _dir_btns: Dictionary = {}
var _held: Dictionary = {}


func _ready() -> void:
	layer = 9
	if not _touch_target():
		queue_free()
		return
	_build()


func _touch_target() -> bool:
	# Mobile / touch only. Desktop and CPU-vs players never see this.
	if OS.has_environment("EV_FORCE_TOUCH"):
		return true
	if OS.has_feature("mobile"):
		return true
	return DisplayServer.is_touchscreen_available()


func _build() -> void:
	# Compact D-pad, lower-left (16x16 keys in a plus)
	_dir_btns["move_up"] = _dir_btn(Vector2(20, 110), "up")
	_dir_btns["move_left"] = _dir_btn(Vector2(4, 126), "left")
	_dir_btns["move_right"] = _dir_btn(Vector2(36, 126), "right")
	_dir_btns["move_down"] = _dir_btn(Vector2(20, 142), "down")
	for a in DIRS:
		_held[a] = false

	# A (interact / confirm), lower-right
	var a_btn := Button.new()
	a_btn.position = Vector2(206, 124)
	a_btn.size = Vector2(28, 22)
	a_btn.custom_minimum_size = a_btn.size
	a_btn.text = "A"
	a_btn.focus_mode = Control.FOCUS_NONE
	a_btn.add_theme_font_size_override("font_size", 11)
	a_btn.add_theme_color_override("font_color", Color("eaf4ff"))
	_style_btn(a_btn)
	a_btn.button_down.connect(func(): Input.action_press("interact"))
	a_btn.button_up.connect(func(): Input.action_release("interact"))
	add_child(a_btn)


func _dir_btn(pos: Vector2, dir: String) -> Button:
	var b := Button.new()
	b.position = pos
	b.size = Vector2(16, 16)
	b.custom_minimum_size = b.size
	b.focus_mode = Control.FOCUS_NONE
	_style_btn(b)
	b.draw.connect(_draw_arrow.bind(b, dir))
	add_child(b)
	return b


func _draw_arrow(b: Button, dir: String) -> void:
	var c := b.size * 0.5
	var a := 4.0
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


func _process(_delta: float) -> void:
	var block := EventBus.dialogue_active or EventBus.menu_active
	for a in DIRS:
		var btn: Button = _dir_btns.get(a, null)
		if btn == null:
			continue
		btn.visible = not block
		var want: bool = (not block) and btn.button_pressed
		if want and not bool(_held[a]):
			Input.action_press(a)
			_held[a] = true
			btn.queue_redraw()
		elif not want and bool(_held[a]):
			Input.action_release(a)
			_held[a] = false
			btn.queue_redraw()


func _exit_tree() -> void:
	for a in DIRS:
		if bool(_held.get(a, false)):
			Input.action_release(a)
