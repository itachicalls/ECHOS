extends Control

## Cinematic story cutscenes: painted scenes + grounded hero sprites, framed
## with letterbox bars, a gentle camera drift, and subtitle text that fits.

signal finished

const TitleFonts := preload("res://scripts/ui/title_fonts.gd")

const VIEW_W := 240
const VIEW_H := 160
const BAR_TOP := 14
const BAR_BOTTOM := 38


var sequence_id: String = "opening"
var starter_id: String = ""

var _slides: Array = []
var _index := 0
var _anim_t := 0.0
var _caption: Label
var _prompt: Label
var _fade: ColorRect
var _bar_top: ColorRect
var _bar_bottom: ColorRect
var _camera: Control
var _stage: Control
var _backdrop: Control
var _done := false
var _sequences: Dictionary = {}
var _advance_requested := false
var _cam_tween: Tween
var _busy := false


func _ready() -> void:
	custom_minimum_size = Vector2(VIEW_W, VIEW_H)
	size = Vector2(VIEW_W, VIEW_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
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
	# Opaque underlay so the title screen never bleeds through.
	var under := ColorRect.new()
	under.color = Color("060810")
	under.size = Vector2(VIEW_W, VIEW_H)
	under.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(under)

	# Camera holds the movable scene layers (gentle drift only).
	_camera = Control.new()
	_camera.size = Vector2(VIEW_W, VIEW_H)
	_camera.pivot_offset = Vector2(VIEW_W * 0.5, VIEW_H * 0.5)
	_camera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camera.clip_contents = true
	add_child(_camera)

	var backdrop := preload("res://scripts/boot/intro_cutscene_backdrop.gd").new()
	_camera.add_child(backdrop)
	_backdrop = backdrop

	_stage = preload("res://scripts/boot/intro_cutscene_stage.gd").new()
	_camera.add_child(_stage)

	# Letterbox bars — fixed, never move with camera.
	_bar_top = ColorRect.new()
	_bar_top.color = Color(0, 0, 0, 1)
	_bar_top.position = Vector2.ZERO
	_bar_top.size = Vector2(VIEW_W, BAR_TOP)
	_bar_top.z_index = 5
	_bar_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar_top)

	_bar_bottom = ColorRect.new()
	_bar_bottom.color = Color(0, 0, 0, 1)
	_bar_bottom.position = Vector2(0, VIEW_H - BAR_BOTTOM)
	_bar_bottom.size = Vector2(VIEW_W, BAR_BOTTOM)
	_bar_bottom.z_index = 5
	_bar_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar_bottom)

	# Caption sits fully inside the bottom bar with padding for the tap prompt.
	_caption = Label.new()
	_caption.position = Vector2(8, VIEW_H - BAR_BOTTOM + 3)
	_caption.size = Vector2(VIEW_W - 16, BAR_BOTTOM - 14)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.clip_text = true
	_caption.max_lines_visible = 3
	_caption.z_index = 6
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TitleFonts.apply(_caption, 5, Color("f4f8ff"), Color("000000"), 1)
	add_child(_caption)

	_prompt = Label.new()
	_prompt.position = Vector2(VIEW_W - 60, VIEW_H - 11)
	_prompt.size = Vector2(52, 8)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt.z_index = 6
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TitleFonts.apply(_prompt, 5, Color("7ee8d8", 0.75))
	_prompt.text = "tap >"
	add_child(_prompt)

	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.03, 0.06, 1.0)
	_fade.size = Vector2(VIEW_W, VIEW_H)
	_fade.z_index = 9
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	# Full-screen tap target for mobile + desktop.
	var tap := Button.new()
	tap.position = Vector2.ZERO
	tap.size = Vector2(VIEW_W, VIEW_H)
	tap.focus_mode = Control.FOCUS_NONE
	tap.z_index = 10
	tap.mouse_filter = Control.MOUSE_FILTER_STOP
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
	if _done or _busy:
		return
	if event is InputEventScreenTouch and event.pressed:
		_on_advance()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
		_on_advance()
		get_viewport().set_input_as_handled()


