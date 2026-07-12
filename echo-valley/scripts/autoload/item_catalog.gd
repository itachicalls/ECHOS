extends Node

## Central item definitions and inventory helpers.

var _defs: Dictionary = {}


func _ready() -> void:
	_load()


func _load() -> void:
	var f := FileAccess.open("res://data/items.json", FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_defs = parsed


func has(id: String) -> bool:
	return _defs.has(id)


func get_def(id: String) -> Dictionary:
	return _defs.get(id, {})


func display_name(id: String) -> String:
	return String(get_def(id).get("name", id.capitalize()))


func description(id: String) -> String:
	return String(get_def(id).get("desc", ""))


func is_key_item(id: String) -> bool:
	return bool(get_def(id).get("key_item", false))


func usable_in_battle(id: String) -> bool:
	return bool(get_def(id).get("battle", false))


func usable_in_field(id: String) -> bool:
	return bool(get_def(id).get("field", false))


func starter_inventory() -> Dictionary:
	return { "echo_capsule": 3, "heart_salve": 2 }


func add_item(id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	GameState.inventory[id] = int(GameState.inventory.get(id, 0)) + amount


func consume_item(id: String, amount: int = 1) -> bool:
	var n := int(GameState.inventory.get(id, 0))
	if n < amount:
		return false
	n -= amount
	if n <= 0:
		GameState.inventory.erase(id)
	else:
		GameState.inventory[id] = n
	return true


func has_item(id: String, amount: int = 1) -> bool:
	return int(GameState.inventory.get(id, 0)) >= amount
