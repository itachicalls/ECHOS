extends Node

## Screenshots of the new gym gates + Crag Cavern maps.

var _shots := [
	{ "scene": "res://scenes/world/route2.tscn", "file": "user://shot_gym_grass.png", "map": "route2", "cell": Vector2i(3, 5) },
	{ "scene": "res://scenes/world/desert3.tscn", "file": "user://shot_gym_desert.png", "map": "desert3", "cell": Vector2i(19, 8) },
	{ "scene": "res://scenes/world/jungle3.tscn", "file": "user://shot_gym_jungle.png", "map": "jungle3", "cell": Vector2i(9, 5) },
	{ "scene": "res://scenes/world/cave1.tscn", "file": "user://shot_cave1.png", "map": "cave1", "cell": Vector2i(9, 18) },
	{ "scene": "res://scenes/world/cave2.tscn", "file": "user://shot_cave2.png", "map": "cave2", "cell": Vector2i(9, 8) },
]


func _ready() -> void:
	GameState.party.clear()
	GameState.party.append(EchoCatalog.create_instance("emberkit", 12))
	await _run()


func _run() -> void:
	var vp := get_viewport()
	for s in _shots:
		GameState.current_map = String(s.map)
		GameState.player_cell = s.cell
		var packed: PackedScene = load(String(s.scene))
		var inst: Node = packed.instantiate()
		add_child(inst)
		for i in 40:
			await get_tree().process_frame
		var img := vp.get_texture().get_image()
		img.save_png(String(s.file))
		print("SHOT ", ProjectSettings.globalize_path(String(s.file)))
		inst.queue_free()
		await get_tree().process_frame
	print("SHOTS DONE")
	get_tree().quit(0)
