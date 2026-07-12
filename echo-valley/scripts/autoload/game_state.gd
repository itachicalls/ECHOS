extends Node

signal party_changed

const PlayerAvatarScript := preload("res://scripts/core/player_avatar.gd")

const STARTERS := ["emberkit", "tideling", "mossling"]

var player_name: String = "Floki"
var player_avatar: String = "keeper"
var party: Array[EchoInstance] = []
var pc_box: Array[EchoInstance] = []
var inventory: Dictionary = { "echo_capsule": 3, "heart_salve": 2 }
var flags: Dictionary = { "starter_chosen": false, "intro_seen": false }
var seen: Dictionary = {}
var caught: Dictionary = {}

var current_map: String = "town"
var player_cell: Vector2i = Vector2i(0, 0)
var player_facing: String = "down"
var play_mode: String = "solo"


func has_starter() -> bool:
	return bool(flags.get("starter_chosen", false)) and party.size() > 0


func set_player_identity(name: String, avatar_id: String) -> void:
	player_avatar = PlayerAvatarScript.normalize_id(avatar_id)
	player_name = PlayerAvatarScript.sanitize_name(name, player_avatar)


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


func move_to_box(e: EchoInstance) -> bool:
	# Send a party member to storage. Never allow an empty party.
	if e == null or not party.has(e):
		return false
	if party.size() <= 1:
		return false
	party.erase(e)
	pc_box.append(e)
	party_changed.emit()
	EventBus.party_changed.emit()
	return true


func move_to_party(e: EchoInstance) -> bool:
	# Pull a stored Echo into the active party if there's room.
	if e == null or not pc_box.has(e):
		return false
	if party.size() >= EchoTypes.PARTY_SIZE:
		return false
	pc_box.erase(e)
	party.append(e)
	party_changed.emit()
	EventBus.party_changed.emit()
	return true


func set_party_lead(e: EchoInstance) -> bool:
	if e == null or not party.has(e):
		return false
	if party[0] == e:
		return false
	party.erase(e)
	party.insert(0, e)
	party_changed.emit()
	EventBus.party_changed.emit()
	return true


func party_lead() -> EchoInstance:
	return party[0] if party.size() > 0 else null


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
		"player_name": player_name,
		"player_avatar": player_avatar,
		"party": pd, "pc_box": bd,
		"inventory": inventory.duplicate(true), "flags": flags.duplicate(true),
		"seen": seen.duplicate(true), "caught": caught.duplicate(true),
		"current_map": current_map,
		"player_cell": { "x": player_cell.x, "y": player_cell.y },
		"player_facing": player_facing, "play_mode": play_mode,
	}


func from_dict(data: Dictionary) -> void:
	player_name = PlayerAvatarScript.sanitize_name(String(data.get("player_name", "Floki")), String(data.get("player_avatar", "keeper")))
	player_avatar = PlayerAvatarScript.normalize_id(String(data.get("player_avatar", "keeper")))
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
