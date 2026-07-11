extends Control

## Preloads Kenney assets and core data before the title screen.

const PRELOADS := [
	"res://assets/kenney/roguelike_sheet.png",
	"res://assets/kenney/tiny_dungeon_sheet.png",
	"res://assets/kenney/chars/nurse.png",
	"res://assets/kenney/items/echo_capsule.png",
	"res://data/echoes.json",
	"res://data/chimes.json",
	"res://data/encounters.json",
]

var _bar: ColorRect
var _fill: ColorRect
var _label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	await _run_load()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("0d1520")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color("1a2a44"), Color("0d1520")])
	var sky := TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 240
	gt.height = 160
	sky.texture = gt
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(sky)

	var logo := Label.new()
	logo.text = "ECHO VALLEY"
	logo.add_theme_font_size_override("font_size", 22)
	logo.add_theme_color_override("font_color", Color("ffe08a"))
	logo.add_theme_color_override("font_outline_color", Color("1a1028"))
	logo.add_theme_constant_override("outline_size", 4)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	logo.position.y = 48
	add_child(logo)

	var sub := Label.new()
	sub.text = "loading adventure..."
	sub.add_theme_font_size_override("font_size", 8)
	sub.add_theme_color_override("font_color", Color("a8dadc"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub.position.y = 76
	add_child(sub)

	_bar = ColorRect.new()
	_bar.color = Color("1d2b3a")
	_bar.position = Vector2(40, 108)
	_bar.size = Vector2(160, 10)
	add_child(_bar)

	_fill = ColorRect.new()
	_fill.color = Color("52b788")
	_fill.position = _bar.position + Vector2(1, 1)
	_fill.size = Vector2(0, 8)
	add_child(_fill)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 7)
	_label.add_theme_color_override("font_color", Color("cfe8ff"))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_label.position.y = 122
	add_child(_label)

	for i in 3:
		var spr := TextureRect.new()
		spr.texture = load("res://assets/kenney/chars/echo_ghost.png" if i == 1 else (
			"res://assets/kenney/chars/echo_crab.png" if i == 0 else "res://assets/kenney/chars/echo_bat.png"))
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		spr.size = Vector2(20, 20)
		spr.position = Vector2(88 + i * 22, 88)
		add_child(spr)
		var tw := create_tween().set_loops()
		tw.tween_property(spr, "position:y", 84.0, 0.5 + i * 0.1).set_trans(Tween.TRANS_SINE)
		tw.tween_property(spr, "position:y", 88.0, 0.5 + i * 0.1).set_trans(Tween.TRANS_SINE)


func _run_load() -> void:
	var total := PRELOADS.size()
	for i in total:
		var path: String = PRELOADS[i]
		_label.text = "Loading %s" % path.get_file()
		var pct := float(i + 1) / float(total)
		_fill.size.x = 158.0 * pct
		if ResourceLoader.exists(path):
			ResourceLoader.load_threaded_request(path)
			while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await get_tree().process_frame
			ResourceLoader.load_threaded_get(path)
		await get_tree().process_frame
	_label.text = "Ready!"
	await get_tree().create_timer(0.25).timeout
	get_tree().change_scene_to_file("res://scenes/boot/title.tscn")
