# GestureController.gd
# Detecta gestos de swipe nas duas metades da tela (mão esquerda / mão direita)
# Landscape 1280x720: esquerda = x < 640, direita = x >= 640

extends Node

signal swipe_detected(hand: String, direction: String)

const SWIPE_THRESHOLD = 60.0  # pixels mínimos para registrar swipe
const HOLD_THRESHOLD = 0.3     # segundos para considerar "segurar"

var _touches: Dictionary = {}  # touch_index -> {start_pos, start_time, pos}

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = {
				"start_pos": event.position,
				"start_time": Time.get_ticks_msec() / 1000.0,
				"pos": event.position,
				"hand": _get_hand(event.position)
			}
		else:
			if _touches.has(event.index):
				var t = _touches[event.index]
				var delta = event.position - t["start_pos"]
				var elapsed = (Time.get_ticks_msec() / 1000.0) - t["start_time"]
				_process_gesture(t["hand"], delta, elapsed)
				_touches.erase(event.index)

	elif event is InputEventScreenDrag:
		if _touches.has(event.index):
			_touches[event.index]["pos"] = event.position

func _process_gesture(hand: String, delta: Vector2, elapsed: float) -> void:
	var dist = delta.length()
	if dist < SWIPE_THRESHOLD:
		return  # movimento muito curto, ignora

	var angle = rad_to_deg(atan2(delta.y, delta.x))
	var direction = ""

	if angle >= -45 and angle < 45:
		direction = "right"
	elif angle >= 45 and angle < 135:
		direction = "down"
	elif angle >= -135 and angle < -45:
		direction = "up"
	else:
		direction = "left"

	emit_signal("swipe_detected", hand, direction)

func _get_hand(pos: Vector2) -> String:
	var half = get_viewport().get_visible_rect().size.x / 2.0
	return "left" if pos.x < half else "right"

# Verifica se mão esquerda está segurando (para movimento contínuo)
func get_left_hold_direction() -> String:
	for idx in _touches:
		var t = _touches[idx]
		if t["hand"] == "left":
			var delta = t["pos"] - t["start_pos"]
			if delta.length() >= SWIPE_THRESHOLD:
				if delta.x > 0:
					return "right"
				else:
					return "left"
	return ""
