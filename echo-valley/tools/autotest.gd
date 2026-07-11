extends Node

## Runs in a normal (non --script) headless run so autoload globals resolve.
## Instantiates every scene to catch _ready runtime errors, then quits.


func _ready() -> void:
	await get_tree().process_frame
	GameState.party.clear()
	GameState.party.append(EchoCatalog.create_instance("emberkit", 6))
	GameState.party.append(EchoCatalog.create_instance("tideling", 5))

	for path in [
		"res://scenes/boot/loading.tscn",
		"res://scenes/boot/title.tscn",
		"res://scenes/world/town.tscn",
		"res://scenes/world/route1.tscn",
		"res://scenes/world/route2.tscn",
		"res://scenes/world/desert1.tscn",
		"res://scenes/world/desert2.tscn",
		"res://scenes/world/desert3.tscn",
		"res://scenes/world/jungle1.tscn",
		"res://scenes/world/jungle2.tscn",
		"res://scenes/world/jungle3.tscn",
		"res://scenes/boot/versus_setup.tscn",
	]:
		await _try(path)

	# wild battle
	var enemy := EchoCatalog.create_instance("pebblit", 4)
	SceneRouter._battle_request = { "kind": "wild", "enemies": [enemy], "return_map": "route1", "can_flee": true, "can_catch": true }
	await _try("res://scenes/battle/battle.tscn")

	# trainer battle
	SceneRouter._battle_request = {
		"kind": "trainer", "enemies": [EchoCatalog.create_instance("fernkit", 9), EchoCatalog.create_instance("dewling", 9)],
		"trainer_name": "Ranger Lena", "return_map": "route2", "can_flee": false, "can_catch": false,
		"trainer_id": "r2_lena", "reward": 3, "win_line": "GG",
	}
	await _try("res://scenes/battle/battle.tscn")

	# versus battle
	SceneRouter._battle_request = {
		"kind": "versus", "trainer_name": "Ace Nova", "can_flee": false, "can_catch": false,
		"player_override": [EchoCatalog.create_instance("gustrel", 15), EchoCatalog.create_instance("craggan", 15)],
		"enemies": [EchoCatalog.create_instance("nocturn", 15), EchoCatalog.create_instance("marowl", 15)],
	}
	await _try("res://scenes/battle/battle.tscn")

	# verify new echoes exist
	for id in ["craggan", "gustrel", "nocturn", "dewling", "fernkit", "cindboth"]:
		if EchoDatabase.instance.has_echo(id):
			print("OK echo ", id)
		else:
			print("FAIL echo ", id)

	print("AUTOTEST DONE")
	get_tree().quit(0)


func _try(path: String) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		print("FAIL load ", path)
		return
	var inst: Node = packed.instantiate()
	add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	print("OK ", path)
	inst.queue_free()
	await get_tree().process_frame
