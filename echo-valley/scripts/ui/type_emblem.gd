class_name TypeEmblem
extends RefCounted

## Small resonance gem badge — used in battle HUD and versus draft.


static func create(resonance: int, size: int = 14) -> Control:
	var res := resonance as EchoTypes.Resonance
	var col: Color = EchoTypes.RESONANCE_COLORS.get(res, Color("cbd5e1"))
	var sym: String = EchoTypes.RESONANCE_SYMBOLS.get(res, "•")
	var dark: Color = col.darkened(0.55)

	var root := Control.new()
	root.custom_minimum_size = Vector2(size, size)
	root.size = Vector2(size, size)

	var glow := Panel.new()
	glow.position = Vector2(-1, -1)
	glow.size = Vector2(size + 2, size + 2)
	var gsb := StyleBoxFlat.new()
	gsb.bg_color = Color(col.r, col.g, col.b, 0.28)
	gsb.set_corner_radius_all(4)
	gsb.set_border_width_all(0)
	root.add_child(glow)

	var gem := Panel.new()
	gem.position = Vector2.ZERO
	gem.size = Vector2(size, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = col.lightened(0.35)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(dark.r, dark.g, dark.b, 0.45)
	sb.shadow_size = 1
	gem.add_theme_stylebox_override("panel", sb)
	root.add_child(gem)

	var shine := ColorRect.new()
	shine.color = Color(1, 1, 1, 0.22)
	shine.position = Vector2(2, 1)
	shine.size = Vector2(size - 4, maxf(2.0, size * 0.28))
	root.add_child(shine)

	var lbl := Label.new()
	lbl.text = sym
	lbl.position = Vector2.ZERO
	lbl.size = Vector2(size, size)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 7 if size >= 14 else 6)
	lbl.add_theme_color_override("font_color", Color("0a0e14"))
	lbl.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.35))
	lbl.add_theme_constant_override("outline_size", 1)
	root.add_child(lbl)

	return root
