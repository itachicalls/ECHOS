extends "res://scripts/world/overworld.gd"


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "jungle2"

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
	for x in range(3, 10):
		set_ground(Vector2i(x, 14), Tiles.PATH)
		set_ground(Vector2i(x, 15), Tiles.PATH)

	add_warp(Vector2i(9, 23), "jungle1", Vector2i(10, 1), "down")
	add_warp(Vector2i(10, 23), "jungle1", Vector2i(11, 1), "down")
	add_warp(Vector2i(9, 0), "jungle3", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "jungle3", Vector2i(10, 22), "up")

	# marsh pool
	for x in range(12, 17):
		for y in range(4, 9):
			set_ground(Vector2i(x, y), Tiles.WATER)
			block(Vector2i(x, y))

	_grass_patch(2, 5, 7, 12)
	_grass_patch(12, 16, 17, 22)
	_grass_patch(4, 17, 8, 22)

	for p in [Vector2i(6, 13), Vector2i(3, 20), Vector2i(16, 18)]:
		place_tree(p, Tiles.TREE_GREEN_COL)
	for p in [Vector2i(5, 8), Vector2i(14, 11), Vector2i(7, 21)]:
		set_ground(p, Tiles.FLOWERS)
	set_decor(Vector2i(4, 6), Tiles.MUSHROOM)

	add_interact(Vector2i(9, 22), { "type": "sign", "text": "VERDANT ROUTE 2 - vines thicken ahead. Beware the marsh pool." })

	add_trainer(Vector2i(6, 10), "right", {
		"id": "j2_herbal", "name": "Herbalist Mira", "look": 3,
		"party": [{ "id": "fernkit", "level": 15 }, { "id": "bramblor", "level": 16 }],
		"reward": 5,
		"intro": ["I brew salves from jungle leaves.", "Let's see whose Echoes thrive!"],
		"win_line": "Your team blooms beautifully.",
	})
	add_trainer(Vector2i(5, 19), "up", {
		"id": "j2_scout", "name": "Trail Scout", "look": 0,
		"party": [{ "id": "dewling", "level": 14 }, { "id": "duskling", "level": 15 }, { "id": "marowl", "level": 15 }],
		"reward": 5,
		"intro": ["I've mapped every root and river here.", "Test my trail knowledge!"],
		"win_line": "You'd survive the deep jungle. Respect.",
	})

	# thorn thickets sting the unwary
	for p in [Vector2i(11, 12), Vector2i(12, 13), Vector2i(13, 12), Vector2i(8, 13)]:
		if not is_blocked(p):
			add_spikes(p)


func _place_pickups() -> void:
	add_pickup(Vector2i(3, 6), "heart_salve", 1)
	add_pickup(Vector2i(17, 21), "echo_capsule", 2)


func _grass_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y))
