extends "res://scripts/world/overworld.gd"


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "jungle3"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.GRASS)

	for x in map_w:
		if x != 9 and x != 10:
			place_tree(Vector2i(x, 0), Tiles.TREE_GREEN_COL)
			place_tree(Vector2i(x, map_h - 1), Tiles.TREE_GREEN_COL)
	for y in range(1, map_h - 1):
		place_tree(Vector2i(0, y), Tiles.TREE_GREEN_COL)
		place_tree(Vector2i(map_w - 1, y), Tiles.TREE_GREEN_COL)

	for y in range(0, 24):
		set_ground(Vector2i(9, y), Tiles.PATH)
		set_ground(Vector2i(10, y), Tiles.PATH)

	add_warp(Vector2i(9, 23), "jungle2", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "jungle2", Vector2i(10, 1), "down")
	add_warp(Vector2i(9, 0), "cave1", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "cave1", Vector2i(10, 22), "up")

	_grass_patch(2, 8, 7, 14)
	_grass_patch(12, 4, 17, 11)
	_grass_patch(3, 16, 8, 21)
	_grass_patch(12, 14, 17, 21)

	# deep-grove trees + flowers
	for p in [Vector2i(7, 6), Vector2i(14, 12), Vector2i(5, 15), Vector2i(15, 16), Vector2i(12, 12)]:
		place_tree(p, Tiles.TREE_GREEN_COL)
	for p in [Vector2i(6, 12), Vector2i(13, 9), Vector2i(4, 19)]:
		set_ground(p, Tiles.FLOWERS)
	set_decor(Vector2i(15, 6), Tiles.MUSHROOM)

	# grove clinic
	add_heal_station(Vector2i(12, 5), Vector2i(12, 4), "down")
	add_interact(Vector2i(9, 21), { "type": "sign", "text": "VERDANT ROUTE 3 - the heart of the jungle. Rare Harmons lurk in the ferns." })

	add_trainer(Vector2i(7, 14), "right", {
		"id": "j3_elder", "name": "Grove Elder", "look": 1,
		"party": [{ "id": "bramblor", "level": 18 }, { "id": "nocturn", "level": 18 }, { "id": "gustrel", "level": 17 }],
		"reward": 7,
		"intro": ["Few explorers reach the grove's heart.", "Prove your bond with your Harmons!"],
		"win_line": "The ancient trees bow to your spirit.",
	})
	add_trainer(Vector2i(14, 18), "left", {
		"id": "j3_rival", "name": "Rival Sabo", "look": 3,
		"party": [{ "id": "flarefox", "level": 19 }, { "id": "marowl", "level": 18 }, { "id": "nocturn", "level": 19 }],
		"reward": 8,
		"intro": ["I knew you'd make it this far.", "This is where I surpass you!"],
		"win_line": "...Fine. Next time I'll be stronger. Count on it.",
	})

	# JUNGLE GYM — seals the northern cavern pass to the Crag Caverns.
	add_interact(Vector2i(8, 3), { "type": "sign", "text": "GROVE TRIAL - Ranger Ivy guards the cavern pass. Earn her Sigil to descend!" })
	add_gym_gate({
		"id": "gym_jungle", "name": "Ranger Ivy", "look": 1,
		"party": [{ "id": "myconid", "level": 21 }, { "id": "nocturn", "level": 21 }, { "id": "creepvine", "level": 22 }],
		"reward": 8, "gym": true,
		"intro": ["I am Ivy, Grove Route Ranger.", "Beyond lies the Crag Caverns. Earn your Sigil!"],
		"win_line": "The vines part for you. The caverns await below.",
	}, Vector2i(9, 2), "down", [Vector2i(9, 0), Vector2i(10, 0)], Vector2i(7, 3), [Vector2i(10, 2)])


func _grass_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y))
