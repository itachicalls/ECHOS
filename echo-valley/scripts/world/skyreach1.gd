extends "res://scripts/world/overworld.gd"

## SKYREACH SPIRE — post-game air route above Ashpeak. Endgame wilds + legend.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "skyreach1"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.GRASS2)
	for x in map_w:
		if x != 9 and x != 10:
			place_tree(Vector2i(x, 0), Tiles.TREE_GREEN_COL)
			place_tree(Vector2i(x, map_h - 1), Tiles.TREE_GREEN_COL)
	for y in range(1, map_h - 1):
		place_tree(Vector2i(0, y), Tiles.TREE_GREEN_COL)
		place_tree(Vector2i(map_w - 1, y), Tiles.TREE_GREEN_COL)

	for y in range(0, map_h):
		set_ground(Vector2i(9, y), Tiles.PATH)
		set_ground(Vector2i(10, y), Tiles.PATH)
	for x in range(2, 18):
		set_ground(Vector2i(x, 10), Tiles.PATH)

	add_warp(Vector2i(9, 23), "ashpeak1", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "ashpeak1", Vector2i(10, 1), "down")
	add_warp(Vector2i(9, 0), "frostvale1", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "frostvale1", Vector2i(10, 22), "up")

	for p in [Vector2i(4, 5), Vector2i(15, 6), Vector2i(5, 18), Vector2i(14, 17)]:
		add_ground_prop(Tiles.CRYSTAL, p, true)

	_grass_patch(2, 12, 7, 20)
	_grass_patch(12, 12, 17, 20)
	_grass_patch(3, 3, 8, 8)
	_grass_patch(12, 3, 16, 8)

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "SKYREACH SPIRE - winds older than the Chorus. North descends into Frostvale Reach." })

	add_trainer(Vector2i(5, 14), "right", {
		"id": "sky_gale", "name": "Gale Rider", "look": 11,
		"party": [{ "id": "squallow", "level": 52 }, { "id": "cyclonimbus", "level": 53 }, { "id": "tempestwing", "level": 54 }],
		"reward": 10,
		"intro": ["Up here, only the bold stay grounded!", "Fly with me!"],
		"win_line": "You own the air.",
	}, 4)
	add_trainer(Vector2i(14, 8), "left", {
		"id": "sky_cloud", "name": "Cloud Archivist", "look": 4,
		"party": [{ "id": "galewhisk", "level": 53 }, { "id": "skytalon", "level": 54 }, { "id": "thunderoc", "level": 55 }],
		"reward": 10,
		"intro": ["I record every storm-name.", "Add yours in battle!"],
		"win_line": "Written. You are legend-adjacent.",
	}, 5)
	add_trainer(Vector2i(6, 6), "down", {
		"id": "sky_zeph", "name": "Zephyr Monk", "look": 17,
		"party": [{ "id": "breezik", "level": 52 }, { "id": "glidewatt", "level": 53 }],
		"reward": 9,
		"intro": ["Breathe. Battle. Become wind."],
		"win_line": "Peace. The summit is yours.",
	}, 4)
	add_legend_encounter(Vector2i(9, 5), "skysovereign", 62,
		"Clouds crown a throne of gale. SKYSOVEREIGN opens its wings — the sky itself answers!")

	add_heal_station(Vector2i(12, 20), Vector2i(12, 19), "down")


func _place_pickups() -> void:
	add_pickup(Vector2i(3, 18), "ultra_capsule", 3)
	add_pickup(Vector2i(16, 4), "max_salve", 2)
	add_pickup(Vector2i(4, 7), "evo_capsule", 1)
	add_pickup(Vector2i(17, 15), "super_salve", 3)


func _grass_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)) and not warps.has(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y))
