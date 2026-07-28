extends "res://scripts/world/overworld.gd"


func _build_map() -> void:
	map_w = 22
	map_h = 22
	default_spawn = Vector2i(1, 10)
	encounter_table = "jungle1"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.GRASS)

	# dense tree border with west gap (Desert 3) and north gap (Jungle 2)
	for x in map_w:
		if x != 10 and x != 11:
			place_tree(Vector2i(x, 0), Tiles.TREE_GREEN_COL)
		place_tree(Vector2i(x, map_h - 1), Tiles.TREE_GREEN_COL)
	for y in range(1, map_h - 1):
		if y != 10 and y != 11:
			place_tree(Vector2i(0, y), Tiles.TREE_GREEN_COL)
		place_tree(Vector2i(map_w - 1, y), Tiles.TREE_GREEN_COL)

	for y in range(0, 22):
		set_ground(Vector2i(10, y), Tiles.PATH)
		set_ground(Vector2i(11, y), Tiles.PATH)
	for x in range(0, 11):
		set_ground(Vector2i(x, 10), Tiles.PATH)
		set_ground(Vector2i(x, 11), Tiles.PATH)

	add_warp(Vector2i(0, 10), "desert3", Vector2i(22, 8), "left")
	add_warp(Vector2i(0, 11), "desert3", Vector2i(22, 9), "left")
	add_warp(Vector2i(10, 0), "jungle2", Vector2i(9, 22), "up")
	add_warp(Vector2i(11, 0), "jungle2", Vector2i(10, 22), "up")

	_grass_patch(13, 3, 19, 9)
	_grass_patch(13, 13, 19, 19)
	_grass_patch(3, 3, 8, 8)

	# lush inner trees + flowers
	for p in [Vector2i(15, 11), Vector2i(6, 15), Vector2i(17, 20), Vector2i(4, 18)]:
		place_tree(p, Tiles.TREE_GREEN_COL)
	for p in [Vector2i(14, 12), Vector2i(5, 6), Vector2i(18, 16)]:
		set_ground(p, Tiles.FLOWERS)
	set_decor(Vector2i(7, 13), Tiles.MUSHROOM)

	add_interact(Vector2i(10, 20), { "type": "sign", "text": "VERDANT ROUTE 1 - humid air hums with wild Echoes. North: deeper jungle." })

	add_trainer(Vector2i(14, 12), "left", {
		"id": "j1_ranger", "name": "Canopy Ranger", "look": 4,
		"party": [{ "id": "fernkit", "level": 13 }, { "id": "dewling", "level": 14 }],
		"reward": 4,
		"intro": ["The thicket is my classroom.", "Class is in session!"],
		"win_line": "You read the jungle well. Impressive.",
	})
	add_trainer(Vector2i(5, 5), "down", {
		"id": "j1_leaf", "name": "Leafweaver Nia", "look": 1,
		"party": [{ "id": "acornel", "level": 13 }, { "id": "sporeling", "level": 14 }],
		"reward": 4,
		"intro": ["Vines listen to those who listen back.", "Hear me!"],
		"win_line": "The canopy approves.",
	}, 4)
	add_trainer(Vector2i(17, 16), "left", {
		"id": "j1_moss", "name": "Moss Guide Tor", "look": 8,
		"party": [{ "id": "fungit", "level": 14 }, { "id": "bloomhound", "level": 14 }, { "id": "plumeria", "level": 15 }],
		"reward": 4,
		"intro": ["Lost already? Good. Battle clears the mind.", "Go!"],
		"win_line": "North grows denser. Stay sharp.",
	}, 3)





	# discovery: vine_cathedral
	open_passage(Vector2i(19, 10), Tiles.PATH)
	open_passage(Vector2i(20, 10), Tiles.PATH)
	open_passage(Vector2i(19, 11), Tiles.PATH)
	open_passage(Vector2i(20, 11), Tiles.PATH)
	add_warp(Vector2i(20, 10), "vine_cathedral", Vector2i(9, 22), "right")
	add_warp(Vector2i(20, 11), "vine_cathedral", Vector2i(10, 22), "right")
	add_interact(Vector2i(18, 10), { "type": "sign", "text": "VINE CATHEDRAL - living nave." })

func _place_pickups() -> void:
	add_pickup(Vector2i(16, 5), "echo_capsule", 2)
	add_pickup(Vector2i(4, 16), "heart_salve", 2)
	add_pickup(Vector2i(18, 18), "great_capsule", 2)
	add_pickup(Vector2i(6, 4), "super_salve", 1)


func _grass_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y))
