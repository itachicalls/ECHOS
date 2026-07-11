class_name EchoDatabase
extends RefCounted

static var instance: EchoDatabase

var echoes: Dictionary = {}
var chimes: Dictionary = {}


func has_echo(id: String) -> bool: return echoes.has(id)
func get_echo(id: String) -> EchoDefinition: return echoes.get(id) as EchoDefinition
func get_chime(id: String) -> ChimeDefinition: return chimes.get(id) as ChimeDefinition


func all_echo_ids() -> Array[String]:
	var ids: Array[String] = []
	for k in echoes.keys():
		ids.append(String(k))
	ids.sort()
	return ids


func create_instance(definition_id: String, level: int = 5) -> EchoInstance:
	if not has_echo(definition_id):
		push_error("Unknown echo: %s" % definition_id)
		return null
	return EchoInstance.new(definition_id, level)


func load_from_res() -> void:
	chimes.clear()
	echoes.clear()
	var cdata: Variant = _read("res://data/chimes.json")
	if typeof(cdata) == TYPE_ARRAY:
		for entry: Variant in cdata:
			var c := ChimeDefinition.from_dict(entry as Dictionary)
			chimes[c.id] = c
	var edata: Variant = _read("res://data/echoes.json")
	if typeof(edata) == TYPE_ARRAY:
		for entry: Variant in edata:
			var e := EchoDefinition.from_dict(entry as Dictionary)
			echoes[e.id] = e


func _read(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Missing %s" % path)
		return null
	return JSON.parse_string(f.get_as_text())
