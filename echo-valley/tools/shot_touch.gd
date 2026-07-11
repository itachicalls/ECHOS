extends Node

## Screenshot an overworld map with touch controls forced on.

func _ready() -> void:
	GameState.party.clear()
	GameState.party.append(EchoCatalog.create_instance("emberkit", 8))
	GameState.current_map = "route1"
	GameState.player_cell = Vector2i(9, 12)
	var packed: PackedScene = load("res://scenes/world/route1.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	for i in 60:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://shot_touch.png")
	print("SHOT ", ProjectSettings.globalize_path("user://shot_touch.png"))
	print("SHOTS DONE")
	get_tree().quit(0)
