class_name EchoInstance
extends RefCounted

signal hp_changed(current: int, maximum: int)
signal leveled_up(new_level: int)
signal evolved(new_definition_id: String)

var instance_id: String = ""
var definition_id: String = ""
var nickname: String = ""
var level: int = 5
var xp: int = 0
var current_hp: int = 1
var status: EchoTypes.StatusEffect = EchoTypes.StatusEffect.NONE
## Soft individuality (0.9–1.1) applied to stats.
var affinity: Dictionary = {
	"hp": 1.0,
	"power": 1.0,
	"guard": 1.0,
	"swift": 1.0,
	"bond": 1.0,
}


func _init(p_definition_id: String = "", p_level: int = 5) -> void:
	instance_id = _make_id()
	definition_id = p_definition_id
	level = clampi(p_level, 1, EchoTypes.MAX_LEVEL)
	_roll_affinity()
	current_hp = max_hp()


func get_definition() -> EchoDefinition:
	if EchoDatabase.instance == null:
		return null
	return EchoDatabase.instance.get_echo(definition_id)


func display_name() -> String:
	if nickname != "":
		return nickname
	var def := get_definition()
	return def.name if def else definition_id


func max_hp() -> int:
	return _stat("hp")


func power() -> int:
	return _stat("power")


func guard() -> int:
	return _stat("guard")


func swift() -> int:
	return _stat("swift")


func bond() -> int:
	return _stat("bond")


func is_fainted() -> bool:
	return current_hp <= 0


func heal_full() -> void:
	current_hp = max_hp()
	status = EchoTypes.StatusEffect.NONE
	hp_changed.emit(current_hp, max_hp())


func apply_damage(amount: int) -> int:
	var dealt := mini(amount, current_hp)
	current_hp = maxi(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp())
	return dealt


func gain_xp(amount: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if amount <= 0:
		return events
	xp += amount
	while level < EchoTypes.MAX_LEVEL and xp >= EchoTypes.xp_to_next_level(level):
		xp -= EchoTypes.xp_to_next_level(level)
		level += 1
		var hp_before := max_hp()
		# Recalc max HP via level bump; keep relative health.
		var ratio := 1.0 if hp_before <= 0 else float(current_hp) / float(hp_before)
		current_hp = clampi(int(round(max_hp() * ratio)), 1 if current_hp > 0 else 0, max_hp())
		leveled_up.emit(level)
		events.append({"type": "level_up", "level": level, "name": display_name()})
		var evolved_event := try_evolve()
		if not evolved_event.is_empty():
			events.append(evolved_event)
	return events


func try_evolve() -> Dictionary:
	var def := get_definition()
	if def == null:
		return {}
	if def.evolve_to == "" or def.evolve_level <= 0:
		return {}
	if level < def.evolve_level:
		return {}
	if not EchoDatabase.instance or not EchoDatabase.instance.has_echo(def.evolve_to):
		return {}
	var old_name := display_name()
	var ratio := 1.0 if max_hp() <= 0 else float(current_hp) / float(max_hp())
	definition_id = def.evolve_to
	current_hp = clampi(int(round(max_hp() * ratio)), 1 if current_hp > 0 else 0, max_hp())
	evolved.emit(definition_id)
	return {"type": "evolve", "from": old_name, "to": display_name(), "definition_id": definition_id}


func get_chimes() -> Array[ChimeDefinition]:
	var result: Array[ChimeDefinition] = []
	var def := get_definition()
	if def == null or EchoDatabase.instance == null:
		return result
	for chime_id in def.chime_ids:
		var chime := EchoDatabase.instance.get_chime(chime_id)
		if chime:
			result.append(chime)
	return result


func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"nickname": nickname,
		"level": level,
		"xp": xp,
		"current_hp": current_hp,
		"status": int(status),
		"affinity": affinity.duplicate(),
	}


static func from_dict(data: Dictionary) -> EchoInstance:
	var echo := EchoInstance.new(String(data.get("definition_id", "")), int(data.get("level", 5)))
	echo.instance_id = String(data.get("instance_id", echo.instance_id))
	echo.nickname = String(data.get("nickname", ""))
	echo.xp = int(data.get("xp", 0))
	echo.status = int(data.get("status", 0)) as EchoTypes.StatusEffect
	var saved_affinity: Dictionary = data.get("affinity", {})
	for key in echo.affinity.keys():
		if saved_affinity.has(key):
			echo.affinity[key] = float(saved_affinity[key])
	echo.current_hp = int(data.get("current_hp", echo.max_hp()))
	echo.current_hp = clampi(echo.current_hp, 0, echo.max_hp())
	return echo


func _stat(stat_name: String) -> int:
	var def := get_definition()
	if def == null:
		return 1
	var base := int(def.base_stats.get(stat_name, 40))
	var growth := 1.0 + (level - 1) * 0.08
	var value := base * growth * float(affinity.get(stat_name, 1.0))
	return maxi(1, int(round(value)))


func _roll_affinity() -> void:
	for key in affinity.keys():
		affinity[key] = randf_range(0.92, 1.08)


func _make_id() -> String:
	return "echo_%d_%d" % [Time.get_unix_time_from_system(), randi()]
