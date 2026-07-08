# Trap.gd — Armadilhas do cenário
# Regra universal: afeta Kyle E inimigos igualmente
# Tipos: SPIKES=0, FIRE=1, PIT=2, PENDULUM=3, TRAPDOOR=4

extends Area2D

enum TrapType { SPIKES, FIRE, PIT, PENDULUM, TRAPDOOR }

@export var trap_type: int         = TrapType.SPIKES
@export var damage: float          = 15.0
@export var damage_per_sec: float  = 5.0
@export var knockback_force: float = 250.0
@export var fire_duration: float   = 0.0   # 0 = permanente
@export var pendulum_speed: float  = 1.5
@export var pendulum_range: float  = 80.0

var _fire_timer: float   = 0.0
var _is_temporary: bool  = false
var _pendulum_angle: float = 0.0
var _pendulum_dir: float   = 1.0
var _bodies_inside: Array  = []   # quem está no fogo agora
var _damage_tick: float    = 0.0

@onready var game: Node = $"/root/GameManager"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if trap_type == TrapType.FIRE and fire_duration > 0:
		_is_temporary = true
		_fire_timer   = fire_duration

func _process(delta: float) -> void:
	if _is_temporary:
		_fire_timer -= delta
		if _fire_timer <= 0:
			queue_free()
			return

	# Tick de fogo para todos os corpos dentro
	if trap_type == TrapType.FIRE and _bodies_inside.size() > 0:
		_damage_tick -= delta
		if _damage_tick <= 0:
			_damage_tick = 1.0
			for body in _bodies_inside.duplicate():
				if is_instance_valid(body) and body.has_method("take_damage"):
					body.take_damage(damage_per_sec)

	# Pêndulo oscila
	if trap_type == TrapType.PENDULUM:
		_pendulum_angle += pendulum_speed * _pendulum_dir * delta
		if abs(_pendulum_angle) >= deg_to_rad(60):
			_pendulum_dir *= -1
		position.x = _pendulum_range * sin(_pendulum_angle)

func _on_body_entered(body: Node) -> void:
	if not body.has_method("take_damage"):
		return

	match trap_type:
		TrapType.SPIKES:
			body.take_damage(damage)
			if body.is_in_group("player"):
				game.speak("Espinhos")

		TrapType.FIRE:
			if not _bodies_inside.has(body):
				_bodies_inside.append(body)
				_damage_tick = 0.0
			if body.is_in_group("player"):
				game.speak("Fogo")

		TrapType.PIT:
			body.take_damage(9999.0)
			if body.is_in_group("player"):
				game.speak("Caiu no abismo")
			elif body.is_in_group("enemies"):
				# Inimigo cai — remove imediatamente
				body.queue_free()

		TrapType.PENDULUM:
			body.take_damage(damage)
			var kb_dir = (body.global_position - global_position).normalized()
			if body.has_method("apply_knockback"):
				body.apply_knockback(kb_dir * knockback_force)
			if body.is_in_group("player"):
				game.speak("Pêndulo")

		TrapType.TRAPDOOR:
			_open_trapdoor(body)
			if body.is_in_group("player"):
				game.speak("Alçapão")

func _on_body_exited(body: Node) -> void:
	_bodies_inside.erase(body)

func _open_trapdoor(body: Node) -> void:
	var col = get_node_or_null("CollisionShape2D")
	if col:
		col.set_deferred("disabled", true)
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(body) and body.has_method("take_damage"):
		body.take_damage(9999.0)
		if body.is_in_group("enemies"):
			body.queue_free()
