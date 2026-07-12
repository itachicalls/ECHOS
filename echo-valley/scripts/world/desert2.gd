extends "res://scripts/world/overworld.gd"


func _build_map() -> void:
	map_w = 22
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "desert2"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.SAND)
	for x in range(1, map_w, 3):
		for y in range(2, map_h, 5):
			set_ground(Vector2i(x, y), Tiles.SAND2)

	for x in map_w:
		if x != 9 and x != 10:
			place_tree(Vector2i(x, 0), Tiles.TREE_ORANGE_COL)
			place_tree(Vector2i(x, map_h - 1), Tiles.TREE_ORANGE_COL)
	for y in range(1, map_h - 1):
		place_tree(Vector2i(0, y), Tiles.TREE_ORANGE_COL)
		place_tree(Vector2i(map_w - 1, y), Tiles.TREE_ORANGE_COL)

	for y in range(0, 24):
		set_ground(Vector2i(9, y), Tiles.SAND_PATH)
		set_ground(Vector2i(10, y), Tiles.SAND_PATH)
	for x in range(14, 22):
		set_ground(Vector2i(x, 12), Tiles.SAND_PATH)
		set_ground(Vector2i(x, 13), Tiles.SAND_PATH)

	add_warp(Vector2i(9, 23), "desert1", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "desert1", Vector2i(10, 1), "down")
	add_warp(Vector2i(9, 0), "desert3", Vector2i(10, 22), "up")
	add_warp(Vector2i(10, 0), "desert3", Vector2i(11, 22), "up")

	_brush_patch(3, 5, 8, 11)
	_brush_patch(13, 14, 18, 20)
	_brush_patch(4, 15, 8, 21)

	for p in [Vector2i(5, 8), Vector2i(16, 10), Vector2i(7, 19), Vector2i(17, 16)]:
		place_bush(p)

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "SCORCH ROUTE 2 - mirages dance ahead. An east fork winds through the dunes." })

	add_trainer(Vector2i(15, 12), "left", {
		"id": "d2_rider", "name": "Dune Rider", "look": 7,
		"party": [{ "id": "zephyr", "level": 12 }, { "id": "craggan", "level": 13 }],
		"reward": 4,
		"intro": ["I race the wind across these dunes!", "Try to keep up!"],
		"win_line": "Ha! You've got desert legs. Well fought.",
	})
	add_trainer(Vector2i(7, 17), "down", {
		"id": "d2_mason", "name": "Ruin Mason", "look": 9,
		"party": [{ "id": "pebblit", "level": 11 }, { "id": "duskling", "level": 12 }, { "id": "cindboth", "level": 12 }],
		"reward": 4,
		"intro": ["Ancient stones whisper secrets here.", "Battle me among the ruins!"],
		"win_line": "The ruins approve of your strength.",
	})


func _brush_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y), Tiles.DESERT_BRUSH)
