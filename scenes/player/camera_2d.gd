extends Camera2D

# ── Zoom settings ────────────────────────────────────────────
const ZOOM_DEFAULT:  Vector2 = Vector2(2.0, 2.0)
const ZOOM_INDOOR:   Vector2 = Vector2(2.5, 2.5)  # closer inside buildings
const ZOOM_MIN:      Vector2 = Vector2(1.5, 1.5)  # max zoom out
const ZOOM_MAX:      Vector2 = Vector2(3.0, 3.0)  # max zoom in
const ZOOM_SPEED:    float   = 5.0                # tween speed

# ── Screen shake settings ────────────────────────────────────
var _shake_strength: float = 0.0
var _shake_decay:    float = 0.0

func _ready() -> void:
	zoom = ZOOM_DEFAULT
	position_smoothing_enabled = true
	position_smoothing_speed   = 8.0
	limit_smoothed             = true

func _process(delta: float) -> void:
	_handle_shake(delta)

# ── Screen Shake ─────────────────────────────────────────────
# Call this from anywhere: player camera node reference
# e.g. player.get_node("Camera2D").shake(8.0, 0.3)
func shake(strength: float, duration: float) -> void:
	_shake_strength = strength
	# Decay rate = strength / duration so it fades over exactly 'duration' seconds
	_shake_decay = strength / duration

func _handle_shake(delta: float) -> void:
	if _shake_strength > 0.0:
		offset = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)
		_shake_strength = max(0.0, _shake_strength - _shake_decay * delta)
	else:
		offset = Vector2.ZERO

# ── Smooth Zoom ──────────────────────────────────────────────
func zoom_to(target_zoom: Vector2) -> void:
	target_zoom = target_zoom.clamp(ZOOM_MIN, ZOOM_MAX)
	var tween := create_tween()
	tween.tween_property(self, "zoom", target_zoom, 0.4) \
		 .set_ease(Tween.EASE_OUT) \
		 .set_trans(Tween.TRANS_SINE)

func zoom_reset() -> void:
	zoom_to(ZOOM_DEFAULT)

func zoom_indoor() -> void:
	zoom_to(ZOOM_INDOOR)
