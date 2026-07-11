extends Node

## Shared mobile / touch helpers used across HUD, battle, and on-screen controls.

var _tap_pending: bool = false
var _tap_cooldown: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if _tap_cooldown > 0.0:
		_tap_cooldown -= delta


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


## True when we should show touch UI (D-pad, tap hints, larger hit targets).
static func is_touch_ui_enabled() -> bool:
	if OS.has_environment("EV_FORCE_TOUCH"):
		return true
	if OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("mobile"):
		return true
	if DisplayServer.is_touchscreen_available():
		return true
	# Godot web on phones often reports only the "web" feature.
	if OS.has_feature("web"):
		var sz := DisplayServer.screen_get_size()
		# Portrait or narrow screens are almost always phones/tablets in browser.
		if sz.y >= sz.x or sz.x <= 820:
			return true
	return false


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
