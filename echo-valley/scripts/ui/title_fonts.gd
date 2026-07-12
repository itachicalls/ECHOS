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


static func shadow_label(parent: Control, text: String, size: int, color: Color, pos: Vector2, sz: Vector2, align: int = HORIZONTAL_ALIGNMENT_CENTER, outline: Color = Color("1a1030"), outline_sz: int = 2) -> Label:
	var shadow := Label.new()
	shadow.text = text
	shadow.position = pos + Vector2(2, 2)
	shadow.size = sz
	shadow.horizontal_alignment = align
	apply(shadow, size, Color(0, 0, 0, 0.45))
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shadow)

	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.size = sz
	lbl.horizontal_alignment = align
	apply(lbl, size, color, outline, outline_sz)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	return lbl
