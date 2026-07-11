extends Control

@onready var continue_button: Button = %ContinueButton
@onready var solo_button: Button = %SoloButton
@onready var coop_button: Button = %CoopButton
@onready var vs_button: Button = %VsButton
@onready var preview_viewport: SubViewport = %PreviewViewport
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	continue_button.disabled = not SaveService.has_save()
	continue_button.pressed.connect(_on_continue)
	solo_button.pressed.connect(_on_solo)
	coop_button.pressed.connect(_on_coop)
	vs_button.pressed.connect(_on_vs)
	_setup_preview()


func _setup_preview() -> void:
	var world := Node3D.new()
	preview_viewport.add_child(world)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.8, 4.2)
	cam.rotation_degrees = Vector3(-12, 180, 0)
	world.add_child(cam)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 30, 0)
	world.add_child(light)
	LowPolyKit.ground_plane(Vector2(8, 8), Color("74c69d"), world)
	var trainer := Node3D.new()
	trainer.set_script(load("res://scripts/player/trainer_visual.gd"))
	trainer.position = Vector3(-0.8, 0, 0)
	world.add_child(trainer)
	for i in 3:
		var ids := ["emberkit", "tideling", "mossprite"]
		var echo_vis: Node3D = load("res://scenes/creatures/echo_visual.tscn").instantiate()
		echo_vis.position = Vector3(0.8 + i * 0.9, 0, -0.3)
		world.add_child(echo_vis)
		if echo_vis.has_method("setup_from_definition"):
			echo_vis.setup_from_definition(EchoCatalog.get_echo(ids[i]))


func _on_continue() -> void:
	if SaveService.load_game():
		_go_solo()


func _on_solo() -> void:
	_reset_new_game()
	GameState.play_mode = "solo"
	_go_solo()


func _on_coop() -> void:
	status_label.text = "Co-op Adventure — explore together, trade Echoes, and battle side by side. Coming soon!"


func _on_vs() -> void:
	_reset_new_game()
	GameState.play_mode = "versus"
	SceneRouter.go_to_zone("versus_setup")


func _go_solo() -> void:
	SceneRouter.go_to_zone("hearthmere", Vector3(0, 0.5, 6))


func _reset_new_game() -> void:
	SaveService.delete_save()
	GameState.from_dict({
		"player_name": "Traveler",
		"party": [],
		"inventory": {"resonance_charm": 5, "heart_salve": 3},
		"flags": {"starter_chosen": false, "intro_seen": false},
		"current_zone": "hearthmere",
		"player_position": {"x": 0, "y": 0.5, "z": 6},
		"player_yaw": 0,
		"encounter_steps": 0,
		"play_mode": "solo",
	})
