class_name CombatResolver
extends RefCounted

## Pure turn-based battle rules. No nodes/UI — testable and netcode-ready.


static func build_state(player_party: Array, enemy_party: Array) -> Dictionary:
	return {
		"player": _side(player_party),
		"enemy": _side(enemy_party),
		"turn": 1,
		"finished": false,
		"winner": "",
		"log": [],
	}


static func resolve_turn(state: Dictionary, player_action: Dictionary, enemy_action: Dictionary) -> Dictionary:
	var s: Dictionary = _copy(state)
	if s.get("finished", false):
		return s
	var events: Array = []
	var order := _order(s, player_action, enemy_action)
	if order.size() >= 2:
		var first: Dictionary = order[0]
		var second: Dictionary = order[1]
		events.append({
			"type": "turn_order",
			"first_side": String(first.side),
			"first_name": String(_active(s, String(first.side)).name),
			"second_name": String(_active(s, String(second.side)).name),
			"reason": _order_reason(first, second),
		})
	for entry in order:
		if s.get("finished", false):
			break
		events.append_array(_do(s, entry.side, entry.action))
		_check_end(s, events)
	s["turn"] = int(s.turn) + 1
	s["log"] = events
	return s


static func award_xp(state: Dictionary, base: int = 58) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if state.get("winner", "") != "player":
		return out
	var defeated := 0
	for u in state.enemy.units:
		if int(u.current_hp) <= 0:
			defeated += 1
	var total := base * maxi(1, defeated)
	for u in state.player.units:
		if int(u.current_hp) > 0:
			out.append({ "type": "xp", "instance_id": u.instance_id, "amount": total })
	return out


static func _side(party: Array) -> Dictionary:
	var units: Array = []
	var active := -1
	for item in party:
		if item == null or not item is EchoInstance:
			continue
		var echo: EchoInstance = item
		var d: EchoDefinition = echo.get_definition()
		var u := {
			"instance_id": echo.instance_id,
			"definition_id": echo.definition_id,
			"name": echo.display_name(),
			"level": echo.level,
			"xp": echo.xp,
			"max_hp": echo.max_hp(),
			"current_hp": echo.current_hp,
			"power": echo.power(),
			"guard": echo.guard(),
			"swift": echo.swift(),
			"resonance": int(d.resonance) if d else 0,
			"stages": { "power": 0, "guard": 0, "swift": 0 },
			"chimes": [],
		}
		for c in echo.get_chimes():
			u.chimes.append({
				"id": c.id, "name": c.name, "resonance": int(c.resonance), "category": c.category,
				"power": c.power, "accuracy": c.accuracy, "priority": c.priority,
				"heal_pct": c.heal_pct, "lifesteal": c.lifesteal, "stat": c.stat, "stages": c.stages,
			})
		units.append(u)
		if active < 0 and echo.current_hp > 0:
			active = units.size() - 1
	if active < 0 and units.size() > 0:
		active = 0
	return { "units": units, "active": active }


static func _order(s: Dictionary, pa: Dictionary, ea: Dictionary) -> Array:
	var pu: Dictionary = _active(s, "player")
	var eu: Dictionary = _active(s, "enemy")
	var pp := _action_priority(pu, pa)
	var ep := _action_priority(eu, ea)
	var pe := { "side": "player", "action": pa, "priority": pp, "swift": _eff_swift(pu) }
	var ee := { "side": "enemy", "action": ea, "priority": ep, "swift": _eff_swift(eu) }
	if pp != ep:
		return [pe, ee] if pp > ep else [ee, pe]
	if _eff_swift(pu) >= _eff_swift(eu):
		return [pe, ee]
	return [ee, pe]


static func _order_reason(first: Dictionary, second: Dictionary) -> String:
	if int(first.priority) != int(second.priority):
		return "priority"
	return "swift"


static func _action_priority(unit: Dictionary, action: Dictionary) -> int:
	var t := int(action.get("type", 0))
	if t == EchoTypes.ActionType.SWITCH or t == EchoTypes.ActionType.FLEE:
		return 6
	if t == EchoTypes.ActionType.CHIME:
		for c in unit.get("chimes", []):
			if String(c.id) == String(action.get("chime_id", "")):
				return int(c.get("priority", 0))
	return 0


static func _stage_mult(stage: int) -> float:
	return clampf(1.0 + 0.30 * float(stage), 0.4, 2.5)


static func _eff_swift(unit: Dictionary) -> int:
	var st: Dictionary = unit.get("stages", {})
	return int(round(float(unit.get("swift", 0)) * _stage_mult(int(st.get("swift", 0)))))


static func _do(s: Dictionary, side: String, action: Dictionary) -> Array:
	var t := int(action.get("type", EchoTypes.ActionType.CHIME))
	match t:
		EchoTypes.ActionType.WAIT:
			return []
		EchoTypes.ActionType.SWITCH:
			return _switch(s, side, int(action.get("index", 0)))
		EchoTypes.ActionType.FLEE:
			if side == "player":
				if randf() < 0.6:
					s.finished = true
					s.winner = "flee"
					return [{ "type": "flee_ok" }]
				return [{ "type": "flee_fail" }]
			return []
		_:
			return _chime(s, side, String(action.get("chime_id", "")))


static func _switch(s: Dictionary, side: String, index: int) -> Array:
	var sd: Dictionary = s[side]
	if index < 0 or index >= sd.units.size():
		return [{ "type": "message", "text": "Can't switch." }]
	var u: Dictionary = sd.units[index]
	if int(u.current_hp) <= 0:
		return [{ "type": "message", "text": "%s has fainted." % u.name }]
	if index == int(sd.active):
		return [{ "type": "message", "text": "%s is already out." % u.name }]
	var out_name := String(sd.units[sd.active].name)
	var out_idx := int(sd.active)
	sd.active = index
	return [{ "type": "switch", "side": side, "name": u.name, "out_name": out_name, "out_index": out_idx, "in_index": index }]


