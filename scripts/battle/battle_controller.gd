extends Node3D

const CombatResolver = preload("res://scripts/combat/combat_resolver.gd")
const EchoVisualScene = preload("res://scenes/creatures/echo_visual.tscn")

@onready var stage: Node3D = $Stage
@onready var player_slot: Marker3D = $Stage/PlayerSlot
@onready var enemy_slot: Marker3D = $Stage/EnemySlot
@onready var ui: Control = $UILayer/BattleUI

var _state: Dictionary = {}
var _request: Dictionary = {}
var _player_visual: Node3D
var _enemy_visual: Node3D
var _waiting_for_player: bool = false


func _ready() -> void:
	_request = SceneRouter.get_battle_request()
	if _request.is_empty():
		# Debug fallback
		if not GameState.has_starter():
			GameState.choose_starter("emberkit")
		_request = {
			"kind": "wild",
			"enemies": [EchoCatalog.create_instance("pebblit", 4)],
			"return_zone": "whisperwood",
			"can_flee": true,
		}
	ui.action_chosen.connect(_on_player_action)
	_begin_battle()


func _begin_battle() -> void:
	var enemies: Array = _request.get("enemies", [])
	_state = CombatResolver.build_opening_state(GameState.party, enemies)
	ui.clear_log()
	var kind := String(_request.get("kind", "wild"))
	if kind == "trainer":
		ui.append_log("%s challenged you to a battle!" % String(_request.get("trainer_name", "Rival")))
	else:
		ui.append_log("A wild Echo appeared!")
	ui.flee_button.visible = bool(_request.get("can_flee", true))
	_refresh_visuals()
	ui.refresh_units(_state)
	ui.set_busy(false)
	_waiting_for_player = true


func _on_player_action(action: Dictionary) -> void:
	if not _waiting_for_player:
		return
	_waiting_for_player = false
	ui.set_busy(true)
	var enemy_action := _choose_enemy_action()
	_state = CombatResolver.resolve_turn(_state, action, enemy_action)
	await _play_events(_state.get("log", []))
	ui.refresh_units(_state)
	_refresh_visuals()

	if _state.get("finished", false):
		await _finish_battle()
		return

	ui.set_busy(false)
	_waiting_for_player = true


func _choose_enemy_action() -> Dictionary:
	var enemy: Dictionary = _state.enemy.units[_state.enemy.active]
	if enemy.chimes.is_empty():
		return {"type": EchoTypes.BattleActionType.CHIME, "chime_id": ""}
	var chime: Dictionary = enemy.chimes[randi() % enemy.chimes.size()]
	return {"type": EchoTypes.BattleActionType.CHIME, "chime_id": String(chime.id)}


func _play_events(events: Array) -> void:
	for event in events:
		var type := String(event.get("type", ""))
		match type:
			"damage":
				var mult := float(event.get("multiplier", 1.0))
				var effectiveness := ""
				if mult > 1.1:
					effectiveness = " It's resonant!"
				elif mult < 0.9:
					effectiveness = " It barely echoes..."
				ui.append_log("%s used %s! %s took %d.%s" % [
					event.actor, event.chime, event.target, event.damage, effectiveness
				])
			"miss":
				ui.append_log("%s's %s missed!" % [event.actor, event.chime])
			"faint":
				ui.append_log("%s faded into stillness..." % event.name)
			"switch":
				var auto := bool(event.get("auto", false))
				ui.append_log("%s%s entered the field." % ["Wild " if auto and event.side == "enemy" else "", event.name])
			"flee_success":
				ui.append_log("You slipped away.")
			"flee_fail":
				ui.append_log("Couldn't escape!")
			"battle_end":
				if event.winner == "player":
					ui.append_log("You won the resonance clash!")
				else:
					ui.append_log("Your party was overwhelmed...")
			"message":
				ui.append_log(String(event.text))
		await get_tree().create_timer(0.45).timeout


func _finish_battle() -> void:
	GameState.sync_party_from_battle(_state.player.units)
	var winner := String(_state.get("winner", ""))
	var growth: Array[Dictionary] = []
	if winner == "player":
		var xp_events := CombatResolver.award_xp(_state, 40)
		growth = GameState.apply_xp_events(xp_events)
		for g in growth:
			if g.type == "level_up":
				ui.append_log("%s reached level %d!" % [g.name, g.level])
			elif g.type == "evolve":
				ui.append_log("%s evolved into %s!" % [g.from, g.to])
			await get_tree().create_timer(0.4).timeout
	elif winner == "enemy":
		ui.append_log("Retreat to Hearthmere's Save Shrine to recover.")

	await get_tree().create_timer(0.8).timeout
	SceneRouter.finish_battle({
		"winner": winner,
		"return_zone": String(_request.get("return_zone", "whisperwood")),
		"growth": growth,
	})


func _refresh_visuals() -> void:
	if _player_visual:
		_player_visual.queue_free()
	if _enemy_visual:
		_enemy_visual.queue_free()
	var player_unit: Dictionary = _state.player.units[_state.player.active]
	var enemy_unit: Dictionary = _state.enemy.units[_state.enemy.active]
	_player_visual = _spawn_visual(String(player_unit.definition_id), player_slot)
	_enemy_visual = _spawn_visual(String(enemy_unit.definition_id), enemy_slot)


func _spawn_visual(definition_id: String, slot: Marker3D) -> Node3D:
	var visual: Node3D = EchoVisualScene.instantiate()
	slot.add_child(visual)
	visual.scale = Vector3(2.2, 2.2, 2.2)
	visual.global_position = slot.global_position
	if visual.has_method("setup_from_definition"):
		visual.setup_from_definition(EchoCatalog.get_echo(definition_id))
	return visual
