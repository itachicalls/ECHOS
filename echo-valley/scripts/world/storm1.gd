extends "res://scripts/world/overworld.gd"

## VOLTMARSH (the Telectric Route) — a storm-wracked wetland crackling with static.
## Air-attuned Harmons roam here, and the Fracture factions make a second, bolder
## stand against the rising keeper. A Storm Ranger seals the pass to Mirage Hollow.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "storm1"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.GRASS)

	# marsh water pools
	for c in [Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 7), Vector2i(15, 15), Vector2i(16, 15), Vector2i(15, 16), Vector2i(4, 17), Vector2i(5, 17)]:
		set_ground(c, Tiles.WATER)
		block(c)

	# tree border with south (Cove) and north (Mirage) gaps
	for x in map_w:
		if x != 9 and x != 10:
			place_tree(Vector2i(x, 0), Tiles.TREE_GREEN_COL)
			place_tree(Vector2i(x, map_h - 1), Tiles.TREE_GREEN_COL)
	for y in range(1, map_h - 1):
		place_tree(Vector2i(0, y), Tiles.TREE_GREEN_COL)
		place_tree(Vector2i(map_w - 1, y), Tiles.TREE_GREEN_COL)

	# winding path south -> north
	for y in range(0, map_h):
		set_ground(Vector2i(9, y), Tiles.PATH)
		set_ground(Vector2i(10, y), Tiles.PATH)
	for x in range(3, 17):
		set_ground(Vector2i(x, 13), Tiles.PATH)

	add_warp(Vector2i(9, 23), "tide_town", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "tide_town", Vector2i(10, 1), "down")
	add_warp(Vector2i(9, 0), "psychic_town", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "psychic_town", Vector2i(10, 22), "up")

	# crackling crystal pylons
	for p in [Vector2i(4, 4), Vector2i(15, 5), Vector2i(6, 20), Vector2i(14, 19), Vector2i(3, 12)]:
		add_ground_prop(Tiles.CRYSTAL, p, true)

	# tall-grass encounter fens
	_grass_patch(2, 15, 8, 20)
	_grass_patch(12, 15, 17, 20)
	_grass_patch(3, 3, 8, 10)
	_grass_patch(12, 3, 16, 11)

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "VOLTMARSH - the air bites with static. Storm Harmons nest in the fens." })
	add_interact(Vector2i(8, 13), { "type": "sign", "text": "DANGER: charged ground ahead. The Storm Ranger tests all who seek Mirage Hollow." })

	add_trainer(Vector2i(6, 17), "right", {
		"id": "storm_kade", "name": "Marsh Runner Kade", "look": 11,
		"party": [{ "id": "sparklit", "level": 17 }, { "id": "wattpup", "level": 18 }],
		"reward": 4,
		"intro": ["You feel that hum? That's power, friend.", "Let's discharge some of it!"],
		"win_line": "Zapped fair and square. Respect.",
	})
	add_trainer(Vector2i(14, 6), "down", {
		"id": "storm_vera", "name": "Sky-Watcher Vera", "look": 17,
		"party": [{ "id": "buzzfly", "level": 18 }, { "id": "kiteon", "level": 19 }],
		"reward": 4,
		"intro": ["I read the storm fronts for a living.", "Your team's looking like a clear forecast - let's fix that!"],
		"win_line": "Skies clear. You've earned the pass ahead.",
	}, 5)

	# STORM GYM — seals the pass north to Mirage Hollow.
	add_interact(Vector2i(11, 1), { "type": "sign", "text": "STORM TRIAL - Ranger Bolt guards Mirage Hollow. Earn the Charge Sigil to cross." })
	add_gym_gate({
		"id": "gym_storm", "name": "Ranger Bolt", "look": 11,
		"party": [{ "id": "voltwing", "level": 20 }, { "id": "amperewolf", "level": 21 }, { "id": "stormraptor", "level": 22 }],
		"reward": 5,
		"reward_items": { "echo_capsule": 5 },
		"gym": true, "ranger": true,
		"intro": ["I am Bolt, Storm Route Ranger.", "The marsh answers only to those who master its current. Show me!"],
		"win_line": "The storm bows to you. Mirage Hollow awaits beyond the pass.",
	}, Vector2i(9, 1), "down", [Vector2i(9, 0), Vector2i(10, 0)], Vector2i(7, 1), [Vector2i(10, 1)])


func _place_pickups() -> void:
	add_pickup(Vector2i(3, 18), "heart_salve", 2)
	add_pickup(Vector2i(16, 4), "echo_capsule", 3)


func _grass_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)) and not warps.has(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y))


# --- story-tied faction ambush (second, bolder stand) ---
func _on_map_step(cell: Vector2i) -> void:
	if bool(GameState.flags.get("faction_ambush_storm1", false)):
		return
	if cell != Vector2i(9, 13) and cell != Vector2i(10, 13):
		return
	_trigger_storm_ambush()


func _trigger_storm_ambush() -> void:
	if _cutscene or _busy or player == null:
		return
	var pc: Vector2i = player.cell
	var actor_defs := [
		{ "look": 9, "spawn": pc + Vector2i(-4, 0), "surround": pc + Vector2i(-1, 0) },
		{ "look": 12, "spawn": pc + Vector2i(4, 0), "surround": pc + Vector2i(1, 0) },
		{ "look": 4, "spawn": pc + Vector2i(0, -4), "surround": pc + Vector2i(0, -1) },
	]
	play_ambush_surround(actor_defs, [
		"The static thickens - and three figures step from the reeds.",
		"The Veil, the Rangers, and the Archive have followed you to the coast.",
		"\"You've grown too loud, keeper. The Fracture stirs around you.\"",
		"\"This time we won't hold back. Prove the valley can trust you!\"",
	], _start_storm_ambush)


func _start_storm_ambush() -> void:
	var chain := [
		{
			"id": "faction_veil2", "name": "Veil Adept", "look": 9,
			"party": [{ "id": "ghastling", "level": 18 }, { "id": "willowick", "level": 19 }],
			"reward": 4,
			"intro": ["The Veil remembers our last meeting.", "You listen to the Fracture better than most - dangerously so."],
			"win_line": "So the resonance truly answers you...",
		},
		{
			"id": "faction_ranger2", "name": "Ranger Captain", "look": 12,
			"party": [{ "id": "voltwing", "level": 19 }, { "id": "mistkoi", "level": 19 }],
			"reward": 4,
			"intro": ["The Rangers guard the balance of every route.", "Convince us you protect, not shatter!"],
			"win_line": "Command like that keeps the valley whole.",
		},
		{
			"id": "faction_archive2", "name": "Archive Warden", "look": 4,
			"party": [{ "id": "sparklit", "level": 19 }, { "id": "psybud", "level": 20 }],
			"reward": 6,
			"intro": ["The Archive has recorded your every step.", "Let us see the ending your Harmons are writing."],
			"win_line": "Logged, and remembered. The coast is yours to explore.",
		},
	]
	SceneRouter.start_ambush_chain(chain, "storm1", "faction_ambush_storm1")
