extends Node

## Capture frames of the evolution cutscene.

func _ready() -> void:
	GameState.party.clear()
	GameState.party.append(EchoCatalog.create_instance("emberkit", 12))
	SceneRouter._battle_request = {
		"kind": "wild", "enemies": [EchoCatalog.create_instance("mossling", 9)],
		"return_map": "route1", "can_flee": true, "can_catch": true,
	}
	var packed: PackedScene = load("res://scenes/battle/battle.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	for i in 40:
		await get_tree().process_frame
	# Fire the cutscene without awaiting so we can grab mid-animation frames.
	inst._play_evolution("emberkit", "wispurr", "Emberkit", "Wispurr")
	await get_tree().create_timer(1.6).timeout
	_snap("flicker")
	await get_tree().create_timer(1.2).timeout
	_snap("reveal")
	print("SHOTS DONE")
	get_tree().quit(0)


func _snap(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://shot_evo_%s.png" % name)
	print("SHOT ", ProjectSettings.globalize_path("user://shot_evo_%s.png" % name))
