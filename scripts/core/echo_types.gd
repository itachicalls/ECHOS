## Echoheart core enums and shared constants.
class_name EchoTypes
extends RefCounted

enum Resonance {
	EMBER,
	TIDE,
	VERDANT,
	SPARK,
	STONE,
	GUST,
	SHADE,
	LUMEN,
	FROST,
}

enum Temperament {
	BOLD,
	GENTLE,
	CURIOUS,
	PLAYFUL,
	STOIC,
	MISCHIEVOUS,
}

enum StatusEffect {
	NONE,
	GLOWBURN,
	DRENCH,
	ROOTED,
	STATIC,
	DROWSY,
	FOCUSED,
}

enum BattleActionType {
	CHIME,
	SWITCH,
	FLEE,
	ITEM,
}

const RESONANCE_NAMES := {
	Resonance.EMBER: "Ember",
	Resonance.TIDE: "Tide",
	Resonance.VERDANT: "Verdant",
	Resonance.SPARK: "Spark",
	Resonance.STONE: "Stone",
	Resonance.GUST: "Gust",
	Resonance.SHADE: "Shade",
	Resonance.LUMEN: "Lumen",
	Resonance.FROST: "Frost",
}

const RESONANCE_COLORS := {
	Resonance.EMBER: Color("e76f51"),
	Resonance.TIDE: Color("4cc9f0"),
	Resonance.VERDANT: Color("2a9d8f"),
	Resonance.SPARK: Color("ffd166"),
	Resonance.STONE: Color("8d99ae"),
	Resonance.GUST: Color("a8dadc"),
	Resonance.SHADE: Color("7b2cbf"),
	Resonance.LUMEN: Color("fefae0"),
	Resonance.FROST: Color("90e0ef"),
}

## Attacker -> list of resonances they are strong against.
const TYPE_ADVANTAGE := {
	Resonance.EMBER: [Resonance.VERDANT, Resonance.FROST],
	Resonance.TIDE: [Resonance.EMBER, Resonance.STONE],
	Resonance.VERDANT: [Resonance.TIDE, Resonance.STONE],
	Resonance.SPARK: [Resonance.TIDE, Resonance.GUST],
	Resonance.STONE: [Resonance.SPARK, Resonance.GUST],
	Resonance.GUST: [Resonance.VERDANT, Resonance.EMBER],
	Resonance.SHADE: [Resonance.GUST, Resonance.SPARK],
	Resonance.LUMEN: [Resonance.SHADE, Resonance.FROST],
	Resonance.FROST: [Resonance.VERDANT, Resonance.GUST],
}

const ADVANTAGE_MULT := 1.5
const DISADVANTAGE_MULT := 0.66
const PARTY_SIZE := 3
const MAX_LEVEL := 50


static func resonance_from_string(value: String) -> Resonance:
	match value.to_lower():
		"ember":
			return Resonance.EMBER
		"tide":
			return Resonance.TIDE
		"verdant":
			return Resonance.VERDANT
		"spark":
			return Resonance.SPARK
		"stone":
			return Resonance.STONE
		"gust":
			return Resonance.GUST
		"shade":
			return Resonance.SHADE
		"lumen":
			return Resonance.LUMEN
		"frost":
			return Resonance.FROST
		_:
			push_warning("Unknown resonance: %s" % value)
			return Resonance.LUMEN


static func temperament_from_string(value: String) -> Temperament:
	match value.to_lower():
		"bold":
			return Temperament.BOLD
		"gentle":
			return Temperament.GENTLE
		"curious":
			return Temperament.CURIOUS
		"playful":
			return Temperament.PLAYFUL
		"stoic":
			return Temperament.STOIC
		"mischievous":
			return Temperament.MISCHIEVOUS
		_:
			return Temperament.CURIOUS


static func type_multiplier(attacker: Resonance, defender: Resonance) -> float:
	var strong: Array = TYPE_ADVANTAGE.get(attacker, [])
	if defender in strong:
		return ADVANTAGE_MULT
	var defender_strong: Array = TYPE_ADVANTAGE.get(defender, [])
	if attacker in defender_strong:
		return DISADVANTAGE_MULT
	return 1.0


static func xp_to_next_level(level: int) -> int:
	return int(round(20.0 * pow(level, 1.35)))
