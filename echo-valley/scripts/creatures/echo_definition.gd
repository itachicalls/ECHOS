class_name EchoDefinition
extends RefCounted

const MAX_MOVES := 4

var id: String = ""
var name: String = ""
var resonance: EchoTypes.Resonance = EchoTypes.Resonance.NONE
var base_stats: Dictionary = { "hp": 40, "power": 40, "guard": 40, "swift": 40 }
var learnset: Array = []          # [{ "level": int, "chime": String }, ...]
var evolve_to: String = ""
var evolve_level: int = 0
var catch_rate: float = 0.3
var sprite_path: String = ""
var sprite_back_path: String = ""
var description: String = ""


static func from_dict(data: Dictionary) -> EchoDefinition:
	var d := EchoDefinition.new()
	d.id = String(data.get("id", ""))
	d.name = String(data.get("name", d.id.capitalize()))
	d.resonance = EchoTypes.resonance_from_string(String(data.get("resonance", "none")))
	var stats: Dictionary = data.get("base_stats", {})
	for k in d.base_stats.keys():
		if stats.has(k):
			d.base_stats[k] = int(stats[k])
	d.learnset.clear()
	if data.has("learnset"):
		for entry in data.get("learnset", []):
			d.learnset.append({ "level": int(entry.get("level", 1)), "chime": String(entry.get("chime", "")) })
	else:
		# legacy: a plain "chimes" list learned at level 1
		for cid in data.get("chimes", []):
			d.learnset.append({ "level": 1, "chime": String(cid) })
	d.evolve_to = String(data.get("evolve_to", ""))
	d.evolve_level = int(data.get("evolve_level", 0))
	d.catch_rate = float(data.get("catch_rate", 0.3))
	d.sprite_path = String(data.get("sprite", ""))
	d.sprite_back_path = String(data.get("sprite_back", ""))
	if d.sprite_back_path == "" and d.sprite_path.ends_with(".png"):
		var back := d.sprite_path.substr(0, d.sprite_path.length() - 4) + "_back.png"
		if ResourceLoader.exists(back):
			d.sprite_back_path = back
	if d.sprite_back_path == "":
		d.sprite_back_path = d.sprite_path
	d.description = String(data.get("description", ""))
	return d


## Move ids known at a given level = the last MAX_MOVES learned (by level order).
func moves_at_level(level: int) -> Array[String]:
	var learned: Array[String] = []
	for entry in learnset:
		if int(entry.level) <= level:
			var cid := String(entry.chime)
			if cid != "" and cid not in learned:
				learned.append(cid)
	if learned.size() > MAX_MOVES:
		learned = learned.slice(learned.size() - MAX_MOVES)
	return learned


## Move ids taught exactly at this level (for level-up learning).
func moves_learned_at(level: int) -> Array[String]:
	var out: Array[String] = []
	for entry in learnset:
		if int(entry.level) == level:
			out.append(String(entry.chime))
	return out
