## Multiplayer stubs — interfaces only for Milestone 1.
## Do not add sockets here until Milestone 5.
class_name MultiplayerContracts
extends RefCounted


class SessionTransport:
	func connect_session(_friend_code: String) -> void:
		push_warning("Multiplayer not implemented yet.")

	func send_battle_action(_action: Dictionary) -> void:
		pass

	func send_trade_offer(_offer: Dictionary) -> void:
		pass


class FriendCode:
	static func generate() -> String:
		return "%04d-%04d" % [randi() % 10000, randi() % 10000]


class TradeOffer:
	var offered_instance_id: String = ""
	var requested_definition_id: String = ""
