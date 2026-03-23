extends Node

signal hour_changed(hour: int)
signal day_changed(day: int)
signal prep_day_elapsed(days_remaining: int)
signal night_started
signal day_started

# 1 real second = 1 in-game minute
# 1 real minute = 1 in-game hour
# 24 real minutes = 1 full in-game day
const REAL_SECONDS_PER_HOUR: float = 60.0

var current_hour: int = 8
var current_day:  int = 1
var elapsed_seconds: float = 0.0
var prep_days_remaining: int = 10
var _was_night: bool = false

func _process(delta: float) -> void:
	if GameManager.is_paused:
		return
	elapsed_seconds += delta
	if elapsed_seconds >= REAL_SECONDS_PER_HOUR:
		elapsed_seconds -= REAL_SECONDS_PER_HOUR
		_advance_hour()

func _advance_hour() -> void:
	current_hour += 1
	emit_signal("hour_changed", current_hour)

	# Fire night/day transition signals
	var is_night_now := is_night()
	if is_night_now and not _was_night:
		emit_signal("night_started")
	elif not is_night_now and _was_night:
		emit_signal("day_started")
	_was_night = is_night_now

	if current_hour >= 24:
		current_hour = 0
		_advance_day()

func _advance_day() -> void:
	current_day += 1
	emit_signal("day_changed", current_day)
	if GameManager.current_phase == GameManager.GamePhase.PREP:
		prep_days_remaining -= 1
		emit_signal("prep_day_elapsed", prep_days_remaining)
		if prep_days_remaining <= 0:
			GameManager.trigger_collapse()

func is_night() -> bool:
	return current_hour < 6 or current_hour >= 20

func get_time_string() -> String:
	var suffix := "AM" if current_hour < 12 else "PM"
	var display_hour := current_hour % 12
	if display_hour == 0:
		display_hour = 12
	return "Day %d  %02d:00 %s" % [current_day, display_hour, suffix]
