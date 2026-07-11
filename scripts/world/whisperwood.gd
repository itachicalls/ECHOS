extends Node3D

const PlayerScene = preload("res://scenes/player/player.tscn")
const HudScene = preload("res://scenes/ui/world_hud.tscn")

@onready var world_root: Node3D = $World
@onready var spawn_point: Marker3D = $SpawnPoint

var _player: CharacterBody3D


func _ready() -> void:
	_build_forest()
	_spawn_player()
	add_child(HudScene.instantiate())
	EventBus.toast.emit("Tall grass ahead — wild Echoes may appear!")


func _build_forest() -> void:
	LowPolyKit.ground_plane(Vector2(80, 100), Color("52b788"), world_root)
	LowPolyKit.ground_plane(Vector2(8, 90), Color("b08968"), world_root)

	for z in range(-38, 40, 2):
		LowPolyKit.path_tile(Vector3(0, 0.01, z), world_root, 1.1)

	for i in 45:
		var x := randf_range(-34, 34)
		var z := randf_range(-40, 38)
		if absf(x) < 5.0:
			continue
		if i % 3 == 0:
			LowPolyKit.pine_tree(Vector3(x, 0, z), world_root, randf_range(0.9, 1.3))
		else:
			LowPolyKit.round_tree(Vector3(x, 0, z), world_root)

	for i in 20:
		LowPolyKit.rock(Vector3(randf_range(-30, 30), 0, randf_range(-30, 30)), world_root, randf_range(0.6, 1.2))

	_add_town_gate(Vector3(0, 0, -26))
	_add_encounter_field(Vector3(0, 0, 10), Vector3(24, 2, 32))


func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	add_child(_player)
	if GameState.current_zone == "whisperwood" and GameState.player_position.length() > 0.1:
		_player.global_position = GameState.player_position
	else:
		_player.global_position = spawn_point.global_position
	GameState.current_zone = "whisperwood"


func _add_town_gate(pos: Vector3) -> void:
	LowPolyKit.forest_arch(pos, world_root)
	var area := Area3D.new()
	area.set_script(load("res://scripts/exploration/interactable.gd"))
	area.interaction_id = "gate_hearthmere"
	area.prompt = "Return to Hearthmere — press E"
	area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(5, 3, 3)
	shape.shape = box
	area.add_child(shape)
	area.position = pos
	area.interacted.connect(_on_interact)
	world_root.add_child(area)


func _add_encounter_field(pos: Vector3, size: Vector3) -> void:
	# Pokemon-style tall grass patch
	for i in 120:
		var offset := Vector3(
			randf_range(-size.x * 0.45, size.x * 0.45),
			0,
			randf_range(-size.z * 0.45, size.z * 0.45)
		)
		LowPolyKit.grass_tuft(pos + offset, world_root, true)

	# Darker ground under grass
	LowPolyKit.box(Vector3(size.x, 0.05, size.z), Color("40916c"), pos + Vector3(0, 0.02, 0), world_root)

	var field := Area3D.new()
	field.set_script(load("res://scripts/exploration/encounter_field.gd"))
	field.table_id = "whisperwood_grass"
	field.collision_layer = 8
	field.collision_mask = 2
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	field.add_child(shape)
	field.position = pos + Vector3(0, size.y * 0.5, 0)
	world_root.add_child(field)
	call_deferred("_bind_encounter", field)


func _bind_encounter(field: Area3D) -> void:
	if field.has_method("bind_player") and _player:
		field.bind_player(_player)


func _on_interact(id: String) -> void:
	if id == "gate_hearthmere":
		SceneRouter.go_to_zone("hearthmere", Vector3(0, 0.5, 18))
