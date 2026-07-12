extends Node

## Headless smoke test: instantiate every overworld map (checks it builds + spawns
## a player) and verify each expected warp is wired to the right destination.
## Run via the normal main loop so autoloads are available:
##   godot --headless --path <proj> res://tools/test_maps.tscn

const MAPS := {
	"town": "res://scenes/world/town.tscn",
	"route1": "res://scenes/world/route1.tscn",
	"route2": "res://scenes/world/route2.tscn",
	"desert1": "res://scenes/world/desert1.tscn",
	"desert2": "res://scenes/world/desert2.tscn",
	"desert3": "res://scenes/world/desert3.tscn",
	"jungle1": "res://scenes/world/jungle1.tscn",
	"jungle2": "res://scenes/world/jungle2.tscn",
	"jungle3": "res://scenes/world/jungle3.tscn",
	"cave1": "res://scenes/world/cave1.tscn",
	"cave2": "res://scenes/world/cave2.tscn",
	"beach1": "res://scenes/world/beach1.tscn",
	"tide_town": "res://scenes/world/tide_town.tscn",
	"storm1": "res://scenes/world/storm1.tscn",
	"psychic_town": "res://scenes/world/psychic_town.tscn",
	"psychic1": "res://scenes/world/psychic1.tscn",
	"graveyard1": "res://scenes/world/graveyard1.tscn",
}

# from_map, from_cell, expected target map, expected target cell
const WARPS := [
	["route1", Vector2i(9, 0), "route2", Vector2i(8, 20)],
	["route2", Vector2i(8, 21), "route1", Vector2i(9, 1)],
	["route2", Vector2i(3, 0), "desert1", Vector2i(9, 22)],
	["desert1", Vector2i(9, 0), "desert2", Vector2i(9, 22)],
	["desert2", Vector2i(9, 0), "desert3", Vector2i(10, 22)],
	["jungle1", Vector2i(10, 0), "jungle2", Vector2i(9, 22)],
	["jungle2", Vector2i(9, 0), "jungle3", Vector2i(9, 22)],
	["town", Vector2i(0, 14), "beach1", Vector2i(18, 10)],
	["beach1", Vector2i(19, 10), "town", Vector2i(1, 14)],
	["beach1", Vector2i(9, 0), "tide_town", Vector2i(9, 22)],
	["tide_town", Vector2i(9, 23), "beach1", Vector2i(9, 1)],
	["tide_town", Vector2i(9, 0), "storm1", Vector2i(9, 22)],
	["storm1", Vector2i(9, 23), "tide_town", Vector2i(9, 1)],
	["storm1", Vector2i(9, 0), "psychic_town", Vector2i(9, 22)],
	["psychic_town", Vector2i(9, 23), "storm1", Vector2i(9, 1)],
	["psychic_town", Vector2i(9, 0), "psychic1", Vector2i(9, 22)],
	["psychic1", Vector2i(9, 23), "psychic_town", Vector2i(9, 1)],
	["psychic1", Vector2i(9, 0), "graveyard1", Vector2i(9, 22)],
	["graveyard1", Vector2i(9, 23), "psychic1", Vector2i(9, 1)],
]

var _log: PackedStringArray = PackedStringArray()


func _ready() -> void:
	_run.call_deferred()


func _say(line: String) -> void:
	_log.append(line)
	print(line)


func _finish(code: int) -> void:
	var f := FileAccess.open("res://_maptest_result.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_log) + "\n")
		f.close()
	get_tree().quit(code)


func _run() -> void:
	GameState.flags["starter_chosen"] = true
	if GameState.party.is_empty():
		var starter := EchoCatalog.create_instance("emberkit", 10)
		if starter:
			GameState.party.append(starter)

	var built: Dictionary = {}
	for map_id in MAPS.keys():
		var res := await _load_map(String(map_id))
		if res.err != "":
			_say("MAP FAIL %s: %s" % [map_id, res.err])
			_finish(1)
			return
		built[map_id] = res.warps
		_say("OK load " + String(map_id))

	for w in WARPS:
		var from_id := String(w[0])
		var from_cell: Vector2i = w[1]
		var to_id := String(w[2])
		var to_cell: Vector2i = w[3]
		var wmap: Dictionary = built.get(from_id, {})
		if not wmap.has(from_cell):
			_say("WARP FAIL %s %s: no warp at cell" % [from_id, str(from_cell)])
			_finish(1)
			return
		var dest: Dictionary = wmap[from_cell]
		if String(dest.get("map", "")) != to_id:
			_say("WARP FAIL %s %s: target %s != %s" % [from_id, str(from_cell), dest.get("map", ""), to_id])
			_finish(1)
			return
		var dcell: Vector2i = dest.get("cell", Vector2i.ZERO)
		if dcell != to_cell:
			_say("WARP FAIL %s %s: cell %s != %s" % [from_id, str(from_cell), str(dcell), str(to_cell)])
			_finish(1)
			return
		_say("OK warp %s %s -> %s %s" % [from_id, str(from_cell), to_id, str(to_cell)])

	_say("MAP TEST OK")
	_finish(0)


func _load_map(map_id: String) -> Dictionary:
	var scene: PackedScene = load(MAPS[map_id])
	if scene == null:
		return { "err": "missing scene", "warps": {} }
	var inst := scene.instantiate()
	if inst == null:
		return { "err": "instantiate failed", "warps": {} }
	get_tree().root.add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	var err := ""
	var warps: Dictionary = {}
	if not inst.get("player") or inst.player == null:
		err = "no player"
	else:
		warps = inst.warps.duplicate(true)
	inst.queue_free()
	await get_tree().process_frame
	return { "err": err, "warps": warps }
