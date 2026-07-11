extends Node

signal party_changed

const STARTERS := ["emberkit", "tideling", "mossling"]

var player_name: String = "Ash"
var party: Array[EchoInstance] = []
var pc_box: Array[EchoInstance] = []
var inventory: Dictionary = { "echo_capsule": 8, "heart_salve": 4 }
var flags: Dictionary = { "starter_chosen": false, "intro_seen": false }
var seen: Dictionary = {}
var caught: Dictionary = {}

var current_map: String = "town"
var player_cell: Vector2i = Vector2i(0, 0)
var player_facing: String = "down"
var play_mode: String = "solo"


func has_starter() -> bool:
	return bool(flags.get("starter_chosen", false)) and party.size() > 0


func choose_starter(id: String) -> bool:
	if has_starter() or id not in STARTERS:
		return false
	var e := EchoCatalog.create_instance(id, 5)
	if e == null:
		return false
	party.clear()
	party.append(e)
	flags["starter_chosen"] = true
	mark_caught(id)
	party_changed.emit()
	EventBus.party_changed.emit()
	return true


func living_party() -> Array[EchoInstance]:
	var out: Array[EchoInstance] = []
	for e in party:
		if e and not e.is_fainted():
			out.append(e)
	return out


func heal_party() -> void:
	for e in party:
		if e:
			e.heal_full()
	party_changed.emit()
	EventBus.party_changed.emit()


func add_echo(e: EchoInstance) -> bool:
	if e == null:
		return false
	if party.size() < EchoTypes.PARTY_SIZE:
		party.append(e)
	else:
		pc_box.append(e)
	mark_caught(e.definition_id)
	party_changed.emit()
	EventBus.party_changed.emit()
	return true


func mark_seen(id: String) -> void: seen[id] = true
func mark_caught(id: String) -> void:
	seen[id] = true
	caught[id] = true


func sync_from_battle(units: Array) -> void:
	for u in units:
		var iid := String(u.get("instance_id", ""))
		for e in party:
			if e.instance_id == iid:
				e.current_hp = int(u.get("current_hp", e.current_hp))
				break
	party_changed.emit()
	EventBus.party_changed.emit()


func apply_xp(events: Array) -> Array[Dictionary]:
	var growth: Array[Dictionary] = []
	for ev in events:
		if String(ev.get("type", "")) != "xp":
			continue
		var iid := String(ev.get("instance_id", ""))
		for e in party:
			if e.instance_id == iid:
				growth.append_array(e.gain_xp(int(ev.get("amount", 0))))
				break
	if not growth.is_empty():
		party_changed.emit()
		EventBus.party_changed.emit()
	return growth


func to_dict() -> Dictionary:
	var pd: Array = []
	for e in party: pd.append(e.to_dict())
	var bd: Array = []
	for e in pc_box: bd.append(e.to_dict())
	return {
		"player_name": player_name, "party": pd, "pc_box": bd,
		"inventory": inventory.duplicate(true), "flags": flags.duplicate(true),
		"seen": seen.duplicate(true), "caught": caught.duplicate(true),
		"current_map": current_map,
		"player_cell": { "x": player_cell.x, "y": player_cell.y },
		"player_facing": player_facing, "play_mode": play_mode,
	}


func from_dict(data: Dictionary) -> void:
	player_name = String(data.get("player_name", "Ash"))
	inventory = data.get("inventory", inventory).duplicate(true)
	if inventory.has("echo_charm") and not inventory.has("echo_capsule"):
		inventory["echo_capsule"] = int(inventory.get("echo_charm", 0))
		inventory.erase("echo_charm")
	flags = data.get("flags", flags).duplicate(true)
	seen = data.get("seen", {}).duplicate(true)
	caught = data.get("caught", {}).duplicate(true)
	current_map = String(data.get("current_map", "town"))
	var pc: Dictionary = data.get("player_cell", {})
	player_cell = Vector2i(int(pc.get("x", 0)), int(pc.get("y", 0)))
	player_facing = String(data.get("player_facing", "down"))
	play_mode = String(data.get("play_mode", "solo"))
	party.clear()
	for entry in data.get("party", []):
		party.append(EchoInstance.from_dict(entry))
	pc_box.clear()
	for entry in data.get("pc_box", []):
		pc_box.append(EchoInstance.from_dict(entry))
	party_changed.emit()
	EventBus.party_changed.emit()