static func _chime(s: Dictionary, side: String, chime_id: String) -> Array:
	var atk: Dictionary = _active(s, side)
	if int(atk.current_hp) <= 0:
		return []
	var foe_side := "enemy" if side == "player" else "player"
	var def: Dictionary = _active(s, foe_side)
	var chime: Dictionary = {}
	for c in atk.chimes:
		if String(c.id) == chime_id:
			chime = c
			break
	if chime.is_empty():
		if atk.chimes.is_empty():
			return []
		chime = atk.chimes[0]

	var category := String(chime.get("category", "attack"))

	# ---- heal ----
	if category == "heal":
		var heal := int(round(float(atk.max_hp) * float(chime.get("heal_pct", 0.5))))
		var actor_hp_before := int(atk.current_hp)
		atk.current_hp = mini(int(atk.max_hp), actor_hp_before + heal)
		return [{
			"type": "heal", "side": side, "actor": atk.name, "chime": chime.name,
			"amount": heal, "actor_hp_before": actor_hp_before, "actor_hp": atk.current_hp, "actor_max_hp": atk.max_hp,
		}]

	# ---- buff ----
	if category == "buff":
		var stat := String(chime.get("stat", "power"))
		var st: Dictionary = atk.get("stages", {})
		st[stat] = clampi(int(st.get(stat, 0)) + int(chime.get("stages", 1)), -6, 6)
		atk.stages = st
		return [{
			"type": "buff", "side": side, "actor": atk.name, "chime": chime.name,
			"stat": stat, "stages": int(chime.get("stages", 1)),
		}]

	# ---- attack ----
	if int(def.current_hp) <= 0:
		return []
	if randf() > float(chime.get("accuracy", 1.0)):
		return [{ "type": "miss", "side": side, "actor": atk.name, "chime": chime.name }]
	var atk_st: Dictionary = atk.get("stages", {})
	var def_st: Dictionary = def.get("stages", {})
	var mult := EchoTypes.type_multiplier(int(chime.resonance) as EchoTypes.Resonance, int(def.resonance) as EchoTypes.Resonance)
	var atk_pow := float(atk.power) * _stage_mult(int(atk_st.get("power", 0)))
	var def_grd := float(def.guard) * _stage_mult(int(def_st.get("guard", 0)))
	var raw := (atk_pow * float(chime.power)) / maxf(1.0, def_grd * 1.8)
	var dmg := maxi(1, int(round(raw * mult * randf_range(0.9, 1.1))))
	var target_idx := int(s[foe_side].active)
	var target_hp_before := int(def.current_hp)
	var actor_hp_before := int(atk.current_hp)
	def.current_hp = maxi(0, target_hp_before - dmg)
	var events := [{
		"type": "damage", "side": side, "target_side": foe_side, "target_index": target_idx,
		"actor_index": int(s[side].active),
		"actor": atk.name, "target": def.name,
		"chime": chime.name, "resonance": int(chime.resonance), "damage": dmg, "multiplier": mult,
		"target_hp_before": target_hp_before, "target_hp": def.current_hp, "target_max_hp": def.max_hp,
		"actor_hp_before": actor_hp_before, "actor_max_hp": atk.max_hp,
	}]
	var steal := float(chime.get("lifesteal", 0.0))
	if steal > 0.0 and int(atk.current_hp) > 0:
		var gain := maxi(1, int(round(float(dmg) * steal)))
		atk.current_hp = mini(int(atk.max_hp), int(atk.current_hp) + gain)
		events.append({
			"type": "drain", "side": side, "actor": atk.name, "amount": gain,
			"actor_hp_before": actor_hp_before, "actor_hp": atk.current_hp, "actor_max_hp": atk.max_hp,
		})
	if int(def.current_hp) <= 0:
		events.append({ "type": "faint", "side": foe_side, "name": def.name, "index": target_idx })
		_auto_switch(s, foe_side, events)
	return events


static func _auto_switch(s: Dictionary, side: String, events: Array) -> void:
	var sd: Dictionary = s[side]
	if int(sd.units[sd.active].current_hp) > 0:
		return
	var living: Array = []
	for i in sd.units.size():
		if int(sd.units[i].current_hp) > 0:
			living.append(i)
	if living.is_empty():
		return
	if side == "player":
		events.append({ "type": "need_switch", "side": "player" })
		return
	var out_name := String(sd.units[sd.active].name)
	var out_idx := int(sd.active)
	sd.active = living[0]
	events.append({
		"type": "switch", "side": side, "name": sd.units[living[0]].name,
		"out_name": out_name, "out_index": out_idx, "in_index": living[0], "auto": true,
	})


static func _check_end(s: Dictionary, events: Array) -> void:
	if _all_down(s.player):
		s.finished = true
		s.winner = "enemy"
		events.append({ "type": "battle_end", "winner": "enemy" })
	elif _all_down(s.enemy):
		s.finished = true
		s.winner = "player"
		events.append({ "type": "battle_end", "winner": "player" })


static func _all_down(sd: Dictionary) -> bool:
	for u in sd.units:
		if int(u.current_hp) > 0:
			return false
	return true


static func _active(s: Dictionary, side: String) -> Dictionary:
	var sd: Dictionary = s[side]
	return sd.units[sd.active]


static func _copy(v: Dictionary) -> Dictionary:
	var p: Variant = JSON.parse_string(JSON.stringify(v))
	return p if typeof(p) == TYPE_DICTIONARY else {}
