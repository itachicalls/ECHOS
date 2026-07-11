extends Node


func _ready() -> void:
	reload()


func reload() -> void:
	var db := EchoDatabase.new()
	db.load_from_res()
	EchoDatabase.instance = db
	print("Echo Valley: loaded %d echoes, %d chimes" % [db.echoes.size(), db.chimes.size()])


func has_echo(id: String) -> bool: return EchoDatabase.instance.has_echo(id)
func get_echo(id: String) -> EchoDefinition: return EchoDatabase.instance.get_echo(id)
func get_chime(id: String) -> ChimeDefinition: return EchoDatabase.instance.get_chime(id)
func all_echo_ids() -> Array[String]: return EchoDatabase.instance.all_echo_ids()
func create_instance(id: String, level: int = 5) -> EchoInstance: return EchoDatabase.instance.create_instance(id, level)
