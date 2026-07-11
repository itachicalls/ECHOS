extends Node

## Loads scenes and saves screenshots so we can eyeball the visuals.

var _shots := [
	{ "scene": "res://scenes/boot/title.tscn", "file": "user://shot_title.png", "map": "town", "cell": Vector2i(12, 16) },
	{ "scene": "res://scenes/boot/versus_setup.tscn", "file": "user://shot_versus.png", "map": "town", "cell": Vector2i(12, 16) },
	{ "scene": "res://scenes/world/town.tscn", "file": "user://shot_town.png", "map": "town", "cell": Vector2i(11, 15) },
	{ "scene": "res://scenes/world/route1.tscn", "file": "user://shot_route1.png", "map": "route1", "cell": Vector2i(9, 12) },
	{ "scene": "res://scenes/world/route2.tscn", "file": "user://shot_route2.png", "map": "route2", "cell": Vector2i(8, 15) },
	{ "scene": "res://scenes/world/desert1.tscn", "file": "user://shot_desert1.png", "map": "desert1", "cell": Vector2i(9, 12) },
	{ "scene": "res://scenes/world/desert3.tscn", "file": "user://shot_desert3.png", "map": "desert3", "cell": Vector2i(10, 10) },
	{ "scene": "res://scenes/world/jungle1.tscn", "file": "user://shot_jungle1.png", "map": "jungle1", "cell": Vector2i(10, 10) },
	{ "scene": "res://scenes/world/jungle3.tscn", "file": "user://shot_jungle3.png", "map": "jungle3", "cell": Vector2i(9, 12) },
	{ "scene": "res://scenes/battle/battle.tscn", "file": "user://shot_battle_trainer.png", "map": "battle", "cell": Vector2i(0, 0), "frames": 260 },
]


func _ready() -> void:
	GameState.party.clear()
	GameState.party.append(EchoCatalog.create_instance("emberkit", 8))
	GameState.party.append(EchoCatalog.create_instance("tideling", 7))
	SceneRouter._battle_request = {
		"kind": "trainer", "enemies": [EchoCatalog.create_instance("cindboth", 10), EchoCatalog.create_instance("nocturn", 11)],
		"trainer_name": "Rival Sabo", "return_map": "route2", "can_flee": false, "can_catch": false,
		"trainer_id": "r2_rival", "reward": 5, "win_line": "Not bad.",
	}
	await _run()


func _run() -> void:
	var vp := get_viewport()
	for s in _shots:
		GameState.current_map = String(s.map)
		GameState.player_cell = s.cell
		var packed: PackedScene = load(String(s.scene))
		var inst: Node = packed.instantiate()
		add_child(inst)
		var frames: int = int(s.get("frames", 40))
		for i in frames:
			await get_tree().process_frame
		var img := vp.get_texture().get_image()
		img.save_png(String(s.file))
		print("SHOT ", ProjectSettings.globalize_path(String(s.file)))
		inst.queue_free()
		await get_tree().process_frame
	print("SHOTS DONE")
	get_tree().quit(0)
