extends Node3D

const PlayerScene = preload("res://scenes/player/player.tscn")
const HudScene = preload("res://scenes/ui/world_hud.tscn")
const EchoVisualScene = preload("res://scenes/creatures/echo_visual.tscn")

@onready var world_root: Node3D = $World
@onready var spawn_point: Marker3D = $SpawnPoint

var _player: CharacterBody3D


func _ready() -> void:
	_build_village()
	_spawn_player()
	add_child(HudScene.instantiate())
	if not GameState.flags.get("intro_seen", false):
		GameState.set_flag("intro_seen", true)
		EventBus.toast.emit("Welcome to Hearthmere! Choose your partner Echo at the shrine.")


func _build_village() -> void:
	LowPolyKit.ground_plane(Vector2(70, 70), Color("74c69d"), world_root)
	LowPolyKit.ground_plane(Vector2(16, 16), Color("d8e2dc"), world_root)
	# Cobble ring
	for i in 16:
		var angle := i * TAU / 16.0
		LowPolyKit.path_tile(Vector3(cos(angle) * 7.5, 0, sin(angle) * 7.5), world_root, 1.0)

	# Main path south to forest
	for z in range(2, 24, 2):
		LowPolyKit.path_tile(Vector3(0, 0, z), world_root)

	# Cottages
	LowPolyKit.cottage(Vector3(-9, 0, -7), world_root, Color("f1faee"), Color("e76f51"))
	LowPolyKit.cottage(Vector3(9, 0, -6), world_root, Color("fefae0"), Color("2a9d8f"))
	LowPolyKit.cottage(Vector3(-8, 0, 9), world_root, Color("f1faee"), Color("457b9d"))
	LowPolyKit.cottage(Vector3(10, 0, 8), world_root, Color("fefae0"), Color("e9c46a"))

	# Town fence + trees
	LowPolyKit.fence_line(Vector3(-14, 0, -14), Vector3(14, 0, -14), world_root)
	LowPolyKit.fence_line(Vector3(-14, 0, 14), Vector3(14, 0, 14), world_root)
	for i in 10:
		var angle := i * TAU / 10.0
		var p := Vector3(cos(angle) * 22.0, 0, sin(angle) * 22.0)
		if i % 2 == 0:
			LowPolyKit.round_tree(p, world_root)
		else:
			LowPolyKit.pine_tree(p, world_root, randf_range(0.85, 1.15))

	for i in 30:
		var gx := randf_range(-30, 30)
		var gz := randf_range(-30, 30)
		if Vector2(gx, gz).length() < 9.0:
			continue
		LowPolyKit.grass_tuft(Vector3(gx, 0, gz), world_root)

	LowPolyKit.lamp_post(Vector3(-5, 0, 2), world_root)
	LowPolyKit.lamp_post(Vector3(5, 0, 2), world_root)
	LowPolyKit.sign_post(Vector3(-4, 0, -3), "Save Shrine", world_root)

	_add_save_shrine(Vector3(0, 0, -7))
	_add_starter_shrine(Vector3(0, 0, 3))
	_add_forest_gate(Vector3(0, 0, 22))


func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	add_child(_player)
	if GameState.current_zone == "hearthmere" and GameState.player_position.length() > 0.1:
		_player.global_position = GameState.player_position
	else:
		_player.global_position = spawn_point.global_position
	GameState.current_zone = "hearthmere"


func _add_save_shrine(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	world_root.add_child(root)
	LowPolyKit.cylinder(1.2, 1.2, 0.2, Color("fefae0"), Vector3(0, 0.1, 0), root, 8)
	LowPolyKit.cylinder(0.35, 0.2, 1.8, Color("e9c46a"), Vector3(0, 1.1, 0), root, 6)
	LowPolyKit.sphere(0.35, Color("ffd166"), Vector3(0, 2.15, 0), root, 8)
	var area := _make_interact_area(pos, "save_shrine", "Save Shrine — press E to heal & save")
	area.interacted.connect(_on_interact)


func _add_starter_shrine(pos: Vector3) -> void:
	LowPolyKit.starter_shrine(pos, world_root)
	var ids := ["emberkit", "tideling", "mossprite"]
	var names := ["Emberkit", "Tideling", "Mossprite"]
	for i in 3:
		var angle := deg_to_rad(i * 120.0)
		var offset := pos + Vector3(cos(angle) * 1.5, 0.9, sin(angle) * 1.5)
		var echo_vis: Node3D = EchoVisualScene.instantiate()
		world_root.add_child(echo_vis)
		echo_vis.global_position = offset
		echo_vis.scale = Vector3(1.4, 1.4, 1.4)
		if echo_vis.has_method("setup_from_definition"):
			echo_vis.setup_from_definition(EchoCatalog.get_echo(ids[i]))
		var area := _make_interact_area(offset, "starter_%s" % ids[i], "Press E — bond with %s" % names[i])
		area.interacted.connect(_on_interact)


func _add_forest_gate(pos: Vector3) -> void:
	LowPolyKit.forest_arch(pos, world_root)
	var area := _make_interact_area(pos, "gate_whisperwood", "Whisperwood Route — press E")
	area.interacted.connect(_on_interact)


func _make_interact_area(pos: Vector3, id: String, prompt: String) -> Area3D:
	var area := Area3D.new()
	area.set_script(load("res://scripts/exploration/interactable.gd"))
	area.interaction_id = id
	area.prompt = prompt
	area.collision_layer = 4
	area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.6
	shape.shape = sphere
	area.add_child(shape)
	area.position = pos
	world_root.add_child(area)
	return area


func _on_interact(id: String) -> void:
	match id:
		"save_shrine":
			GameState.heal_party()
			SaveService.save_game()
		"gate_whisperwood":
			if not GameState.has_starter():
				EventBus.toast.emit("Choose a partner Echo before leaving town!")
				return
			SceneRouter.go_to_zone("whisperwood", Vector3(0, 0.5, -20))
		_:
			if id.begins_with("starter_"):
				var def_id := id.trim_prefix("starter_")
				if GameState.has_starter():
					EventBus.toast.emit("You already have a partner.")
				else:
					GameState.choose_starter(def_id)
					SaveService.save_game()
