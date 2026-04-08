extends CharacterBody2D

# ── Speed values tuned for 1280×720 at Camera zoom 2.0 ──────
# Effective pixel view = 640×360, so 200px/s feels like
# crossing the screen in ~3 seconds — Zelda-paced
const SPEED:         float = 200.0
const SPRINT_SPEED:  float = 340.0
const ACCELERATION:  float = 1200.0
const FRICTION:      float = 1400.0
const STAMINA_COST:  float = 18.0    # per second while sprinting

@onready var anim_sprite:   AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D           = $InteractArea
@onready var camera:        Camera2D         = $Camera2D


var last_direction: Vector2 = Vector2.DOWN
var is_sprinting:   bool    = false
var can_interact:   bool    = false

# ── State Machine ────────────────────────────────────────────
enum State { IDLE, WALK, SPRINT, DEAD }
var state: State = State.IDLE

func _ready() -> void:
	$AnimatedSprite2D.play("idle")
	PlayerStats.player_died.connect(_on_player_died)
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if GameManager.is_paused:
		return
	match state:
		State.IDLE:   _state_idle(delta)
		State.WALK:   _state_walk(delta)
		State.SPRINT: _state_sprint(delta)
		State.DEAD:   return

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_interact:
		_try_interact()

# ── States ───────────────────────────────────────────────────

func _state_idle(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	anim_sprite.play("idle")
	PlayerStats.regen_stamina(delta)
	move_and_slide()

	var dir := _get_input_direction()
	if dir != Vector2.ZERO:
		last_direction = dir
		state = State.WALK

func _state_walk(delta: float) -> void:
	var dir := _get_input_direction()
	PlayerStats.regen_stamina(delta)

	if dir != Vector2.ZERO:
		last_direction = dir
		velocity = velocity.move_toward(dir * SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	_update_walk_animation()
	move_and_slide()

	if velocity.length() < 5.0:
		state = State.IDLE
	elif Input.is_action_pressed("sprint") and PlayerStats.stamina > 0.0:
		state = State.SPRINT

func _state_sprint(delta: float) -> void:
	var dir := _get_input_direction()
	is_sprinting = true
	PlayerStats.drain_stamina(STAMINA_COST * delta)

	if dir != Vector2.ZERO:
		last_direction = dir
		velocity = velocity.move_toward(dir * SPRINT_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	_update_walk_animation()
	move_and_slide()

	# Exit sprint conditions
	if not Input.is_action_pressed("sprint") or PlayerStats.stamina <= 0.0:
		is_sprinting = false
		state = State.WALK if velocity.length() > 5.0 else State.IDLE

# when hit take damage
func take_damage(amount: float) -> void:
	PlayerStats.modify_health(-amount)
	$Camera2D.shake(6.0, 0.25)   # shake strength 6px, fade over 0.25 seconds


# ── Helpers ──────────────────────────────────────────────────

func _get_input_direction() -> Vector2:
	return Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	).normalized()

func _update_walk_animation() -> void:
	# Prioritize horizontal animation when moving diagonally
	if abs(last_direction.x) >= abs(last_direction.y):
		anim_sprite.play("walk_right" if last_direction.x > 0 else "walk_left")
	else:
		anim_sprite.play("walk_down" if last_direction.y > 0 else "walk_up")

func _try_interact() -> void:
	# Finds the nearest interactable in range and calls interact()
	var bodies := interact_area.get_overlapping_bodies()
	var areas  := interact_area.get_overlapping_areas()
	for obj in bodies + areas:
		if obj.has_method("interact"):
			obj.interact(self)
			break

func _on_player_died() -> void:
	state = State.DEAD
	anim_sprite.play("death")
	set_physics_process(false)
	set_process_input(false)
