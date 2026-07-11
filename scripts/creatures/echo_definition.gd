class_name EchoDefinition
extends RefCounted

var id: String = ""
var name: String = ""
var resonance: EchoTypes.Resonance = EchoTypes.Resonance.LUMEN
var temperament: EchoTypes.Temperament = EchoTypes.Temperament.CURIOUS
var base_stats: Dictionary = {
	"hp": 40,
	"power": 40,
	"guard": 40,
	"swift": 40,
	"bond": 40,
}
var chime_ids: Array[String] = []
var evolve_to: String = ""
var evolve_level: int = 0
var catch_rate: float = 0.3
var description: String = ""
var mesh_scene: String = ""
var color: Color = Color.WHITE


static func from_dict(data: Dictionary) -> EchoDefinition:
	var def := EchoDefinition.new()
	def.id = String(data.get("id", ""))
	def.name = String(data.get("name", def.id.capitalize()))
	def.resonance = EchoTypes.resonance_from_string(String(data.get("resonance", "lumen")))
	def.temperament = EchoTypes.temperament_from_string(String(data.get("temperament", "curious")))
	var stats: Dictionary = data.get("base_stats", {})
	for key in def.base_stats.keys():
		if stats.has(key):
			def.base_stats[key] = int(stats[key])
	def.chime_ids.clear()
	for chime_id in data.get("chimes", []):
		def.chime_ids.append(String(chime_id))
	def.evolve_to = String(data.get("evolve_to", ""))
	def.evolve_level = int(data.get("evolve_level", 0))
	def.catch_rate = float(data.get("catch_rate", 0.3))
	def.description = String(data.get("description", ""))
	def.mesh_scene = String(data.get("mesh", ""))
	if data.has("color"):
		def.color = Color(String(data.get("color")))
	else:
		def.color = EchoTypes.RESONANCE_COLORS[def.resonance]
	return def
