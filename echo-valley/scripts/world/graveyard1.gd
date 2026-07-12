extends "res://scripts/world/overworld.gd"

## THE HOLLOW BARROWS (Graveyard Route) — where the Fracture never healed. Shadow
## Harmons haunt the tombs, the factions make their final stand, and a sealed
## Primordial dreams beneath the barrow-mound. The deepest reach of the expansion.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "graveyard1"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.CAVE_FLOOR)

	# crumbling wall border with a south gap (Dream Reach)
	for x in map_w:
		if x != 9 and x != 10:
			place_rock(Vector2i(x, 0))
			place_rock(Vector2i(x, map_h - 1))
	for y in range(1, map_h - 1):
		place_rock(Vector2i(0, y))
		place_rock(Vector2i(map_w - 1, y))

	# cobbled processional path
	for y in range(1, map_h):
		set_ground(Vector2i(9, y), Tiles.STONE)
		set_ground(Vector2i(10, y), Tiles.STONE)
	for x in range(2, 18):
		set_ground(Vector2i(x, 14), Tiles.STONE)

	add_warp(Vector2i(9, 23), "psychic1", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "psychic1", Vector2i(10, 1), "down")

	# rows of tombstones
	for p in [Vector2i(3, 5), Vector2i(5, 5), Vector2i(7, 5), Vector2i(13, 5), Vector2i(15, 5), Vector2i(17, 5),
			Vector2i(3, 9), Vector2i(5, 9), Vector2i(15, 9), Vector2i(17, 9),
			Vector2i(4, 18), Vector2i(6, 18), Vector2i(14, 18), Vector2i(16, 18)]:
		add_ground_prop(Tiles.TOMBSTONE, p, true)

	# grave-mist encounter dens
	_den(2, 6, 7, 12)
	_den(12, 6, 17, 12)
	_den(3, 16, 8, 21)
	_den(12, 16, 17, 21)

	# the barrow-mound altar at the north end
	set_ground(Vector2i(9, 3), Tiles.CAVE_ALTAR)
	set_ground(Vector2i(10, 3), Tiles.CAVE_ALTAR)

	# The sealed Primordial — a static, catchable finale encounter.
	add_legend_encounter(Vector2i(9, 4), "primordius", 48,
		"The barrow-mound splits. From the deepest Fracture-scar rises PRIMORDIUS, the dream older than the Chorus. Reality shudders - it acknowledges you at last!")

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "THE HOLLOW BARROWS - here the Fracture bleeds still. Shadow-Harmons keep the dead company." })
	add_interact(Vector2i(11, 5), { "type": "sign", "text": "\"Beneath this mound sleeps the first resonance. Wake it, and the valley changes forever.\"" })

	add_trainer(Vector2i(5, 12), "right", {
		"id": "grave_mourn", "name": "Warden Mourn", "look": 13,
		"party": [{ "id": "tombkin", "level": 38 }, { "id": "wispire", "level": 39 }],
		"reward": 6,
		"intro": ["Few keepers walk out of the Barrows.", "Let the tombs judge your resolve!"],
		"win_line": "The dead grant you passage. Impressive.",
	})
	add_trainer(Vector2i(13, 16), "left", {
		"id": "grave_yew", "name": "Gravekeeper Yew", "look": 16,
		"party": [{ "id": "boneling", "level": 39 }, { "id": "gravemoss", "level": 40 }, { "id": "candleflit", "level": 41 }],
		"reward": 7,
		"intro": ["I tend what the Fracture left behind.", "Prove you respect the resting - in battle!"],
		"win_line": "Rest easy, they whisper. You've earned their peace.",
	}, 5)


func _place_pickups() -> void:
	add_pickup(Vector2i(3, 20), "echo_capsule", 5)
	add_pickup(Vector2i(16, 6), "heart_salve", 4)


func _den(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			var c := Vector2i(x, y)
			if not is_blocked(c) and not warps.has(c):
				set_ground(c, Tiles.CAVE_FLOOR2)
				grass[c] = true


# --- climactic faction ambush: the factions' final stand ---
func _on_map_step(cell: Vector2i) -> void:
	if bool(GameState.flags.get("faction_ambush_graveyard", false)):
		return
	if cell != Vector2i(9, 14) and cell != Vector2i(10, 14):
		return
	_trigger_grave_ambush()


func _trigger_grave_ambush() -> void:
	if _cutscene or _busy or player == null:
		return
	var pc: Vector2i = player.cell
	var actor_defs := [
		{ "look": 9, "spawn": pc + Vector2i(-4, 0), "surround": pc + Vector2i(-1, 0) },
		{ "look": 12, "spawn": pc + Vector2i(4, 0), "surround": pc + Vector2i(1, 0) },
		{ "look": 4, "spawn": pc + Vector2i(0, 4), "surround": pc + Vector2i(0, 1) },
	]
	play_ambush_surround(actor_defs, [
		"Cold light spills across the tombs. The three factions block the processional.",
		"\"This is where it ends, keeper. Beyond you lies a Primordial we've guarded for an age.\"",
		"\"The Veil would wake it. The Rangers would seal it. The Archive would only watch.\"",
		"\"But all of us agree: only the strongest may decide. Face us - all of us!\"",
	], _start_grave_ambush)


func _start_grave_ambush() -> void:
	var chain := [
		{
			"id": "faction_veil_final", "name": "Veil Oracle", "look": 9,
			"party": [{ "id": "cryptid", "level": 40 }, { "id": "shroudmoth", "level": 41 }, { "id": "banshee", "level": 42 }],
			"reward": 8,
			"intro": ["The Veil has waited a long time for one like you.", "Wake the dream with us - or be swept aside!"],
			"win_line": "Then perhaps the dream chose wrongly... or perfectly.",
		},
		{
			"id": "faction_ranger_final", "name": "Ranger Marshal", "look": 12,
			"party": [{ "id": "amperewolf", "level": 41 }, { "id": "mesmind", "level": 42 }, { "id": "reaperwing", "level": 43 }],
			"reward": 8,
			"intro": ["Every Ranger of the valley stands behind me.", "If you'd hold this power, you'll answer to all of us!"],
			"win_line": "...The routes were right to fear you. And to hope in you.",
		},
		{
			"id": "faction_archive_final", "name": "Archive Primarch", "look": 4,
			"party": [{ "id": "sarcolord", "level": 43 }, { "id": "hypnaura", "level": 44 }, { "id": "grimsovereign", "level": 45 }],
			"reward": 12,
			"intro": ["The Archive has recorded every keeper who came before.", "None reached this tomb. Let us write your final chapter!"],
			"win_line": "It is written, then. The Primordial is yours to face.",
		},
	]
	SceneRouter.start_ambush_chain(chain, "graveyard1", "faction_ambush_graveyard")
