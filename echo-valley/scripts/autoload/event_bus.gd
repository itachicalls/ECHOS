extends Node

signal toast(text: String)
signal party_changed
signal dialogue_requested(lines: Array)
signal dialogue_closed
signal tap_continue
signal menu_requested(tab: String)

var dialogue_active: bool = false
var menu_active: bool = false
var awaiting_continue: bool = false
