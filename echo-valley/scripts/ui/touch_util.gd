extends Node

## Shared mobile / touch helpers used across HUD, battle, and on-screen controls.

const GAME_W := 240.0
const GAME_H := 160.0

var _tap_pending: bool = false
var _tap_cooldown: float = 0.0
var _cached_margins: Vector4 = Vector4.ZERO
var _margin_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if _tap_cooldown > 0.0:
		_tap_cooldown -= delta
	_margin_timer -= delta
	if _margin_timer <= 0.0:
		_margin_timer = 0.35
		_cached_margins = _compute_game_margins()


func _unhandled_input(event: InputEvent) -> void:
	if not _can_consume_tap():
		return
	if event is InputEventScreenTouch and event.pressed:
		_queue_tap()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_queue_tap()


func _can_consume_tap() -> bool:
	return EventBus.dialogue_active or EventBus.awaiting_continue


func register_tap() -> void:
	if _can_consume_tap():
		_queue_tap()


func _queue_tap() -> void:
	_tap_pending = true
	EventBus.tap_continue.emit()


## True when we should show on-screen mobile controls (D-pad, A button).
## Desktop web always returns false — keyboard/mouse only.
static func is_touch_ui_enabled() -> bool:
	if OS.has_environment("EV_FORCE_TOUCH"):
		return true
	if OS.has_feature("android") or OS.has_feature("ios"):
		return true
	if OS.has_feature("mobile") and not OS.has_feature("web"):
		return true
	if OS.has_feature("web"):
		return _is_mobile_web_viewport()
	return false


## Web export: only phones/tablets in a touch viewport — not laptop browsers.
static func _is_mobile_web_viewport() -> bool:
	if not DisplayServer.is_touchscreen_available():
		return false
	var sz: Vector2 = DisplayServer.screen_get_size()
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	if loop:
		var vp: Viewport = loop.root.get_viewport()
		if vp:
			sz = vp.get_visible_rect().size
	if sz.x < 1.0 or sz.y < 1.0:
		return false
	var short_side := minf(sz.x, sz.y)
	var long_side := maxf(sz.x, sz.y)
	# Phone-sized canvas only (rejects typical desktop browser windows).
	return short_side <= 520.0 and long_side >= short_side * 1.25


## Safe-area padding in game pixels: left, top, right, bottom.
func get_game_margins() -> Vector4:
	return _cached_margins


func _compute_game_margins() -> Vector4:
	if not is_touch_ui_enabled():
		return Vector4.ZERO
	# Fixed padding — avoids web safe-area API quirks.
	return Vector4(4, 2, 4, 8)


## Slightly larger UI on touch (buttons, fonts).
static func ui_scale() -> float:
	return 1.28 if is_touch_ui_enabled() else 1.0


## Consume one queued screen tap (call once per frame from dialogue / battle waits).
func consume_tap() -> bool:
	if _tap_cooldown > 0.0:
		return false
	if not _tap_pending:
		return false
	_tap_pending = false
	_tap_cooldown = 0.22
	return true


func wants_continue() -> bool:
	return Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("cancel") or consume_tap()
