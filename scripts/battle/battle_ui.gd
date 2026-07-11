extends Control

signal action_chosen(action: Dictionary)
signal battle_finished

@onready var log_label: RichTextLabel = %BattleLog
@onready var player_name: Label = %PlayerName
@onready var player_hp: ProgressBar = %PlayerHP
@onready var player_hp_text: Label = %PlayerHPText
@onready var enemy_name: Label = %EnemyName
@onready var enemy_hp: ProgressBar = %EnemyHP
@onready var enemy_hp_text: Label = %EnemyHPText
@onready var chime_box: VBoxContainer = %ChimeButtons
@onready var switch_box: VBoxContainer = %SwitchButtons
@onready var action_panel: Control = %ActionPanel
@onready var flee_button: Button = %FleeButton

var _busy: bool = false


func _ready() -> void:
	flee_button.pressed.connect(func() -> void:
		if _busy:
			return
		action_chosen.emit({"type": EchoTypes.BattleActionType.FLEE})
	)


func set_busy(value: bool) -> void:
	_busy = value
	action_panel.visible = not value


func append_log(text: String) -> void:
	log_label.append_text(text + "\n")


func clear_log() -> void:
	log_label.clear()


func refresh_units(state: Dictionary) -> void:
	var player: Dictionary = state.player.units[state.player.active]
	var enemy: Dictionary = state.enemy.units[state.enemy.active]
	_set_unit_ui(player, player_name, player_hp, player_hp_text)
	_set_unit_ui(enemy, enemy_name, enemy_hp, enemy_hp_text)
	_rebuild_chimes(player)
	_rebuild_switches(state.player)


func _set_unit_ui(unit: Dictionary, name_label: Label, bar: ProgressBar, hp_label: Label) -> void:
	name_label.text = "%s  Lv.%d" % [unit.name, unit.level]
	bar.max_value = maxi(1, int(unit.max_hp))
	bar.value = int(unit.current_hp)
	hp_label.text = "%d / %d" % [unit.current_hp, unit.max_hp]


func _rebuild_chimes(unit: Dictionary) -> void:
	for child in chime_box.get_children():
		child.queue_free()
	for chime in unit.chimes:
		var button := Button.new()
		button.text = "%s  (%d)" % [chime.name, chime.power]
		button.tooltip_text = String(chime.get("description", ""))
		var chime_id := String(chime.id)
		button.pressed.connect(func() -> void:
			if _busy:
				return
			action_chosen.emit({
				"type": EchoTypes.BattleActionType.CHIME,
				"chime_id": chime_id,
			})
		)
		chime_box.add_child(button)


func _rebuild_switches(side: Dictionary) -> void:
	for child in switch_box.get_children():
		child.queue_free()
	for i in side.units.size():
		var unit: Dictionary = side.units[i]
		var button := Button.new()
		var fainted := int(unit.current_hp) <= 0
		button.text = "%s%s" % [unit.name, " (weary)" if fainted else ""]
		button.disabled = fainted or i == int(side.active)
		var index: int = i
		button.pressed.connect(func() -> void:
			if _busy:
				return
			action_chosen.emit({
				"type": EchoTypes.BattleActionType.SWITCH,
				"index": index,
			})
		)
		switch_box.add_child(button)
