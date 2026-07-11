extends Node

## Screenshot the Party and Box tabs to verify swap buttons + no bleed.

func _ready() -> void:
	GameState.party.clear()
	GameState.pc_box.clear()
	GameState.party.append(EchoCatalog.create_instance("emberkit", 5))
	GameState.party.append(EchoCatalog.create_instance("wispurr", 13))
	GameState.party.append(EchoCatalog.create_instance("pebblit", 12))
	GameState.pc_box.append(EchoCatalog.create_instance("emberkit", 8))
	GameState.pc_box.append(EchoCatalog.create_instance("wispurr", 9))
	GameState.current_map = "route1"
	GameState.player_cell = Vector2i(9, 12)
	var packed: PackedScene = load("res://scenes/world/route1.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	for i in 60:
		await get_tree().process_frame
	EventBus.menu_requested.emit("party")
	await get_tree().create_timer(0.2).timeout
	_snap("party")
	EventBus.menu_requested.emit("box")
	await get_tree().create_timer(0.2).timeout
	_snap("box")
	print("SHOTS DONE")
	get_tree().quit(0)


func _snap(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://shot_menu_%s.png" % name)
	print("SHOT ", ProjectSettings.globalize_path("user://shot_menu_%s.png" % name))
