extends Control

## Post-Primordius ending: victory flourish, fate choice, credits, return to town.

signal finished

const FATE_LINES := {
	"chorus": [
		"You open the valley to The Chorus once more.",
		"Harmons hum in unison — old scars along the Fracture begin to close.",
		"The Archive will remember this day as the Second Harmonization.",
	],
	"fracture": [
		"You leave the Fracture standing — wild, unfinished, free.",
		"Regions keep their strange edges. New Harmons will still wash ashore.",
		"The Rangers nod. Power unchecked is no longer the only fear.",
	],
	"balance": [
		"You braid Chorus and Fracture into a living compromise.",
		"Sigils glow soft. The Primordial sleeps — neither sealed nor unleashed.",
		"The valley invents a third truth, and writes your name beside it.",
	],
}

const CREDITS := [
	"HARMONA VALLEY",
	"A keeper's journey through resonance and ruin",
	"",
	"You chose a starter in Harmona Rest",
	"You earned Sigils across desert, grove, storm, and dream",
	"You faced Sabo, the Rangers, The Veil, and the Archive",
	"You woke PRIMORDIUS beneath the Hollow Barrows",
	"",
	"Thanks for playing",
	"The valley remembers.",
]

var _root: Control
var _title: Label
var _body: Label
var _btn_row: HBoxContainer
var _continue_btn: Button
var _phase: String = "victory"
var _credit_i: int = 0
var _fate: String = ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_show_victory()


func _build() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color("0b1220")
	add_child(dim)

	# soft aurora wash
	var glow := ColorRect.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.color = Color("2a1a4a", 0.55)
	add_child(glow)

	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 14)
	_title.add_theme_color_override("font_color", Color("ffe08a"))
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 4)
	_title.position = Vector2(8, 18)
	_title.size = Vector2(224, 22)
	_root.add_child(_title)

	_body = Label.new()
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 8)
	_body.add_theme_color_override("font_color", Color("e8f0ff"))
	_body.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_body.add_theme_constant_override("outline_size", 2)
	_body.position = Vector2(16, 48)
	_body.size = Vector2(208, 70)
	_root.add_child(_body)

	_btn_row = HBoxContainer.new()
	_btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_btn_row.add_theme_constant_override("separation", 4)
	_btn_row.position = Vector2(8, 122)
	_btn_row.size = Vector2(224, 28)
	_root.add_child(_btn_row)

	_continue_btn = _mk_btn("Continue", _on_continue)
	_continue_btn.position = Vector2(70, 128)
	_continue_btn.size = Vector2(100, 20)
	_root.add_child(_continue_btn)


func _mk_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(72, 18)
	b.add_theme_font_size_override("font_size", 7)
	b.pressed.connect(cb)
	return b


func _clear_btns() -> void:
	for c in _btn_row.get_children():
		c.queue_free()
	_continue_btn.visible = false


func _show_victory() -> void:
	_phase = "victory"
	_title.text = "PRIMORDIUS FALLS SILENT"
	_body.text = "The barrow-mound stills. Light folds back into the Fracture-scar.\nThe valley waits for your judgment."
	_clear_btns()
	_continue_btn.visible = true
	_continue_btn.text = "Decide the valley's fate"
	# brief flash
	modulate = Color(2.2, 2.0, 1.4)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.8)


func _show_fate() -> void:
	_phase = "fate"
	_title.text = "CHOOSE THE VALLEY'S FATE"
	_body.text = "Restore The Chorus, preserve The Fracture, or forge a new balance."
	_clear_btns()
	_btn_row.add_child(_mk_btn("Chorus", _pick_fate.bind("chorus")))
	_btn_row.add_child(_mk_btn("Fracture", _pick_fate.bind("fracture")))
	_btn_row.add_child(_mk_btn("Balance", _pick_fate.bind("balance")))


func _pick_fate(fate: String) -> void:
	_fate = fate
	GameState.flags["fate_choice"] = fate
	GameState.flags["story_complete"] = true
	StoryService.notify_progress()
	SaveService.save_game(true)
	_show_fate_result()


func _show_fate_result() -> void:
	_phase = "fate_result"
	var lines: Array = FATE_LINES.get(_fate, FATE_LINES["balance"])
	_title.text = "FATE SEALED"
	_body.text = "\n".join(PackedStringArray(lines))
	_clear_btns()
	_continue_btn.visible = true
	_continue_btn.text = "Credits"


func _show_credits() -> void:
	_phase = "credits"
	_credit_i = 0
	_clear_btns()
	_continue_btn.visible = true
	_continue_btn.text = "Next"
	_advance_credit()


func _advance_credit() -> void:
	if _credit_i >= CREDITS.size():
		_show_return()
		return
	_title.text = "CREDITS"
	_body.text = String(CREDITS[_credit_i])
	_credit_i += 1
	if _credit_i >= CREDITS.size():
		_continue_btn.text = "Finish"


func _show_return() -> void:
	_phase = "return"
	_title.text = "JOURNEY COMPLETE"
	_body.text = "Your team rests in Harmona Rest.\nPress M anytime — the journal remembers what you chose."
	_clear_btns()
	_continue_btn.visible = true
	_continue_btn.text = "Return to Harmona Rest"


func _on_continue() -> void:
	match _phase:
		"victory":
			_show_fate()
		"fate_result":
			_show_credits()
		"credits":
			_advance_credit()
		"return":
			GameState.heal_party()
			GameState.current_map = "town"
			GameState.player_cell = Vector2i(17, 7)
			GameState.player_facing = "up"
			SaveService.save_game(true)
			SceneRouter.go_to_map("town", Vector2i(17, 7), "up")
		_:
			pass
