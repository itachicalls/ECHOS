extends Node

signal party_changed
signal inventory_changed
signal flags_changed
signal starter_chosen(definition_id: String)

const STARTERS := ["emberkit", "tideling", "mossprite"]

var player_name: String = "Traveler"
var party: Array[EchoInstance] = []
var inventory: Dictionary = {
	"resonance_charm": 5,
	"heart_salve": 3,
}
var flags: Dictionary = {
	"starter_chosen": false,
	"intro_seen": false,
}
var current_zone: String = "hearthmere"
var player_position: Vector3 = Vector3(0, 0.5, 0)
var player_yaw: float = 0.0
var encounter_steps: int = 0
var play_mode: String = "solo"  # solo | coop | versus


func _ready() -> void:
	pass


func has_starter() -> bool:
	return bool(flags.get("starter_chosen", false)) and party.size() > 0


func choose_starter(definition_id: String) -> bool:
	if has_starter():
		return false
	if definition_id not in STARTERS:
		return false
	var echo := EchoCatalog.create_instance(definition_id, 5)
	if echo == null:
		return false
	party.clear()
	party.append(echo)
	flags["starter_chosen"] = true
	flags_changed.emit()
	party_changed.emit()
	starter_chosen.emit(definition_id)
	EventBus.toast.emit("Your heart resonates with %s!" % echo.display_name())
	return true


func get_living_party() -> Array[EchoInstance]:
	var living: Array[EchoInstance] = []
	for echo in party:
		if echo and not echo.is_fainted():
			living.append(echo)
	return living


func heal_party() -> void:
	for echo in party:
		if echo:
			echo.heal_full()
	party_changed.emit()


func add_echo(echo: EchoInstance) -> void:
	if echo == null:
		return
	if party.size() < EchoTypes.PARTY_SIZE:
		party.append(echo)
	else:
		# M1: overflow ignored with toast; box comes later.
		EventBus.toast.emit("Party full — %s watches from afar for now." % echo.display_name())
		return
	party_changed.emit()


func sync_party_from_battle(side_units: Array) -> void:
	for unit in side_units:
		var instance_id := String(unit.get("instance_id", ""))
		for echo in party:
			if echo.instance_id == instance_id:
				echo.current_hp = int(unit.get("current_hp", echo.current_hp))
				echo.status = int(unit.get("status", echo.status)) as EchoTypes.StatusEffect
				break
	party_changed.emit()


func apply_xp_events(events: Array) -> Array[Dictionary]:
	var growth: Array[Dictionary] = []
	for event in events:
		if String(event.get("type", "")) != "xp":
			continue
		var instance_id := String(event.get("instance_id", ""))
		var amount := int(event.get("amount", 0))
		for echo in party:
			if echo.instance_id == instance_id:
				growth.append_array(echo.gain_xp(amount))
				break
	if not growth.is_empty():
		party_changed.emit()
	return growth


func set_flag(key: String, value: Variant) -> void:
	flags[key] = value
	flags_changed.emit()


func to_dict() -> Dictionary:
	var party_data: Array = []
	for echo in party:
		party_data.append(echo.to_dict())
	return {
		"player_name": player_name,
		"party": party_data,
		"inventory": inventory.duplicate(true),
		"flags": flags.duplicate(true),
		"current_zone": current_zone,
		"player_position": {"x": player_position.x, "y": player_position.y, "z": player_position.z},
		"player_yaw": player_yaw,
		"encounter_steps": encounter_steps,
		"play_mode": play_mode,
	}


func from_dict(data: Dictionary) -> void:
	player_name = String(data.get("player_name", "Traveler"))
	inventory = data.get("inventory", inventory).duplicate(true)
	flags = data.get("flags", flags).duplicate(true)
	current_zone = String(data.get("current_zone", "hearthmere"))
	var pos: Dictionary = data.get("player_position", {})
	player_position = Vector3(float(pos.get("x", 0)), float(pos.get("y", 0.5)), float(pos.get("z", 0)))
	player_yaw = float(data.get("player_yaw", 0))
	encounter_steps = int(data.get("encounter_steps", 0))
	play_mode = String(data.get("play_mode", "solo"))
	party.clear()
	for entry in data.get("party", []):
		party.append(EchoInstance.from_dict(entry))
	party_changed.emit()
	flags_changed.emit()
	inventory_changed.emit()
