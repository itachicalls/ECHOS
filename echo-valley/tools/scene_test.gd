extends SceneTree

## Instantiates each scene into a live tree to catch _ready runtime errors.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame

	# ensure DB + a party exist
	if EchoDatabase.instance == null:
		var db := EchoDatabase.new()
		db.load_from_res()
		EchoDatabase.instance = db
	GameState.party.clear()
	GameState.party.append(EchoCatalog.create_instance("emberkit", 6))
	GameState.party.append(EchoCatalog.create_instance("tideling", 5))

	for path in ["res://scenes/boot/title.tscn", "res://scenes/world/town.tscn", "res://scenes/world/route1.tscn"]:
		await _try_scene(path)

	# battle needs a request set on the SceneRouter autoload
	var router: Node = root.get_node("SceneRouter")
	var enemy := EchoCatalog.create_instance("pebblit", 4)
	router._battle_request = { "kind": "wild", "enemies": [enemy], "return_map": "route1", "can_flee": true, "can_catch": true }
	await _try_scene("res://scenes/battle/battle.tscn")

	print("SCENE TEST DONE")
	quit(0)


func _try_scene(path: String) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		print("FAIL load ", path)
		return
	var inst: Node = packed.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame
	print("OK ", path)
	inst.queue_free()
	await process_frame
