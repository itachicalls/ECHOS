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

	add_interact(Vector2i(12, 6), { "type": "sign", "text": "FISHING DOCK - face the pond and press J with your Fishing Rod equipped in your bag." })

	add_trainer(Vector2i(6, 16), "right", {
		"id": "r2_lena", "name": "Ranger Lena", "look": 8,
		"party": [{ "id": "fernkit", "level": 9 }, { "id": "dewling", "level": 9 }],
		"reward": 3,
		"intro": ["The Echowood is my home turf.", "Prove you belong here!"],
		"win_line": "The forest smiles on you. Well done.",
	})
	add_trainer(Vector2i(7, 6), "down", {
		"id": "r2_rival", "name": "Rival Sabo", "look": 5,
		"party": [{ "id": "duskling", "level": 10 }, { "id": "cindboth", "level": 10 }, { "id": "zephyr", "level": 11 }],
		"reward": 5,
		"intro": ["So YOU'RE the trainer everyone's talking about.", "Let's find out if the hype is real!"],
		"win_line": "...Not bad. This won't be our last battle.",
	})

	# GRASS GYM — seals the pass to the Scorch Desert until defeated.
	add_interact(Vector2i(5, 2), { "type": "sign", "text": "MEADOW TRIAL - Ranger Fern guards the desert pass. Earn her Sigil to cross!" })
	add_gym_gate({
		"id": "gym_grass", "name": "Ranger Fern", "look": 1,
		"party": [{ "id": "fernkit", "level": 12 }, { "id": "thornvine", "level": 13 }, { "id": "bramblor", "level": 14 }],
		"reward": 4,
		"reward_items": { "fishing_rod": 1 },
		"gym": true,
		"intro": ["I am Fern, Meadow Route Ranger.", "None cross to the desert without proving your resonance!"],
		"win_line": "The meadow yields to you. Take this rod — the desert oasis rewards patient fishers.",
	}, Vector2i(3, 1), "down", [Vector2i(3, 0), Vector2i(4, 0)], Vector2i(2, 2), [Vector2i(4, 1)])


func _on_map_step(cell: Vector2i) -> void:
	if bool(GameState.flags.get("faction_ambush_route2", false)):
		return
	if cell != Vector2i(8, 14) and cell != Vector2i(9, 14):
		return
	_trigger_faction_ambush()


func _trigger_faction_ambush() -> void:
	if _cutscene or _busy or player == null:
		return

	var pc: Vector2i = player.cell
	var surround := _ambush_surround_cells(pc)
	var spawns := _ambush_spawn_cells(pc)

	var actor_defs := [
		{ "look": 9, "spawn": spawns[0], "surround": surround[0] },
		{ "look": 8, "spawn": spawns[1], "surround": surround[1] },
		{ "look": 4, "spawn": spawns[2], "surround": surround[2] },
	]

	play_ambush_surround(actor_defs, [
		"Shadows move between the trees...",
		"Three figures step onto the path — emblems of the Veil, the Rangers, and the Archive.",
		"\"You carry too much resonance for one keeper,\" one warns.",
		"\"Prove your strength, or turn back.\"",
	], _start_ambush_chain)


func _ambush_surround_cells(pc: Vector2i) -> Array:
	var order := [
		pc + Vector2i(-1, 0),
		pc + Vector2i(1, 0),
		pc + Vector2i(0, -1),
		pc + Vector2i(0, 1),
		pc + Vector2i(-1, -1),
		pc + Vector2i(1, -1),
	]
	var out: Array = []
	for c in order:
		if out.size() >= 3:
			break
		if c == pc or is_blocked(c):
			continue
		if c in out:
			continue
		out.append(c)
	while out.size() < 3:
		var offset := Vector2i(-1, 0) if out.size() == 0 else Vector2i(1, 0) if out.size() == 1 else Vector2i(0, -1)
		out.append(pc + offset)
	return out.slice(0, 3)


func _ambush_spawn_cells(pc: Vector2i) -> Array:
	return [
		_pick_spawn(pc + Vector2i(-5, 0), pc + Vector2i(-1, 0)),
		_pick_spawn(pc + Vector2i(5, 0), pc + Vector2i(1, 0)),
		_pick_spawn(pc + Vector2i(0, -5), pc + Vector2i(0, -1)),
	]


func _pick_spawn(preferred: Vector2i, fallback: Vector2i) -> Vector2i:
	if not is_blocked(preferred):
		return preferred
	return fallback + Vector2i(0, -2) if not is_blocked(fallback + Vector2i(0, -2)) else fallback


func _start_ambush_chain() -> void:
	var chain := [
		{
			"id": "faction_veil", "name": "Veil Agent", "look": 9,
			"party": [{ "id": "duskling", "level": 10 }, { "id": "shadelet", "level": 11 }],
			"reward": 2,
			"intro": ["The Veil tests every rising keeper.", "Your Harmons will tell us if you listen to the Fracture."],
			"win_line": "Hmm. You fight with conviction.",
		},
		{
			"id": "faction_ranger", "name": "Ranger Scout", "look": 8,
			"party": [{ "id": "fernkit", "level": 11 }, { "id": "dewling", "level": 11 }],
			"reward": 2,
			"intro": ["Route Rangers guard the valley's balance.", "Show me you can protect your team!"],
			"win_line": "Steady command. The routes respect you.",
		},
		{
			"id": "faction_archive", "name": "Archive Hunter", "look": 4,
			"party": [{ "id": "cindboth", "level": 11 }, { "id": "zephyr", "level": 12 }],
			"reward": 3,
			"intro": ["The Memory Archive records every battle.", "We will see what your Harmons remember."],
			"win_line": "Logged. Your story grows louder.",
		},
	]
	SceneRouter.start_ambush_chain(chain, "route2")
