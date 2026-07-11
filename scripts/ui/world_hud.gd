extends CanvasLayer

@onready var toast_label: Label = %Toast
@onready var party_label: Label = %PartyInfo
@onready var help_label: Label = %Help

var _toast_tween: Tween


func _ready() -> void:
	EventBus.toast.connect(_show_toast)
	GameState.party_changed.connect(_refresh_party)
	_refresh_party()
	help_label.text = "WASD move · Q/R or RMB camera · E interact · Esc save"
	toast_label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		SaveService.save_game()


func _refresh_party() -> void:
	if GameState.party.is_empty():
		party_label.text = "No Echo bonded yet"
		return
	var parts: PackedStringArray = []
	for echo in GameState.party:
		parts.append("%s Lv%d (%d/%d)" % [echo.display_name(), echo.level, echo.current_hp, echo.max_hp()])
	party_label.text = " · ".join(parts)


func _show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.5)
	_toast_tween.tween_callback(func() -> void: toast_label.visible = false)
