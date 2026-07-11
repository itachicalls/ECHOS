extends Control

@onready var starter_box: HBoxContainer = %StarterBox
@onready var rival_label: Label = %RivalLabel
@onready var back_button: Button = %BackButton

const STARTERS := ["emberkit", "tideling", "mossprite"]
const RIVAL_NAMES := ["Kai", "Mira", "Rowan"]


func _ready() -> void:
	rival_label.text = "Rival Trainer %s wants to battle!" % RIVAL_NAMES[randi() % RIVAL_NAMES.size()]
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/boot/boot.tscn"))
	_build_starter_buttons()


func _build_starter_buttons() -> void:
	for child in starter_box.get_children():
		child.queue_free()
	for id in STARTERS:
		var def := EchoCatalog.get_echo(id)
		if def == null:
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(140, 80)
		btn.text = "%s\n(%s)" % [def.name, EchoTypes.RESONANCE_NAMES[def.resonance]]
		btn.pressed.connect(func() -> void: _start_vs(id))
		starter_box.add_child(btn)


func _start_vs(player_starter: String) -> void:
	GameState.choose_starter(player_starter)
	var rival_pool := ["pebblit", "zephyette", "duskip", "mossprite"]
	var rival_id: String = rival_pool[randi() % rival_pool.size()]
	if rival_id == player_starter:
		rival_id = "pebblit"
	var rival := EchoCatalog.create_instance(rival_id, 6)
	SceneRouter.start_trainer_battle([rival], "boot", false)
