class_name EchoTypes
extends RefCounted

enum Resonance { NONE, FIRE, WATER, GRASS, ROCK, AIR, SHADOW }
enum ActionType { CHIME, SWITCH, CATCH, FLEE, WAIT }

const RESONANCE_NAMES := {
	Resonance.NONE: "Normal",
	Resonance.FIRE: "Fire",
	Resonance.WATER: "Water",
	Resonance.GRASS: "Grass",
	Resonance.ROCK: "Rock",
	Resonance.AIR: "Air",
	Resonance.SHADOW: "Shadow",
}

const RESONANCE_COLORS := {
	Resonance.NONE: Color("cbd5e1"),
	Resonance.FIRE: Color("e76f51"),
	Resonance.WATER: Color("4cc9f0"),
	Resonance.GRASS: Color("52b788"),
	Resonance.ROCK: Color("8d99ae"),
	Resonance.AIR: Color("a8dadc"),
	Resonance.SHADOW: Color("7b2cbf"),
}

## attacker -> resonances it is strong against (1.5x)
const ADVANTAGE := {
	Resonance.FIRE: [Resonance.GRASS],
	Resonance.WATER: [Resonance.FIRE, Resonance.ROCK],
	Resonance.GRASS: [Resonance.WATER, Resonance.ROCK],
	Resonance.ROCK: [Resonance.AIR, Resonance.FIRE],
	Resonance.AIR: [Resonance.GRASS],
	Resonance.SHADOW: [Resonance.AIR],
}

const RESONANCE_SYMBOLS := {
	Resonance.NONE: "○",
	Resonance.FIRE: "▲",
	Resonance.WATER: "▼",
	Resonance.GRASS: "✿",
	Resonance.ROCK: "■",
	Resonance.AIR: "◆",
	Resonance.SHADOW: "★",
}

const RESONANCE_GLYPHS := {
	Resonance.NONE: "N",
	Resonance.FIRE: "F",
	Resonance.WATER: "W",
	Resonance.GRASS: "G",
	Resonance.ROCK: "R",
	Resonance.AIR: "A",
	Resonance.SHADOW: "S",
}

const ADV_MULT := 1.5
const DIS_MULT := 0.66
const PARTY_SIZE := 6
const MAX_LEVEL := 50


static func resonance_from_string(v: String) -> Resonance:
	match v.to_lower():
		"fire": return Resonance.FIRE
		"water": return Resonance.WATER
		"grass": return Resonance.GRASS
		"rock": return Resonance.ROCK
		"air": return Resonance.AIR
		"shadow": return Resonance.SHADOW
		_: return Resonance.NONE


static func type_multiplier(atk: Resonance, def: Resonance) -> float:
	if atk == Resonance.NONE:
		return 1.0
	var strong: Array = ADVANTAGE.get(atk, [])
	if def in strong:
		return ADV_MULT
	var def_strong: Array = ADVANTAGE.get(def, [])
	if atk in def_strong:
		return DIS_MULT
	return 1.0


static func xp_to_next(level: int) -> int:
	# Gentle early curve — quick first levels, slower growth later.
	var lv := maxi(1, level)
	return int(max(12, round(5.0 * pow(float(lv), 1.22) + 3.5 * float(lv) + 8.0)))
