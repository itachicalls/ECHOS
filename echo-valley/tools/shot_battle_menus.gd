extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var db := EchoDatabase.new()
	db.load_from_res()
	EchoDatabase.instance = db
	var party: Array = []
	party.append(db.create_instance("emberkit", 12))
	SceneRouter._battle_request = {
		"kind": "wild",
		"player_override": party,
		"enemies": [db.create_instance("mossling", 9)],
		"return_map": "route1", "can_flee": true, "can_catch": true,
	}
	var packed: PackedScene = load("res://scenes/battle/battle.tscn")
	var inst = packed.instantiate()
	root.add_child(inst)
	for i in 30:
		await process_frame
	inst.phase = inst.Phase.CHOOSING
	inst.menu_root.visible = true
	inst._open_main_menu()
	for i in 8:
		await process_frame
	_save("shot_battle_main.png")
	inst._on_fight()
	for i in 8:
		await process_frame
	_save("shot_battle_fight.png")
	print("SHOTS DONE")
	quit(0)


func _save(name: String) -> void:
	var img := root.get_texture().get_image()
	var out := ProjectSettings.globalize_path("user://%s" % name)
	img.save_png(out)
	print("SHOT ", out)
