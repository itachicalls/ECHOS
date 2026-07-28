extends "res://scripts/world/overworld.gd"

## ASHPEAK CALDERA — post-game fire route. Opens after deciding the valley's fate.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "ashpeak1"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.SAND2)
	for x in map_w:
		if x != 9 and x != 10:
			place_rock(Vector2i(x, 0))
			place_rock(Vector2i(x, map_h - 1))
	for y in range(1, map_h - 1):
		place_rock(Vector2i(0, y))
		place_rock(Vector2i(map_w - 1, y))

	for y in range(0, map_h):
		set_ground(Vector2i(9, y), Tiles.STONE)
		set_ground(Vector2i(10, y), Tiles.STONE)
	for x in range(3, 17):
		set_ground(Vector2i(x, 12), Tiles.STONE)

	# lava pools
	for c in [Vector2i(3, 5), Vector2i(4, 5), Vector2i(3, 6), Vector2i(15, 16), Vector2i(16, 16), Vector2i(15, 17)]:
		set_ground(c, Tiles.WATER)
		block(c)

	add_warp(Vector2i(9, 23), "town", Vector2i(12, 18), "down")
	add_warp(Vector2i(10, 23), "town", Vector2i(13, 18), "down")
	add_warp(Vector2i(9, 0), "skyreach1", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "skyreach1", Vector2i(10, 22), "up")

	_brush_patch(2, 8, 7, 14)
	_brush_patch(12, 8, 17, 14)
	_brush_patch(3, 16, 8, 21)
	_brush_patch(12, 3, 16, 7)

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "ASHPEAK CALDERA - post-fate fire route. North climbs toward Skyreach Spire." })

	add_trainer(Vector2i(5, 10), "right", {
		"id": "ash_cinder", "name": "Cinder Monk", "look": 7,
		"party": [{ "id": "magmapup", "level": 48 }, { "id": "volcanid", "level": 49 }, { "id": "infernost", "level": 50 }],
		"reward": 8,
		"intro": ["The caldera forges legends.", "Step into the heat!"],
		"win_line": "Tempered. Ascend.",
	}, 4)
	add_trainer(Vector2i(14, 15), "left", {
		"id": "ash_flare", "name": "Flare Knight", "look": 5,
		"party": [{ "id": "phoenixar", "level": 50 }, { "id": "pyrelynx", "level": 51 }, { "id": "hellhoof", "level": 51 }],
		"reward": 9,
		"intro": ["Ash rains. Blades rise.", "Prove your flame!"],
		"win_line": "Your fire outshines mine.",
	}, 5)
	add_trainer(Vector2i(6, 18), "up", {
		"id": "ash_vein", "name": "Magma Surveyor", "look": 8,
		"party": [{ "id": "embertoad", "level": 49 }, { "id": "calderoad", "level": 50 }],
		"reward": 8,
		"intro": ["Readings spike — battle incoming!"],
		"win_line": "Data logged. You're volcanic.",
	}, 4)
	add_legend_encounter(Vector2i(9, 6), "solarch", 60,
		"The caldera sun collapses into form. SOLARCH — dayfire incarnate — crowns the peak!")

	add_npc(Vector2i(11, 20), "left", Color(1, 1, 1), {
		"type": "npc",
		"lines": [
			"After Primordius, the Fracture opened this caldera.",
			"Climb north if your team can breathe thin fire.",
		],
	}, Tiles.TRAINER_PATHS[5], 1)





	# discovery: starfall_crater
	open_passage(Vector2i(17, 10), Tiles.PATH)
	open_passage(Vector2i(18, 10), Tiles.PATH)
	open_passage(Vector2i(17, 11), Tiles.PATH)
	open_passage(Vector2i(18, 11), Tiles.PATH)
	add_warp(Vector2i(18, 10), "starfall_crater", Vector2i(9, 22), "right", ["story_complete"], "Side path sealed for now...")
	add_warp(Vector2i(18, 11), "starfall_crater", Vector2i(10, 22), "right", ["story_complete"], "Side path sealed for now...")
	add_interact(Vector2i(16, 10), { "type": "sign", "text": "STARFALL CRATER - post-fate bruise." })

func _place_pickups() -> void:
	add_pickup(Vector2i(3, 19), "ultra_capsule", 2)
	add_pickup(Vector2i(16, 5), "max_salve", 2)
	add_pickup(Vector2i(4, 9), "super_salve", 2)
	add_pickup(Vector2i(17, 18), "great_capsule", 3)


func _brush_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)) and not warps.has(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y), Tiles.DESERT_BRUSH)
