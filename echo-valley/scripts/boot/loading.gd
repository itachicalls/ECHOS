extends Control

## Preloads Kenney assets and core data before the title screen.

const TitleFonts := preload("res://scripts/ui/title_fonts.gd")

const VIEW_W := 240
const VIEW_H := 160

const PRELOADS := [
	"res://assets/kenney/roguelike_sheet.png",
	"res://assets/kenney/tiny_dungeon_sheet.png",
	"res://assets/kenney/chars/nurse.png",
	"res://assets/kenney/items/echo_capsule.png",
	"res://data/echoes.json",
	"res://data/chimes.json",
	"res://data/encounters.json",
	"res://data/intro_cutscenes.json",
]

var _fill: ColorRect
var _label: Label
var _pct_label: Label
var hold_on_complete := false


func _ready() -> void:
	custom_minimum_size = Vector2(VIEW_W, VIEW_H)
	size = Vector2(VIEW_W, VIEW_H)
	_build_ui()
	await _run_load()


func _build_ui() -> void:
	var backdrop := preload("res://scripts/ui/title_backdrop.gd").new()
	add_child(backdrop)

	# Dim overlay so loading UI reads clearly over the scenery.
	var veil := ColorRect.new()
	veil.color = Color("060c18", 0.28)
	veil.position = Vector2.ZERO
	veil.size = Vector2(VIEW_W, VIEW_H)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	TitleFonts.shadow_label(
		self, GameStrings.TITLE, 8, Color("fff0b0"),
		Vector2(4, 42), Vector2(VIEW_W - 8, 16),
		HORIZONTAL_ALIGNMENT_CENTER, Color(), 0
	)

	TitleFonts.shadow_label(
		self, "awakening the valley...", 5, Color("d8f0ff"),
		Vector2(0, 62), Vector2(VIEW_W, 12),
		HORIZONTAL_ALIGNMENT_CENTER, Color(), 0
	)

	const STARTER_PX := 22
	const STARTER_IDS := ["emberkit", "tideling", "mossling"]
	for i in STARTER_IDS.size():
		var tr := TextureRect.new()
		var def := EchoCatalog.get_echo(STARTER_IDS[i])
		tr.texture = load(def.sprite_path)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size = Vector2(STARTER_PX, STARTER_PX)
		var base_y := 68.0
		tr.position = Vector2(84 + i * 24, base_y)
		add_child(tr)
		var tw := create_tween().set_loops()
		var dur := 0.5 + i * 0.12
		tw.tween_property(tr, "position:y", base_y - 3.0, dur).set_trans(Tween.TRANS_SINE)
		tw.tween_property(tr, "position:y", base_y, dur).set_trans(Tween.TRANS_SINE)

	var bar_panel := Panel.new()
	bar_panel.position = Vector2(32, 108)
	bar_panel.size = Vector2(176, 14)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color("0c1828", 0.9)
	bar_bg.border_color = Color("5ad4c8", 0.5)
	bar_bg.set_border_width_all(2)
	bar_bg.set_corner_radius_all(4)
	bar_panel.add_theme_stylebox_override("panel", bar_bg)
	add_child(bar_panel)

	_fill = ColorRect.new()
	_fill.color = Color("5ad4c8")
	_fill.position = Vector2(34, 110)
	_fill.size = Vector2(0, 10)
	add_child(_fill)

	var fill_glow := ColorRect.new()
	fill_glow.color = Color("fff0b0", 0.35)
	fill_glow.position = Vector2(34, 110)
	fill_glow.size = Vector2(0, 3)
	fill_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill_glow.name = "FillGlow"
	add_child(fill_glow)

	_label = Label.new()
	_label.position = Vector2(0, 124)
	_label.size = Vector2(VIEW_W, 10)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	TitleFonts.apply(_label, 5, Color("b8dce8"))
	add_child(_label)

	_pct_label = Label.new()
	_pct_label.position = Vector2(0, 134)
	_pct_label.size = Vector2(VIEW_W, 10)
	_pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	TitleFonts.apply(_pct_label, 5, Color("7ee8d8", 0.85))
	add_child(_pct_label)


func _run_load() -> void:
	var glow := get_node_or_null("FillGlow") as ColorRect
	var total := PRELOADS.size()
	for i in total:
		var path: String = PRELOADS[i]
		_label.text = path.get_file()
		var pct := float(i + 1) / float(total)
		var w := 172.0 * pct
		_fill.size.x = w
		if glow:
			glow.size.x = w
		_pct_label.text = "%d%%" % int(round(pct * 100.0))
		if ResourceLoader.exists(path):
			ResourceLoader.load_threaded_request(path)
			while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await get_tree().process_frame
			ResourceLoader.load_threaded_get(path)
		await get_tree().process_frame
	_label.text = "ready!"
	_pct_label.text = "100%"
	await get_tree().create_timer(0.35).timeout
	if not hold_on_complete:
		get_tree().change_scene_to_file("res://scenes/boot/title.tscn")
