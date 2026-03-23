extends Node

signal health_changed(new_val: float)
signal hunger_changed(new_val: float)
signal thirst_changed(new_val: float)
signal stamina_changed(new_val: float)
signal morale_changed(new_stage: int)
signal player_died

# ── Vitals ──────────────────────────────────────
var max_health:  float = 100.0
var health:      float = 100.0
var max_hunger:  float = 100.0
var hunger:      float = 100.0
var max_thirst:  float = 100.0
var thirst:      float = 100.0
var max_stamina: float = 100.0
var stamina:     float = 100.0

# ── Morale: 0=Thriving, 1=Stable, 2=Strained,
#            3=Unraveling, 4=Broken ─────────────
var morale_stage: int = 0

# ── Drain rates (per real second) ───────────────
# 1 real min = 1 in-game hr, full day = 24 min
# Hunger empties in ~50 in-game hrs = 50 real mins
const HUNGER_DRAIN:       float = 0.033
const THIRST_DRAIN:       float = 0.050
const HEALTH_DRAIN_HUNGER: float = 0.083
const HEALTH_DRAIN_THIRST: float = 0.133

# ── Stamina recovery when not sprinting ─────────
const STAMINA_REGEN: float = 15.0

# ── Meal history (tracks last 5 for morale) ─────
var meal_history: Array[String] = []
const MEAL_HISTORY_MAX: int = 5

func _process(delta: float) -> void:
	if GameManager.is_paused:
		return
	_drain_hunger(delta)
	_drain_thirst(delta)
	_check_starvation(delta)

func _drain_hunger(delta: float) -> void:
	hunger = max(0.0, hunger - HUNGER_DRAIN * delta)
	emit_signal("hunger_changed", hunger)

func _drain_thirst(delta: float) -> void:
	thirst = max(0.0, thirst - THIRST_DRAIN * delta)
	emit_signal("thirst_changed", thirst)

func _check_starvation(delta: float) -> void:
	if hunger <= 0.0:
		modify_health(-HEALTH_DRAIN_HUNGER * delta)
	if thirst <= 0.0:
		modify_health(-HEALTH_DRAIN_THIRST * delta)

func modify_health(amount: float) -> void:
	health = clamp(health + amount, 0.0, max_health)
	emit_signal("health_changed", health)
	if health <= 0.0:
		emit_signal("player_died")

func regen_stamina(delta: float) -> void:
	stamina = min(max_stamina, stamina + STAMINA_REGEN * delta)
	emit_signal("stamina_changed", stamina)

func drain_stamina(amount: float) -> void:
	stamina = max(0.0, stamina - amount)
	emit_signal("stamina_changed", stamina)

func consume_food(food_id: String, restore_hunger: float) -> void:
	hunger = min(max_hunger, hunger + restore_hunger)
	emit_signal("hunger_changed", hunger)
	_record_meal(food_id)

func consume_water(restore_thirst: float) -> void:
	thirst = min(max_thirst, thirst + restore_thirst)
	emit_signal("thirst_changed", thirst)

func set_morale(new_stage: int) -> void:
	morale_stage = clamp(new_stage, 0, 4)
	emit_signal("morale_changed", morale_stage)

func _record_meal(food_id: String) -> void:
	meal_history.append(food_id)
	if meal_history.size() > MEAL_HISTORY_MAX:
		meal_history.pop_front()

func get_health_regen_multiplier() -> float:
	match morale_stage:
		0: return 1.10   # Thriving  +10%
		1: return 1.00   # Stable    normal
		2: return 0.75   # Strained  -25%
		3: return 0.50   # Unraveling -50%
		4: return 0.0    # Broken    stopped
	return 1.0
