extends Control
## Soft atmospheric backdrop for versus draft / lobby screens.

const VIEW_W := 240
const VIEW_H := 160

var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(VIEW_W, VIEW_H)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for y in VIEW_H:
		var t := float(y) / float(VIEW_H - 1)
		var top := Color("0a1024")
		var bot := Color("121a32")
		draw_rect(Rect2(0, y, VIEW_W, 1), top.lerp(bot, t))

	# Soft vignette corners.
	draw_rect(Rect2(0, 0, VIEW_W, 18), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(0, VIEW_H - 24, VIEW_W, 24), Color(0, 0, 0, 0.22))

	# Slow drifting motes.
	var rng := 4242
	for i in 18:
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var x := float(rng % VIEW_W)
		rng = (rng * 1103515245 + 12345) & 0x7fffffff
		var phase := float(rng % 100) / 100.0
		var y := fmod(_t * (4.0 + phase * 5.0) + phase * VIEW_H, float(VIEW_H))
		var a := 0.12 + 0.1 * sin(_t * 1.5 + i)
		draw_rect(Rect2(x, VIEW_H - y, 1, 1), Color("8ab8e8", a))
