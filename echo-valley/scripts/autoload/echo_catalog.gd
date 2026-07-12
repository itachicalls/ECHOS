extends Node


func _ready() -> void:
	reload()


func reload() -> void:
	var db := EchoDatabase.new()
	db.load_from_res()
	EchoDatabase.instance = db
	print("%s: loaded %d %s, %d chimes" % [GameStrings.GAME_NAME, db.echoes.size(), GameStrings.CREATURE_PLURAL_LOWER, db.chimes.size()])


func has_echo(id: String) -> bool: return EchoDatabase.instance.has_echo(id)
func get_echo(id: String) -> EchoDefinition: return EchoDatabase.instance.get_echo(id)
func get_chime(id: String) -> ChimeDefinition: return EchoDatabase.instance.get_chime(id)
func all_echo_ids() -> Array[String]: return EchoDatabase.instance.all_echo_ids()
func create_instance(id: String, level: int = 5) -> EchoInstance: return EchoDatabase.instance.create_instance(id, level)


func water_echo_ids() -> Array[String]:
	var out: Array[String] = []
	for id in all_echo_ids():
		var def := get_echo(id)
		if def and int(def.resonance) == EchoTypes.Resonance.WATER:
			out.append(id)
	return out


func random_water_echo_id() -> String:
	var pool := water_echo_ids()
	if pool.is_empty():
		return "dewling"
	return pool[randi() % pool.size()]
