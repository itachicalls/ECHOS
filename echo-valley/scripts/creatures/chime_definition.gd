class_name ChimeDefinition
extends RefCounted

var id: String = ""
var name: String = ""
var resonance: EchoTypes.Resonance = EchoTypes.Resonance.NONE
var category: String = "attack"  # "attack" | "heal" | "buff"
var power: int = 40
var accuracy: float = 1.0
var priority: int = 0
var heal_pct: float = 0.0
var lifesteal: float = 0.0
var stat: String = ""            # buff target: "power" | "guard" | "swift"
var stages: int = 0
var description: String = ""


static func from_dict(data: Dictionary) -> ChimeDefinition:
	var c := ChimeDefinition.new()
	c.id = String(data.get("id", ""))
	c.name = String(data.get("name", c.id.capitalize()))
	c.resonance = EchoTypes.resonance_from_string(String(data.get("resonance", "none")))
	c.category = String(data.get("category", "attack"))
	c.power = int(data.get("power", 40))
	c.accuracy = float(data.get("accuracy", 1.0))
	c.priority = int(data.get("priority", 0))
	c.heal_pct = float(data.get("heal_pct", 0.0))
	c.lifesteal = float(data.get("lifesteal", 0.0))
	c.stat = String(data.get("stat", ""))
	c.stages = int(data.get("stages", 0))
	c.description = String(data.get("description", ""))
	return c
