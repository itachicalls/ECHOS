extends "res://scripts/world/overworld.gd"


func _build_map() -> void:
	map_w = 18
	map_h = 22
	default_spawn = Vector2i(8, 20)
	encounter_table = "route2"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.GRASS)

	# tree border with south gap (Route 1) and north-west gap (Desert 1)
	for x in map_w:
		if x != 3 and x != 4:
			place_tree(Vector2i(x, 0), Tiles.TREE_GREEN_COL)
		if x != 8 and x != 9:
			place_tree(Vector2i(x, map_h - 1), Tiles.TREE_GREEN_COL)
	for y in range(1, map_h - 1):
		place_tree(Vector2i(0, y), Tiles.TREE_GREEN_COL)
		place_tree(Vector2i(map_w - 1, y), Tiles.TREE_GREEN_COL)

	# winding path
	for y in range(11, 22):
		set_ground(Vector2i(8, y), Tiles.PATH)
		set_ground(Vector2i(9, y), Tiles.PATH)
	for x in range(3, 10):
		set_ground(Vector2i(x, 11), Tiles.PATH)
		set_ground(Vector2i(x, 12), Tiles.PATH)
	for y in range(0, 12):
		set_ground(Vector2i(3, y), Tiles.PATH)
		set_ground(Vector2i(4, y), Tiles.PATH)
	add_warp(Vector2i(8, 21), "route1", Vector2i(9, 1), "down")
	add_warp(Vector2i(9, 21), "route1", Vector2i(10, 1), "down")
	add_warp(Vector2i(3, 0), "desert1", Vector2i(9, 22), "up")
	add_warp(Vector2i(4, 0), "desert1", Vector2i(10, 22), "up")

	# forest pond, north-east
	for x in range(11, 16):
		for y in range(3, 8):
			set_ground(Vector2i(x, y), Tiles.WATER)
			block(Vector2i(x, y))

	# tall-grass meadows
	_grass_patch(6, 13, 7, 19)
	_grass_patch(11, 13, 16, 20)
	_grass_patch(6, 3, 10, 9)

	# scenery
	for p in [Vector2i(2, 10), Vector2i(10, 10), Vector2i(15, 10), Vector2i(11, 16)]:
		place_tree(p, Tiles.TREE_GREEN_COL)
	for p in [Vector2i(7, 12), Vector2i(4, 15), Vector2i(13, 11)]:
		set_ground(p, Tiles.FLOWERS)
	set_decor(Vector2i(5, 5), Tiles.MUSHROOM)

	add_interact(Vector2i(8, 19), { "type": "sign", "text": "ECHOWOOD - deeper Echoes roam here. The path north-west leads to the desert." })

	add_trainer(Vector2i(6, 16), "right", {
		"id": "r2_lena", "name": "Ranger Lena", "look": 4,
		"party": [{ "id": "fernkit", "level": 9 }, { "id": "dewling", "level": 9 }],
		"reward": 3,
		"intro": ["The Echowood is my home turf.", "Prove you belong here!"],
		"win_line": "The forest smiles on you. Well done.",
	})
	add_trainer(Vector2i(7, 6), "down", {
		"id": "r2_rival", "name": "Rival Sabo", "look": 3,
		"party": [{ "id": "duskling", "level": 10 }, { "id": "cindboth", "level": 10 }, { "id": "zephyr", "level": 11 }],
		"reward": 5,
		"intro": ["So YOU'RE the trainer everyone's talking about.", "Let's find out if the hype is real!"],
		"win_line": "...Not bad. This won't be our last battle.",
	})

	# GRASS GYM — seals the pass to the Scorch Desert until defeated.
	add_interact(Vector2i(5, 2), { "type": "sign", "text": "MEADOW GYM - Leader Fern guards the desert pass. Defeat her to cross!" })
	add_gym_gate({
		"id": "gym_grass", "name": "Leader Fern", "look": 1,
		"party": [{ "id": "fernkit", "level": 12 }, { "id": "thornvine", "level": 13 }, { "id": "bramblor", "level": 14 }],
		"reward": 6, "gym": true,
		"intro": ["I am Fern, Meadow Gym Leader.", "None cross to the desert without besting my Echoes!"],
		"win_line": "The meadow yields to you. The desert pass is open — go!",
	}, Vector2i(3, 1), "down", [Vector2i(3, 0), Vector2i(4, 0)], Vector2i(2, 2), [Vector2i(4, 1)])


func _grass_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y))
