extends Node

signal collapse_triggered
signal game_paused(is_paused: bool)
signal zone_changed(zone_path: String, spawn_name: String)

enum GamePhase { PREP, COLLAPSED, GAME_OVER }

var current_phase: GamePhase = GamePhase.PREP
var active_power_id: String = ""
var is_paused: bool = false
var current_zone: String = ""

func trigger_collapse() -> void:
	current_phase = GamePhase.COLLAPSED
	emit_signal("collapse_triggered")

func set_paused(value: bool) -> void:
	is_paused = value
	get_tree().paused = value
	emit_signal("game_paused", value)

func change_zone(zone_path: String, spawn_name: String) -> void:
	current_zone = zone_path
	emit_signal("zone_changed", zone_path, spawn_name)
