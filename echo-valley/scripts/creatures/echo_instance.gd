class_name EchoInstance
extends RefCounted

var instance_id: String = ""
var definition_id: String = ""
var nickname: String = ""
var level: int = 5
var xp: int = 0
var current_hp: int = 1
var affinity: Dictionary = { "hp": 1.0, "power": 1.0, "guard": 1.0, "swift": 1.0 }
var moves: Array[String] = []


func _init(p_definition_id: String = "", p_level: int = 5) -> void:
	instance_id = "e%d_%d" % [Time.get_ticks_usec(), randi() % 100000]
	definition_id = p_definition_id
	level = clampi(p_level, 1, EchoTypes.MAX_LEVEL)
	for k in affinity.keys():
		affinity[k] = randf_range(0.92, 1.08)
	_init_moves()
	current_hp = max_hp()


func _init_moves() -> void:
	var d := get_definition()
	if d:
		moves = d.moves_at_level(level)
	if moves.is_empty():
		moves = ["tackle"]


func _learn_move(chime_id: String) -> void:
	if chime_id == "" or chime_id in moves:
		return
	moves.append(chime_id)
	if moves.size() > EchoDefinition.MAX_MOVES:
		moves.remove_at(0)


func get_definition() -> EchoDefinition:
	if EchoDatabase.instance == null:
		return null
	return EchoDatabase.instance.get_echo(definition_id)


func display_name() -> String:
	if nickname != "":
		return nickname
	var d := get_definition()
	return d.name if d else definition_id


func _stat(name: String) -> int:
	var d := get_definition()
	if d == null:
		return 1
	var base := int(d.base_stats.get(name, 40))
	var growth := 1.0 + (level - 1) * 0.09
	return maxi(1, int(round(base * growth * float(affinity.get(name, 1.0)))))


func max_hp() -> int: return _stat("hp")
func power() -> int: return _stat("power")
func guard() -> int: return _stat("guard")
func swift() -> int: return _stat("swift")
func is_fainted() -> bool: return current_hp <= 0


func heal_full() -> void:
	current_hp = max_hp()


func get_chimes() -> Array[ChimeDefinition]:
	var result: Array[ChimeDefinition] = []
	if EchoDatabase.instance == null:
		return result
	if moves.is_empty():
		_init_moves()
	for cid in moves:
		var c := EchoDatabase.instance.get_chime(cid)
		if c:
			result.append(c)
	return result


func gain_xp(amount: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if amount <= 0:
		return events
	xp += amount
	while level < EchoTypes.MAX_LEVEL and xp >= EchoTypes.xp_to_next(level):
		xp -= EchoTypes.xp_to_next(level)
		level += 1
		var before := max_hp()
		var ratio := 1.0 if before <= 0 else float(current_hp) / float(before)
		current_hp = clampi(int(round(max_hp() * ratio)), (1 if current_hp > 0 else 0), max_hp())
		events.append({ "type": "level_up", "level": level, "name": display_name() })
		var d := get_definition()
		if d:
			for cid in d.moves_learned_at(level):
				if cid not in moves:
					_learn_move(cid)
					var mv := EchoDatabase.instance.get_chime(cid) if EchoDatabase.instance else null
					events.append({ "type": "learn", "name": display_name(), "move": (mv.name if mv else cid) })
		var evo := try_evolve()
		if not evo.is_empty():
			events.append(evo)
	return events


func try_evolve() -> Dictionary:
	var d := get_definition()
	if d == null or d.evolve_to == "" or d.evolve_level <= 0 or level < d.evolve_level:
		return {}
	if EchoDatabase.instance == null or not EchoDatabase.instance.has_echo(d.evolve_to):
		return {}
	var old := display_name()
	var old_id := definition_id
	var ratio := 1.0 if max_hp() <= 0 else float(current_hp) / float(max_hp())
	definition_id = d.evolve_to
	current_hp = clampi(int(round(max_hp() * ratio)), 1, max_hp())
	# learn any signature moves the evolved form knows from the start
	var nd := get_definition()
	if nd:
		for cid in nd.moves_at_level(level):
			if moves.size() < EchoDefinition.MAX_MOVES and cid not in moves:
				_learn_move(cid)
	return { "type": "evolve", "from": old, "to": display_name(), "from_id": old_id, "to_id": definition_id }


func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id, "definition_id": definition_id, "nickname": nickname,
		"level": level, "xp": xp, "current_hp": current_hp, "affinity": affinity.duplicate(),
		"moves": moves.duplicate(),
	}


static func from_dict(data: Dictionary) -> EchoInstance:
	var e := EchoInstance.new(String(data.get("definition_id", "")), int(data.get("level", 5)))
	e.instance_id = String(data.get("instance_id", e.instance_id))
	e.nickname = String(data.get("nickname", ""))
	e.xp = int(data.get("xp", 0))
	var aff: Dictionary = data.get("affinity", {})
	for k in e.affinity.keys():
		if aff.has(k):
			e.affinity[k] = float(aff[k])
	var saved_moves: Array = data.get("moves", [])
	if not saved_moves.is_empty():
		e.moves.clear()
		for m in saved_moves:
			e.moves.append(String(m))
	e.current_hp = clampi(int(data.get("current_hp", e.max_hp())), 0, e.max_hp())
	return e
