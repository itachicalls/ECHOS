extends Node

## Lightweight side-quest catalog. Quests complete via talk / flag / caught / item.

var quests: Array = []
var _by_id: Dictionary = {}


func _ready() -> void:
	_load()


func _load() -> void:
	var f := FileAccess.open("res://data/quests.json", FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	quests = parsed.get("quests", [])
	_by_id.clear()
	for q in quests:
		_by_id[String(q.get("id", ""))] = q


func get_quest(id: String) -> Dictionary:
	return _by_id.get(id, {})


func is_complete(id: String) -> bool:
	var q := get_quest(id)
	if q.is_empty():
		return false
	return bool(GameState.flags.get(String(q.get("complete_flag", "")), false))


func is_available(id: String) -> bool:
	var q := get_quest(id)
	if q.is_empty() or is_complete(id):
		return false
	var req := String(q.get("require_flag", ""))
	if req != "" and not bool(GameState.flags.get(req, false)):
		return false
	return true


func active_quests() -> Array:
	var out: Array = []
	for q in quests:
		var id := String(q.get("id", ""))
		if is_available(id) or is_complete(id):
			out.append(q)
	return out


func incomplete_active() -> Array:
	var out: Array = []
	for q in quests:
		var id := String(q.get("id", ""))
		if is_available(id):
			out.append(q)
	return out


func completed_count() -> int:
	var n := 0
	for q in quests:
		if is_complete(String(q.get("id", ""))):
			n += 1
	return n


func can_complete(id: String) -> bool:
	if not is_available(id):
		return false
	var q := get_quest(id)
	var cond: Dictionary = q.get("complete", { "type": "talk" })
	match String(cond.get("type", "talk")):
		"talk":
			return true
		"flag":
			return bool(GameState.flags.get(String(cond.get("id", "")), false))
		"caught":
			return bool(GameState.caught.get(String(cond.get("id", "")), false))
		"item":
			return ItemCatalog.has_item(String(cond.get("id", "")), int(cond.get("amount", 1)))
		_:
			return true


func complete(id: String) -> bool:
	if not can_complete(id):
		return false
	var q := get_quest(id)
	var cond: Dictionary = q.get("complete", {})
	if String(cond.get("type", "")) == "item" and bool(cond.get("consume", false)):
		if not ItemCatalog.consume_item(String(cond.get("id", "")), int(cond.get("amount", 1))):
			return false
	var flag := String(q.get("complete_flag", ""))
	if flag != "":
		GameState.flags[flag] = true
	var reward: Dictionary = q.get("reward", {})
	for k in reward.keys():
		ItemCatalog.add_item(String(k), int(reward[k]))
	SaveService.save_game()
	EventBus.toast.emit("Quest complete: %s" % String(q.get("title", id)))
	return true
