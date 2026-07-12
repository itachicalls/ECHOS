extends "res://scripts/world/overworld.gd"

## TIDECROSS SHORE — sunlit beach route west of town. Water-attuned Harmons and
## the first hint that stranger resonances wash in from the sea.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(18, 11)
	encounter_table = "beach1"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.SAND)

	# the sea along the south edge
	for x in map_w:
		for y in range(21, map_h):
			set_ground(Vector2i(x, y), Tiles.WATER)
			block(Vector2i(x, y))
	# a tide pool inlet, north-west
	for x in range(2, 6):
		for y in range(3, 6):
			set_ground(Vector2i(x, y), Tiles.WATER)
			block(Vector2i(x, y))

	# sand path: east gate (town) -> center -> north gate (Saltwind Cove)
	for x in range(2, 20):
		set_ground(Vector2i(x, 11), Tiles.SAND_PATH)
	for x in range(16, 20):
		set_ground(Vector2i(x, 10), Tiles.SAND_PATH)
	for y in range(1, 12):
		set_ground(Vector2i(9, y), Tiles.SAND_PATH)
		set_ground(Vector2i(10, y), Tiles.SAND_PATH)

	# gates
	add_warp(Vector2i(19, 10), "town", Vector2i(1, 14), "right")
	add_warp(Vector2i(19, 11), "town", Vector2i(1, 15), "right")
	add_warp(Vector2i(9, 0), "tide_town", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "tide_town", Vector2i(10, 22), "up")

	# palms line the dunes
	for p in [Vector2i(3, 8), Vector2i(6, 14), Vector2i(14, 6), Vector2i(16, 14), Vector2i(4, 18), Vector2i(13, 18)]:
		add_ground_prop(Tiles.PALM, p, true)

	# beach scrub = encounter zones
	_scrub_patch(2, 13, 7, 19)
	_scrub_patch(12, 13, 16, 19)
	_scrub_patch(12, 2, 17, 8)

	add_interact(Vector2i(18, 12), { "type": "sign", "text": "TIDECROSS SHORE - coastal Harmons gather in the sea scrub. North: Saltwind Cove." })
	add_interact(Vector2i(8, 20), { "type": "sign", "text": "Legends say a colossal tide-serpent circles these waters on the rarest days..." })

	# a beachcomber greeter gifts capsules
	add_greeter(Vector2i(17, 11), "left", {
		"id": "beach_marisol", "look": 19,
		"gifts": { "echo_capsule": 6, "heart_salve": 3 },
		"lines": [
			"Oh! A keeper this far west? Welcome to Tidecross.",
			"The coast draws Harmons no one's cataloged before - keep your capsules ready.",
			"Take these. The Cove ahead has a clinic if your team tires.",
		],
		"repeat": ["The sea's been restless lately. Mind the deep water."],
	}, 4)

	add_trainer(Vector2i(6, 16), "right", {
		"id": "beach_tomas", "name": "Surfer Tomas", "look": 10,
		"party": [{ "id": "dripling", "level": 10 }, { "id": "mistkoi", "level": 11 }],
		"reward": 3, "ranger": false,
		"intro": ["Caught the tide just right, huh?", "Let's see if your team can ride the waves!"],
		"win_line": "Whoa, totally swept me out. Nice one!",
	}, 4)
	add_trainer(Vector2i(14, 8), "down", {
		"id": "beach_nerissa", "name": "Diver Nerissa", "look": 15,
		"party": [{ "id": "shellby", "level": 11 }, { "id": "fintot", "level": 12 }],
		"reward": 3,
		"intro": ["The reef taught me patience.", "Show me the bond you've built!"],
		"win_line": "The current favors you. Well fought.",
	}, 4)


func _place_pickups() -> void:
	add_pickup(Vector2i(3, 13), "echo_capsule", 2)
	add_pickup(Vector2i(15, 3), "heart_salve", 2)


func _scrub_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)) and not warps.has(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y), Tiles.DESERT_BRUSH)
