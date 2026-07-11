extends SceneTree

## Headless smoke test: DB load, instances, leveling/evolution, full battle.


func _init() -> void:
	var db := EchoDatabase.new()
	db.load_from_res()
	EchoDatabase.instance = db
	print("Echoes: %d  Chimes: %d" % [db.echoes.size(), db.chimes.size()])
	assert(db.echoes.size() >= 6)
	assert(db.chimes.size() >= 10)

	var starter := db.create_instance("emberkit", 11)
	print("Starter: %s Lv%d HP=%d PWR=%d moves=%s" % [starter.display_name(), starter.level, starter.max_hp(), starter.power(), str(starter.moves)])
	var events := starter.gain_xp(EchoTypes.xp_to_next(11) + 5)
	print("XP events: ", events)
	print("After XP: %s Lv%d" % [starter.display_name(), starter.level])

	# evolution + learnset: level a fresh emberkit up to 16 -> Flarefox
	var evo := db.create_instance("emberkit", 15)
	var big_xp := 0
	for lv in range(15, 17):
		big_xp += EchoTypes.xp_to_next(lv) + 1
	var evo_events := evo.gain_xp(big_xp)
	var did_evolve := false
	var did_learn := false
	for e in evo_events:
		if String(e.get("type", "")) == "evolve": did_evolve = true
		if String(e.get("type", "")) == "learn": did_learn = true
	print("Evolve line: now=%s (evolved=%s, learned_something=%s) moves=%s" % [evo.display_name(), did_evolve, did_learn, str(evo.moves)])
	assert(did_evolve)
	assert(evo.moves.size() <= 4)

	# buff move path: pebblit knows Harden at Lv5
	var rock := db.create_instance("pebblit", 6)
	var foe := db.create_instance("mossling", 6)
	var bstate := CombatResolver.build_state([rock], [foe])
	var before_guard := int(bstate.player.units[0].stages.get("guard", 0))
	bstate = CombatResolver.resolve_turn(bstate, { "type": EchoTypes.ActionType.CHIME, "chime_id": "harden" }, { "type": EchoTypes.ActionType.WAIT })
	var after_guard := int(bstate.player.units[0].stages.get("guard", 0))
	print("Harden guard stage: %d -> %d" % [before_guard, after_guard])
	assert(after_guard > before_guard)

	var player := [db.create_instance("emberkit", 10), db.create_instance("tideling", 9)]
	var enemy := [db.create_instance("mossling", 9)]
	var state := CombatResolver.build_state(player, enemy)
	var turns := 0
	while not state.get("finished", false) and turns < 40:
		_auto_bench_if_needed(state)
		var pa := { "type": EchoTypes.ActionType.CHIME, "chime_id": state.player.units[state.player.active].chimes[0].id }
		var ea := { "type": EchoTypes.ActionType.CHIME, "chime_id": state.enemy.units[state.enemy.active].chimes[0].id }
		state = CombatResolver.resolve_turn(state, pa, ea)
		_auto_bench_if_needed(state)
		turns += 1
	print("Battle finished in %d turns. Winner=%s" % [turns, state.get("winner", "?")])
	assert(state.get("finished", false))
	var xp := CombatResolver.award_xp(state)
	print("Awarded XP events: ", xp.size())

	# type advantage sanity
	var m := EchoTypes.type_multiplier(EchoTypes.Resonance.WATER, EchoTypes.Resonance.FIRE)
	print("Water vs Fire mult = %.2f" % m)
	assert(m > 1.0)

	print("SMOKE OK")
	quit(0)


func _auto_bench_if_needed(state: Dictionary) -> void:
	var sd: Dictionary = state.player
	if int(sd.units[sd.active].current_hp) > 0:
		return
	for i in sd.units.size():
		if int(sd.units[i].current_hp) > 0:
			sd.active = i
			return
