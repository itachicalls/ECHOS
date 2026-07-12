extends "res://scripts/world/overworld.gd"


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "desert1"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.SAND)
	# sand texture variation
	for x in range(0, map_w, 3):
		for y in range(0, map_h, 4):
			set_ground(Vector2i(x, y), Tiles.SAND2)

	# tree border with south gap (Route 2) and north gap (Desert 2)
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
	add_warp(Vector2i(9, 23), "route2", Vector2i(3, 1), "down")
	add_warp(Vector2i(10, 23), "route2", Vector2i(4, 1), "down")
	add_warp(Vector2i(9, 0), "desert2", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "desert2", Vector2i(10, 22), "up")

	_brush_patch(2, 4, 7, 10)
	_brush_patch(12, 6, 17, 12)
	_brush_patch(3, 14, 8, 20)
	_brush_patch(12, 15, 16, 21)

	for p in [Vector2i(7, 7), Vector2i(14, 9), Vector2i(6, 18), Vector2i(15, 17)]:
		place_bush(p)

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "SCORCH ROUTE 1 - blistering sands hide hardy Echoes. North leads deeper." })

	add_trainer(Vector2i(6, 12), "right", {
		"id": "d1_sage", "name": "Nomad Sage", "look": 9,
		"party": [{ "id": "pebblit", "level": 10 }, { "id": "cindboth", "level": 11 }],
		"reward": 3,
		"intro": ["The desert tests every trainer.", "Show me your grit!"],
		"win_line": "You carry the sun's courage. Take these Capsules.",
	})


func _brush_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y), Tiles.DESERT_BRUSH)
