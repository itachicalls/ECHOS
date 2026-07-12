extends RefCounted
class_name TitleFonts

const FONT_PATH := "res://assets/fonts/PressStart2P-Regular.ttf"

static var _base: FontFile


static func get_font() -> FontFile:
	if _base == null:
		_base = load(FONT_PATH) as FontFile
		if _base == null:
			_base = FontFile.new()
			_base.load_dynamic_font(FONT_PATH)
	return _base


static func apply(node: Control, size: int, color: Color, outline: Color = Color(0, 0, 0, 0), outline_sz: int = 0) -> void:
	var font := get_font()
	if font == null:
		return
	node.add_theme_font_override("font", font)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	if outline.a > 0.0 and outline_sz > 0:
		node.add_theme_color_override("font_outline_color", outline)
		node.add_theme_constant_override("outline_size", outline_sz)


static func measure(text: String, size: int) -> float:
	var font := get_font()
	if font == null:
		return float(text.length()) * float(size) * 0.55
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func fit_label(node: Control, text: String, max_w: float, color: Color, start: int = 5, min_sz: int = 3) -> void:
	var sz := start
	while sz > min_sz and measure(text, sz) > max_w:
		sz -= 1
	var display := text
	if measure(display, sz) > max_w:
		while display.length() > 2 and measure(display + "..", sz) > max_w:
			display = display.substr(0, display.length() - 1)
		if measure(display, sz) > max_w:
			display = display.substr(0, maxi(2, display.length() - 2)) + ".."
	if node is Label:
		(node as Label).text = display
	elif node is Button:
		(node as Button).text = display
	apply(node, sz, color)
	if node is Label:
		(node as Label).add_theme_constant_override("line_spacing", 0)


static func shadow_label(parent: Control, text: String, size: int, color: Color, pos: Vector2, sz: Vector2, align: int = HORIZONTAL_ALIGNMENT_CENTER, outline: Color = Color("1a1030"), outline_sz: int = 0, z_index: int = 0) -> Label:
	# Soft 1px drop shadow only — thick theme outlines garble Press Start 2P.
	var shadow := Label.new()
	shadow.text = text
	shadow.position = pos + Vector2(1, 1)
	shadow.size = sz
	shadow.horizontal_alignment = align
	shadow.z_index = z_index
	apply(shadow, size, Color(0, 0, 0, 0.55))
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shadow)

	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.size = sz
	lbl.horizontal_alignment = align
	lbl.z_index = z_index
	# Cap outline at 1 — anything thicker reads as doubled letters on pixel fonts.
	var safe_outline := mini(outline_sz, 1)
	if outline.a > 0.0 and safe_outline > 0:
		apply(lbl, size, color, outline, safe_outline)
	else:
		apply(lbl, size, color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	return lbl
