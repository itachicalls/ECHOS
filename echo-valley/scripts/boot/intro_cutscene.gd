extends Control

## Animated story cutscenes using real Kenney / in-game assets.

signal finished

const TitleFonts := preload("res://scripts/ui/title_fonts.gd")

const VIEW_W := 240
const VIEW_H := 160

var sequence_id: String = "opening"
var starter_id: String = ""

var _slides: Array = []
var _index := 0
var _anim_t := 0.0
var _caption: Label
var _fade: ColorRect
var _stage: Control
var _done := false
var _sequences: Dictionary = {}
var _advance_requested := false


func _ready() -> void:
	custom_minimum_size = Vector2(VIEW_W, VIEW_H)
	size = Vector2(VIEW_W, VIEW_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_unhandled_input(true)
	_load_data()
	_build_ui()
	_slides = _sequences.get(sequence_id, [])
	if _slides.is_empty():
		finished.emit()
		queue_free()
		return
	call_deferred("_run")


func _load_data() -> void:
	var f := FileAccess.open("res://data/intro_cutscenes.json", FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		_sequences = data


func _build_ui() -> void:
	var backdrop := preload("res://scripts/ui/title_backdrop.gd").new()
	backdrop.modulate = Color(0.72, 0.78, 0.92, 1.0)
	add_child(backdrop)

	_stage = preload("res://scripts/boot/intro_cutscene_stage.gd").new()
	add_child(_stage)

	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.04, 0.08, 1.0)
	_fade.size = Vector2(VIEW_W, VIEW_H)
	add_child(_fade)

	var box := Panel.new()
	box.position = Vector2(6, 108)
	box.size = Vector2(228, 46)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("0c1428", 0.92)
	sb.border_color = Color("5ad4c8", 0.55)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	box.add_theme_stylebox_override("panel", sb)
	add_child(box)

	_caption = Label.new()
	_caption.position = Vector2(10, 8)
	_caption.size = Vector2(208, 28)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	TitleFonts.apply(_caption, 6, Color("f0f8ff"), Color("1a2848"), 1)
	box.add_child(_caption)

	var prompt := Label.new()
	prompt.position = Vector2(10, 34)
	prompt.size = Vector2(208, 10)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	TitleFonts.apply(prompt, 5, Color("7ee8d8", 0.85))
	prompt.text = "> continue"
	box.add_child(prompt)

	var tap := Button.new()
	tap.position = Vector2.ZERO
	tap.size = Vector2(VIEW_W, VIEW_H)
	tap.focus_mode = Control.FOCUS_NONE
	tap.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	tap.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	tap.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	tap.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	tap.pressed.connect(_on_advance)
	add_child(tap)


func _process(delta: float) -> void:
	if _done:
		return
	_anim_t += delta
	if _stage and _stage.has_method("animate"):
		_stage.call("animate", _anim_t)


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
		_on_advance()


func _on_advance() -> void:
	if _done:
		return
	TouchUtil.register_tap()
	_advance_requested = true


func _run() -> void:
	_fade.color.a = 1.0
	var intro := create_tween()
	intro.tween_property(_fade, "color:a", 0.0, 0.8)
	await intro.finished

	while _index < _slides.size():
		_anim_t = 0.0
		var slide: Dictionary = _slides[_index]
		var visual := String(slide.get("visual", ""))
		if _stage and _stage.has_method("build"):
			_stage.call("build", visual, starter_id)
		var lines: Array = slide.get("lines", [])
		var per_line := float(slide.get("hold", 2.8)) / maxf(1.0, float(lines.size()))

		for line_i in lines.size():
			_caption.text = String(lines[line_i])
			_caption.modulate.a = 0.0
			var tw := create_tween()
			tw.tween_property(_caption, "modulate:a", 1.0, 0.3)
			_advance_requested = false
			var timer := get_tree().create_timer(per_line)
			while timer.time_left > 0.0:
				if _advance_requested:
					break
				await get_tree().process_frame

		var out := create_tween()
		out.tween_property(_fade, "color:a", 1.0, 0.45)
		await out.finished
		_index += 1
		if _index < _slides.size():
			var inn := create_tween()
			inn.tween_property(_fade, "color:a", 0.0, 0.55)
			await inn.finished

	_done = true
	var end := create_tween()
	end.tween_property(_fade, "color:a", 1.0, 0.55)
	await end.finished
	finished.emit()
	queue_free()
