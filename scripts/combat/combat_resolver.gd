class_name CombatResolver
extends RefCounted

## Pure battle rules. No nodes, no UI — safe for tests and future netcode.


static func build_opening_state(player_party: Array, enemy_party: Array) -> Dictionary:
	return {
		"player": _side_from_party(player_party),
		"enemy": _side_from_party(enemy_party),
		"turn": 1,
		"log": [],
		"finished": false,
		"winner": "",
	}


static func resolve_turn(state: Dictionary, player_action: Dictionary, enemy_action: Dictionary) -> Dictionary:
	var next: Dictionary = _deep_copy(state)
	if next.get("finished", false):
		return next

	var events: Array = []
	var order := _action_order(next, player_action, enemy_action)
	for entry in order:
		if next.get("finished", false):
			break
		var side: String = entry.side
		var action: Dictionary = entry.action
		events.append_array(_resolve_action(next, side, action))
		_check_finished(next, events)

	next["turn"] = int(next.get("turn", 1)) + 1
	next["log"] = events
	return next


static func award_xp(state: Dictionary, base_xp: int = 35) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if state.get("winner", "") != "player":
		return events
	var enemy_side: Dictionary = state.enemy
	var defeated := 0
	for unit in enemy_side.units:
		if int(unit.current_hp) <= 0:
			defeated += 1
	var total_xp := base_xp * maxi(1, defeated)
	var player_side: Dictionary = state.player
	var living := 0
	for unit in player_side.units:
		if int(unit.current_hp) > 0:
			living += 1
	living = maxi(1, living)
	var share := int(ceil(float(total_xp) / float(living)))
	for unit in player_side.units:
		if int(unit.current_hp) <= 0:
			continue
		events.append({
			"type": "xp",
			"instance_id": unit.instance_id,
			"amount": share,
		})
	return events


static func _side_from_party(party: Array) -> Dictionary:
	var units: Array = []
	var active := -1
	for echo in party:
		if echo == null:
			continue
		var unit := {
			"instance_id": echo.instance_id,
			"definition_id": echo.definition_id,
			"name": echo.display_name(),
			"level": echo.level,
			"max_hp": echo.max_hp(),
			"current_hp": echo.current_hp,
			"power": echo.power(),
			"guard": echo.guard(),
			"swift": echo.swift(),
			"resonance": int(echo.get_definition().resonance) if echo.get_definition() else 0,
			"status": int(echo.status),
			"chimes": [],
		}
		for chime in echo.get_chimes():
			unit.chimes.append({
				"id": chime.id,
				"name": chime.name,
				"resonance": int(chime.resonance),
				"power": chime.power,
				"accuracy": chime.accuracy,
				"description": chime.description,
			})
		units.append(unit)
		if active < 0 and echo.current_hp > 0:
			active = units.size() - 1
	if active < 0 and units.size() > 0:
		active = 0
	return {"units": units, "active": active}


static func _action_order(state: Dictionary, player_action: Dictionary, enemy_action: Dictionary) -> Array:
	var player_unit: Dictionary = _active_unit(state, "player")
	var enemy_unit: Dictionary = _active_unit(state, "enemy")
	var player_priority := 1 if int(player_action.get("type", 0)) == EchoTypes.BattleActionType.SWITCH else 0
	var enemy_priority := 1 if int(enemy_action.get("type", 0)) == EchoTypes.BattleActionType.SWITCH else 0
	var player_entry := {"side": "player", "action": player_action, "priority": player_priority, "swift": int(player_unit.get("swift", 0))}
	var enemy_entry := {"side": "enemy", "action": enemy_action, "priority": enemy_priority, "swift": int(enemy_unit.get("swift", 0))}
	if player_priority != enemy_priority:
		return [player_entry, enemy_entry] if player_priority > enemy_priority else [enemy_entry, player_entry]
	if int(player_unit.get("swift", 0)) >= int(enemy_unit.get("swift", 0)):
		return [player_entry, enemy_entry]
	return [enemy_entry, player_entry]


