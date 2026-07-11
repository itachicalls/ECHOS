class_name ChimeDefinition
extends RefCounted

var id: String = ""
var name: String = ""
var resonance: EchoTypes.Resonance = EchoTypes.Resonance.LUMEN
var power: int = 40
var accuracy: float = 1.0
var description: String = ""
var status: EchoTypes.StatusEffect = EchoTypes.StatusEffect.NONE
var status_chance: float = 0.0


static func from_dict(data: Dictionary) -> ChimeDefinition:
	var chime := ChimeDefinition.new()
	chime.id = String(data.get("id", ""))
	chime.name = String(data.get("name", chime.id.capitalize()))
	chime.resonance = EchoTypes.resonance_from_string(String(data.get("resonance", "lumen")))
	chime.power = int(data.get("power", 40))
	chime.accuracy = float(data.get("accuracy", 1.0))
	chime.description = String(data.get("description", ""))
	var status_name := String(data.get("status", "none")).to_lower()
	match status_name:
		"glowburn":
			chime.status = EchoTypes.StatusEffect.GLOWBURN
		"drench":
			chime.status = EchoTypes.StatusEffect.DRENCH
		"rooted":
			chime.status = EchoTypes.StatusEffect.ROOTED
		"static":
			chime.status = EchoTypes.StatusEffect.STATIC
		"drowsy":
			chime.status = EchoTypes.StatusEffect.DROWSY
		"focused":
			chime.status = EchoTypes.StatusEffect.FOCUSED
		_:
			chime.status = EchoTypes.StatusEffect.NONE
	chime.status_chance = float(data.get("status_chance", 0.0))
	return chime
