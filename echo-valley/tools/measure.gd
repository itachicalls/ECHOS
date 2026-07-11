extends SceneTree

func _init() -> void:
	for fs in [5, 6, 7, 8]:
		var l := Label.new()
		l.text = "Lv50"
		l.add_theme_font_size_override("font_size", fs)
		l.clip_text = true
		var b := Button.new()
		b.text = "Lv50"
		b.add_theme_font_size_override("font_size", fs)
		var sb := StyleBoxFlat.new()
		sb.set_content_margin_all(0)
		b.add_theme_stylebox_override("normal", sb)
		var root := Window.new()
		# realize sizes
		print("font %d  label_min=%s  button_min=%s" % [fs, str(l.get_combined_minimum_size()), str(b.get_combined_minimum_size())])
	quit(0)