static func _resolve_action(state: Dictionary, side: String, action: Dictionary) -> Array:
	var events: Array = []
	var action_type := int(action.get("type", EchoTypes.BattleActionType.CHIME))
	match action_type:
		EchoTypes.BattleActionType.SWITCH:
			events.append_array(_resolve_switch(state, side, int(action.get("index", 0))))
		EchoTypes.BattleActionType.FLEE:
			if side == "player":
				var chance := 0.55
				if randf() < chance:
					state.finished = true
					state.winner = "flee"
					events.append({"type": "flee_success", "side": side})
				else:
					events.append({"type": "flee_fail", "side": side})
		_:
			events.append_array(_resolve_chime(state, side, String(action.get("chime_id", ""))))
	return events


static func _resolve_switch(state: Dictionary, side: String, index: int) -> Array:
	var events: Array = []
	var side_data: Dictionary = state[side]
	if index < 0 or index >= side_data.units.size():
		events.append({"type": "message", "text": "Switch failed."})
		return events
	var unit: Dictionary = side_data.units[index]
	if int(unit.current_hp) <= 0:
		events.append({"type": "message", "text": "%s is too weary." % unit.name})
		return events
	if index == int(side_data.active):
		events.append({"type": "message", "text": "%s is already out." % unit.name})
		return events
	side_data.active = index
	events.append({"type": "switch", "side": side, "index": index, "name": unit.name})
	return events


static func _resolve_chime(state: Dictionary, side: String, chime_id: String) -> Array:
	var events: Array = []
	var attacker: Dictionary = _active_unit(state, side)
	if int(attacker.current_hp) <= 0:
		return events
	var foe_side := "enemy" if side == "player" else "player"
	var defender: Dictionary = _active_unit(state, foe_side)
	if int(defender.current_hp) <= 0:
		return events

	var chime := _find_chime(attacker, chime_id)
	if chime.is_empty():
		# Fallback to first chime.
		if attacker.chimes.is_empty():
			return events
		chime = attacker.chimes[0]

	if randf() > float(chime.get("accuracy", 1.0)):
		events.append({
			"type": "miss",
			"side": side,
			"actor": attacker.name,
			"chime": chime.name,
		})
		return events

	var atk_res := int(chime.get("resonance", attacker.resonance)) as EchoTypes.Resonance
	var def_res := int(defender.resonance) as EchoTypes.Resonance
	var mult := EchoTypes.type_multiplier(atk_res, def_res)
	var raw := (float(attacker.power) * float(chime.power)) / maxf(1.0, float(defender.guard) * 1.8)
	var damage := maxi(1, int(round(raw * mult * randf_range(0.9, 1.1))))
	defender.current_hp = maxi(0, int(defender.current_hp) - damage)
	events.append({
		"type": "damage",
		"side": side,
		"actor": attacker.name,
		"target": defender.name,
		"chime": chime.name,
		"damage": damage,
		"multiplier": mult,
		"target_hp": defender.current_hp,
		"target_max_hp": defender.max_hp,
	})
	if int(defender.current_hp) <= 0:
		events.append({"type": "faint", "side": foe_side, "name": defender.name})
		_auto_switch_if_needed(state, foe_side, events)
	return events


static func _auto_switch_if_needed(state: Dictionary, side: String, events: Array) -> void:
	var side_data: Dictionary = state[side]
	var active: Dictionary = side_data.units[side_data.active]
	if int(active.current_hp) > 0:
		return
	for i in side_data.units.size():
		if int(side_data.units[i].current_hp) > 0:
			side_data.active = i
			events.append({"type": "switch", "side": side, "index": i, "name": side_data.units[i].name, "auto": true})
			return


static func _check_finished(state: Dictionary, events: Array) -> void:
	if _side_all_fainted(state.player):
		state.finished = true
		state.winner = "enemy"
		events.append({"type": "battle_end", "winner": "enemy"})
	elif _side_all_fainted(state.enemy):
		state.finished = true
		state.winner = "player"
		events.append({"type": "battle_end", "winner": "player"})


static func _side_all_fainted(side_data: Dictionary) -> bool:
	for unit in side_data.units:
		if int(unit.current_hp) > 0:
			return false
	return true


static func _active_unit(state: Dictionary, side: String) -> Dictionary:
	var side_data: Dictionary = state[side]
	return side_data.units[side_data.active]


static func _find_chime(unit: Dictionary, chime_id: String) -> Dictionary:
	for chime in unit.chimes:
		if String(chime.id) == chime_id:
			return chime
	return {}


static func _deep_copy(value: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(value))
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}
