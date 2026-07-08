# Trap.gd — Armadilhas do cenário
# Tipos: SPIKES, FIRE, PIT, PENDULUM, TRAPDOOR

extends Area2D

enum TrapType { SPIKES, FIRE, PIT, PENDULUM, TRAPDOOR }

@export var trap_type: int      = TrapType.SPIKES
@export var damage: float       = 15.0
@export var damage_per_sec: float = 5.0
@export var knockback_force: float = 250.0
@export var fire_duration: float   = 3.0   # só pra fogo temporário (tocha)
@export var pendulum_speed: float  = 1.5
@export var pendulum_range: float  = 80.0  # pixels

var _fire_timer: float   = 0.0
var _is_temporary: bool  = false
var _pendulum_angle: float = 0.0
var _pendulum_dir: float   = 1.0
var _player_inside: bool   = false
var _damage_tick: float    = 0.0

@onready var game: Node = $"/root/GameManager"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	match trap_type:
		TrapType.FIRE:
			if fire_duration > 0:
				_is_temporary = true
				_fire_timer = fire_duration
		TrapType.PENDULUM:
			set_process(true)
		_:
			pass

func _process(delta: float) -> void:
	# Fogo temporário (de tocha deflectida)
	if _is_temporary:
		_fire_timer -= delta
		if _fire_timer <= 0:
			queue_free()
			return

	# Tick de dano contínuo (fogo)
	if _player_inside and trap_type == TrapType.FIRE:
		_damage_tick -= delta
		if _damage_tick <= 0:
			_damage_tick = 1.0
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.take_damage(damage_per_sec)

	# Pêndulo — oscila e causa dano ao tocar
	if trap_type == TrapType.PENDULUM:
		_pendulum_angle += pendulum_speed * _pendulum_dir * delta
		if abs(_pendulum_angle) >= deg_to_rad(60):
			_pendulum_dir *= -1
		position.x = _pendulum_range * sin(_pendulum_angle)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	match trap_type:
		TrapType.SPIKES:
			body.take_damage(damage)
			game.speak("Espinhos")

		TrapType.FIRE:
			_player_inside = true
			_damage_tick = 0.0
			game.speak("Fogo")

		TrapType.PIT:
			# Fosso — morte instantânea
			body.take_damage(9999.0)
			game.speak("Caiu no abismo")

		TrapType.PENDULUM:
			body.take_damage(damage)
			# Knockback afasta do pêndulo
			var kb_dir = (body.global_position - global_position).normalized()
			if body.has_method("apply_knockback"):
				body.apply_knockback(kb_dir * knockback_force)
			game.speak("Pêndulo")

		TrapType.TRAPDOOR:
			# Alçapão — abre e faz cair no fosso
			_open_trapdoor(body)
			game.speak("Alçapão")

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _open_trapdoor(player: Node) -> void:
	# Desativa colisão do chão do alçapão
	var col = get_node_or_null("CollisionShape2D")
	if col:
		col.set_deferred("disabled", true)
	# Dano letal após 0.3s (tempo de cair)
	await get_tree().create_timer(0.3).timeout
	if player and is_instance_valid(player):
		player.take_damage(9999.0)
