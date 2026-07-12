extends "res://scripts/world/overworld.gd"


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "route1"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.GRASS)

	# tree border with south (town) and north (route 2) gaps
	for x in map_w:
		if x != 9 and x != 10:
			place_tree(Vector2i(x, 0), Tiles.TREE_GREEN_COL)
			place_tree(Vector2i(x, map_h - 1), Tiles.TREE_GREEN_COL)
	for y in range(1, map_h - 1):
		place_tree(Vector2i(0, y), Tiles.TREE_GREEN_COL)
		place_tree(Vector2i(map_w - 1, y), Tiles.TREE_GREEN_COL)

	# main path south -> north
	for y in range(0, 24):
		set_ground(Vector2i(9, y), Tiles.PATH)
		set_ground(Vector2i(10, y), Tiles.PATH)
	add_warp(Vector2i(9, 23), "town", Vector2i(12, 1), "down")
	add_warp(Vector2i(10, 23), "town", Vector2i(13, 1), "down")
	add_warp(Vector2i(9, 0), "route2", Vector2i(8, 20), "up")
	add_warp(Vector2i(10, 0), "route2", Vector2i(9, 20), "up")

	# tall-grass meadows
	_grass_patch(2, 3, 7, 9)
	_grass_patch(12, 5, 17, 11)
	_grass_patch(3, 13, 8, 19)
	_grass_patch(12, 15, 16, 20)

	# scattered trees + decor
	for p in [Vector2i(8, 6), Vector2i(11, 12), Vector2i(8, 14), Vector2i(11, 4)]:
		place_tree(p, Tiles.TREE_ORANGE_COL)
	for p in [Vector2i(5, 11), Vector2i(14, 13), Vector2i(6, 21)]:
		set_ground(p, Tiles.FLOWERS)
	set_decor(Vector2i(15, 4), Tiles.MUSHROOM)

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "ROUTE 1 - wild Echoes live in the tall grass. North leads deeper into the valley." })

	# Pond for fishing once you have a rod.
	for x in range(2, 6):
		for y in range(17, 20):
			set_ground(Vector2i(x, y), Tiles.WATER)
			block(Vector2i(x, y))
	add_interact(Vector2i(3, 18), { "type": "sign", "text": "STILL POND - face the water and press J to fish. Only water Harmons bite here." })

	# Pathkeeper Mara greets new keepers leaving town.
	add_greeter(Vector2i(9, 20), "down", {
		"id": "r1_mara",
		"look": 1,
		"gifts": { "echo_capsule": 5, "heart_salve": 3, "fishing_rod": 1 },
		"lines": [
			"Hold on, new keeper! Welcome to Route 1.",
			"Harmona Valley is beautiful — but the tall grass hides wild Harmons that show no mercy.",
			"Take these supplies. Fish the pond when you need water types, and tread carefully beyond the meadows.",
		],
		"repeat": [
			"Still getting your bearings? Good.",
			"The pond west of the path is calm — perfect for practicing with your rod.",
		],
	}, 5)

	add_trainer(Vector2i(6, 11), "down", {
		"id": "r1_finn", "name": "Camper Finn", "look": 4,
		"party": [{ "id": "pebblit", "level": 5 }, { "id": "zephyr", "level": 6 }],
		"reward": 2,
		"intro": ["Hey! You walked right into my line of sight!", "A Keeper never turns down a challenge. Go!"],
		"win_line": "Whoa, you're strong! I need to train more.",
	})
	# a second sight-line trainer guarding the eastern meadow
	add_trainer(Vector2i(15, 8), "left", {
		"id": "r1_maple", "name": "Forager Maple", "look": 0,
		"party": [{ "id": "mossling", "level": 6 }, { "id": "dewling", "level": 6 }],
		"reward": 2,
		"intro": ["Not so fast! These meadows are my training ground.", "Show me your bond with your Echoes!"],
		"win_line": "You and your Echoes move as one. Impressive!",
	}, 4)
	add_npc(Vector2i(13, 18), "down", Color(1, 1, 1), {
		"type": "npc",
		"lines": [
			"Weaken a wild Echo before tossing a Capsule - lower HP means a better catch!",
			"And watch the tall grass. That's where wild Echoes hide.",
		],
	}, Tiles.TRAINER_PATHS[1], 2)
	add_interact(Vector2i(8, 21), { "type": "sign", "text": "WARNING: Trainers ahead battle on sight. Step lightly, or step up!" })

	# one-way ledges: hop south to shortcut back down the route
	add_ledge(Vector2i(13, 12))
	add_ledge(Vector2i(14, 12))
	add_ledge(Vector2i(15, 12))


func _place_pickups() -> void:
	add_pickup(Vector2i(4, 5), "echo_capsule", 2)
	add_pickup(Vector2i(16, 18), "heart_salve", 1)


func _grass_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y))
