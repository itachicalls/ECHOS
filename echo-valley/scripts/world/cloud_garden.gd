extends "res://scripts/world/overworld.gd"

## CLOUD GARDEN — discoverable themed area.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "cloud_garden"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.STONE)

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

	add_warp(Vector2i(9, 23), "skyreach1", Vector2i(3, 10), "down")
	add_warp(Vector2i(10, 23), "skyreach1", Vector2i(4, 10), "down")

	_brush_patch(2, 8, 7, 14)
	_brush_patch(12, 8, 17, 14)
	_brush_patch(3, 16, 8, 21)
	_brush_patch(12, 3, 16, 7)

	for p in [Vector2i(4, 7), Vector2i(15, 9), Vector2i(8, 15)]:
		add_ground_prop(Tiles.CRYSTAL, p, true)

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "CLOUD GARDEN - Terraces float above Ashpeak's smoke." })

	add_trainer(Vector2i(5, 10), "right", {
		"id": "cloud_garden_t0", "name": "Scholar Otto", "look": 15,
		"party": [{ "id": "stratoson", "level": 37 }, { "id": "draftling", "level": 38 }],
		"reward": 6,
		"intro": ["Cloud Garden tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"Talk to every beaten keeper. We trade rumors for tough fights.",
		],
		"hint": "Talk to every beaten keeper. We trade rumors for tough fights.",
	}, 3)
	add_trainer(Vector2i(14, 14), "left", {
		"id": "cloud_garden_t1", "name": "Warden Pia", "look": 1,
		"party": [{ "id": "aeroquil", "level": 38 }, { "id": "featherkit", "level": 39 }, { "id": "squallow", "level": 40 }],
		"reward": 7,
		"intro": ["Cloud Garden tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"Side paths hide mansions, towers, and mines off the main gym road.",
		],
		"hint": "Side paths hide mansions, towers, and mines off the main gym road.",
	}, 4)
	add_trainer(Vector2i(6, 17), "up", {
		"id": "cloud_garden_t2", "name": "Seeker Cal", "look": 0,
		"party": [{ "id": "skyranger", "level": 39 }, { "id": "sprytefly", "level": 40 }],
		"reward": 8,
		"intro": ["Cloud Garden tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"After Champion Vael, the western Tidecross trail opens from Harmona Rest. After Primordius, go south to Ashpeak.",
		],
		"hint": "After Champion Vael, the western Tidecross trail opens from Harmona Rest. After Primordius, go south to Ashpeak.",
	}, 5)

	add_legend_encounter(Vector2i(9, 6), "stratoson", 44,
		"Clouds part. STRATOSON blooms above the terrace!")

	add_npc(Vector2i(11, 20), "left", Color(1, 1, 1), {
		"type": "npc",
		"lines": [
			"Terraces float above Ashpeak's smoke.",
			"Beat the keepers here — talk to them again for path rumors.",
		],
	}, Tiles.TRAINER_PATHS[0], 1)


func _place_pickups() -> void:
	add_pickup(Vector2i(3, 19), "echo_capsule", 3)
	add_pickup(Vector2i(16, 5), "heart_salve", 3)
	add_pickup(Vector2i(4, 9), "great_capsule", 2)
	add_pickup(Vector2i(17, 18), "max_salve", 1)


func _brush_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)) and not warps.has(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y), Tiles.DESERT_BRUSH)