func _on_advance() -> void:
	if _done or _busy:
		return
	TouchUtil.register_tap()
	_advance_requested = true


func _run() -> void:
	_busy = true
	# Bars slide in for a cinematic open.
	_bar_top.size.y = 0
	_bar_bottom.position.y = VIEW_H
	_bar_bottom.size.y = BAR_BOTTOM
	var bars := create_tween().set_parallel(true)
	bars.tween_property(_bar_top, "size:y", float(BAR_TOP), 0.45).set_trans(Tween.TRANS_CUBIC)
	bars.tween_property(_bar_bottom, "position:y", float(VIEW_H - BAR_BOTTOM), 0.45).set_trans(Tween.TRANS_CUBIC)

	_fade.color.a = 1.0
	# Build first slide while still black so nothing ghosts through.
	_show_slide(_slides[0])
	await get_tree().process_frame

	var intro := create_tween()
	intro.tween_property(_fade, "color:a", 0.0, 0.7)
	await intro.finished
	_busy = false

	while _index < _slides.size():
		var slide: Dictionary = _slides[_index]
		var lines: Array = slide.get("lines", [])
		var hold := float(slide.get("hold", 3.0))
		_start_camera_move(_index, hold)

		var per_line := hold / maxf(1.0, float(lines.size()))
		for line_i in lines.size():
			_set_caption(String(lines[line_i]))
			_advance_requested = false
			var timer := get_tree().create_timer(per_line)
			while timer.time_left > 0.0:
				if _advance_requested:
					break
				await get_tree().process_frame

		_busy = true
		var out := create_tween()
		out.tween_property(_fade, "color:a", 1.0, 0.35)
		await out.finished

		_index += 1
		if _index < _slides.size():
			# Swap scene WHILE black — never fade into the previous slide.
			_show_slide(_slides[_index])
			await get_tree().process_frame
			var inn := create_tween()
			inn.tween_property(_fade, "color:a", 0.0, 0.45)
			await inn.finished
			_busy = false
		else:
			break

	_done = true
	_busy = true
	var end := create_tween().set_parallel(true)
	end.tween_property(_fade, "color:a", 1.0, 0.5)
	end.tween_property(_bar_top, "size:y", float(VIEW_H * 0.5), 0.5)
	end.tween_property(_bar_bottom, "position:y", float(VIEW_H * 0.5), 0.5)
	await end.finished
	finished.emit()
	queue_free()


func _show_slide(slide: Dictionary) -> void:
	_anim_t = 0.0
	_caption.modulate.a = 0.0
	var visual := String(slide.get("visual", ""))
	if _stage and _stage.has_method("build"):
		_stage.call("build", visual, starter_id)
	if _backdrop and _backdrop.has_method("set_visual"):
		_backdrop.call("set_visual", visual)
	_reset_camera()


func _set_caption(text: String) -> void:
	_caption.text = text
	_caption.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", 1.0, 0.28)


func _reset_camera() -> void:
	if _cam_tween and _cam_tween.is_valid():
		_cam_tween.kill()
	_camera.scale = Vector2.ONE
	_camera.position = Vector2.ZERO


func _start_camera_move(index: int, duration: float) -> void:
	if _cam_tween and _cam_tween.is_valid():
		_cam_tween.kill()
	# Very gentle drift — barely noticeable, no shake feel.
	var dirs := [Vector2(-1.5, 0.5), Vector2(1.5, -0.5), Vector2(-1.0, -0.8), Vector2(1.0, 0.8)]
	var pan: Vector2 = dirs[index % dirs.size()]
	_camera.scale = Vector2(1.0, 1.0)
	_camera.position = Vector2.ZERO
	_cam_tween = create_tween().set_parallel(true)
	_cam_tween.tween_property(_camera, "scale", Vector2(1.03, 1.03), duration + 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_property(_camera, "position", pan, duration + 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
