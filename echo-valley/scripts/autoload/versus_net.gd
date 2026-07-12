extends Node

## WebSocket client for 2-player online versus (host-authoritative battles).
## Production: harmona.fun (Vercel) connects cross-origin to the Render lobby.

# Custom domain on Render — add ws.harmona.fun in Render dashboard + DNS CNAME.
const PROD_LOBBY_WSS := "wss://ws.harmona.fun/versus"
# Vercel preview deploys use the same lobby.
const VERCEL_HOST_SUFFIX := ".vercel.app"
const HARMONA_HOSTS := ["harmona.fun", "www.harmona.fun"]

signal connected
signal disconnected
signal room_updated(room: Dictionary)
signal battle_start(payload: Dictionary)
signal guest_action_received(action: Dictionary)
signal turn_result_received(packet: Dictionary)
signal net_error(message: String)

var role: String = ""
var room: Dictionary = {}
var peer: WebSocketPeer
var _open: bool = false
var _last_error: String = ""
var _turn_packet: Dictionary = {}
var _pending_guest_action: Dictionary = {}
var _has_guest_action: bool = false


func _ready() -> void:
	peer = WebSocketPeer.new()


func _process(_delta: float) -> void:
	if peer == null:
		return
	peer.poll()
	while peer.get_available_packet_count() > 0:
		var raw := peer.get_packet().get_string_from_utf8()
		_handle_raw(raw)


func connect_lobby() -> int:
	disconnect_lobby()
	peer = WebSocketPeer.new()
	var err := peer.connect_to_url(_ws_url())
	if err != OK:
		net_error.emit("Could not connect (%d)" % err)
	return err


func disconnect_lobby() -> void:
	if peer:
		peer.close()
	_open = false
	role = ""
	room = {}


func lobby_open() -> bool:
	return peer != null and peer.get_ready_state() == WebSocketPeer.STATE_OPEN


func create_room(player_name: String) -> void:
	_send({ "type": "create_room", "name": player_name })


func join_room(code: String, player_name: String) -> void:
	_send({ "type": "join_room", "code": code.to_upper(), "name": player_name })


func set_options(team_size: int, level: int) -> void:
	_send({ "type": "set_options", "team_size": team_size, "level": level })


func set_team(echo_ids: Array[String]) -> void:
	_send({ "type": "set_team", "echo_ids": echo_ids })


func send_ready() -> void:
	_send({ "type": "ready" })


func send_guest_action(action: Dictionary) -> void:
	_send({ "type": "guest_action", "action": action })


func send_turn_result(state: Dictionary) -> void:
	_send({
		"type": "turn_result",
		"log": state.get("log", []),
		"state": _guest_view_state(state),
		"finished": state.get("finished", false),
		"winner": String(state.get("winner", "")),
	})


func send_battle_end(winner: String) -> void:
	_send({ "type": "battle_end", "winner": winner })


func _guest_view_state(state: Dictionary) -> Dictionary:
	# Guest sees their team as "player" on the bottom.
	return {
		"player": state.enemy,
		"enemy": state.player,
		"turn": state.get("turn", 1),
		"finished": state.get("finished", false),
		"winner": _flip_winner(String(state.get("winner", ""))),
		"log": [],
	}


func _flip_winner(w: String) -> String:
	if w == "player":
		return "enemy"
	if w == "enemy":
		return "player"
	return w


func _ws_url() -> String:
	if OS.has_feature("web"):
		var host: String = JavaScriptBridge.eval("location.hostname")
		# Local dev: game + lobby share server.js on the same port.
		if host == "localhost" or host == "127.0.0.1":
			return JavaScriptBridge.eval(
				"((location.protocol==='https:')?'wss://':'ws://')+location.host+'/versus'")
		# harmona.fun (and Vercel previews) → Render lobby subdomain.
		if host in HARMONA_HOSTS or host.ends_with(VERCEL_HOST_SUFFIX):
			return PROD_LOBBY_WSS
		# Fallback for all-in-one hosts (e.g. Render serving game + lobby).
		return JavaScriptBridge.eval(
			"((location.protocol==='https:')?'wss://':'ws://')+location.host+'/versus'")
	return "ws://127.0.0.1:4173/versus"


func _send(payload: Dictionary) -> void:
	if not lobby_open():
		net_error.emit("Not connected")
		return
	peer.send_text(JSON.stringify(payload))


func _handle_raw(raw: String) -> void:
	var data: Variant = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		return
	match String(data.get("type", "")):
		"room_state":
			room = data.get("room", {})
			if role == "" and room.get("has_guest", false):
				role = "host" if room.get("guest_name", "") != "" else role
			room_updated.emit(room)
		"battle_start":
			role = String(data.get("role", ""))
			battle_start.emit(data)
		"guest_action":
			_pending_guest_action = data.get("action", {})
			_has_guest_action = true
			guest_action_received.emit(_pending_guest_action)
		"turn_result":
			var pkt := {
				"log": data.get("log", []),
				"state": data.get("state", {}),
				"finished": bool(data.get("finished", false)),
				"winner": String(data.get("winner", "")),
			}
			_turn_packet = pkt
			turn_result_received.emit(pkt)
		"battle_end":
			var end_pkt := {
				"log": [],
				"state": {},
				"finished": true,
				"winner": _flip_winner(String(data.get("winner", ""))),
			}
			_turn_packet = end_pkt
			turn_result_received.emit(end_pkt)
		"error":
			var msg := String(data.get("message", "Network error"))
			_last_error = msg
			net_error.emit(msg)


func wait_guest_action() -> Dictionary:
	if _has_guest_action:
		var a := _pending_guest_action
		_has_guest_action = false
		_pending_guest_action = {}
		return a
	var action: Dictionary = await guest_action_received
	_has_guest_action = false
	_pending_guest_action = {}
	return action


func wait_turn_result() -> Dictionary:
	_turn_packet = {}
	while _turn_packet.is_empty():
		await turn_result_received
	return _turn_packet.duplicate(true)


func wait_connected(timeout: float = 6.0) -> bool:
	var t := 0.0
	while t < timeout:
		peer.poll()
		var st := peer.get_ready_state()
		if st == WebSocketPeer.STATE_OPEN:
			_open = true
			connected.emit()
			return true
		if st == WebSocketPeer.STATE_CLOSED:
			net_error.emit("Connection closed")
			return false
		t += get_process_delta_time()
		await get_tree().process_frame
	net_error.emit("Connection timed out")
	return false
