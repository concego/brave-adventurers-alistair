# Projectile.gd — Projétil genérico com suporte a deflect por tipo
# Tipos: "arrow", "rock", "torch", "ice_ray", "shadow_blast"

extends Area2D

enum ProjType { ARROW, ROCK, TORCH, ICE_RAY, SHADOW_BLAST }

@export var proj_type: int     = ProjType.ARROW
@export var speed: float       = 300.0
@export var damage: float      = 12.0
@export var gravity_scale: float = 0.0   # pedra usa gravidade
@export var fire_duration: float = 3.0   # só pra tocha

var direction: Vector2 = Vector2.RIGHT
var shooter: Node      = null
var deflected: bool    = false
var _velocity: Vector2 = Vector2.ZERO
var _lifetime: float   = 4.0

const GRAVITY: float = 980.0

@onready var game: Node = $"/root/GameManager"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_velocity = direction.normalized() * speed

func launch(from: Node, dir: Vector2, dmg: float) -> void:
	shooter   = from
	direction = dir.normalized()
	damage    = dmg
	_velocity = direction * speed
	global_position = from.global_position + dir * 30

func _process(delta: float) -> void:
	_lifetime -= delta
	if _lifetime <= 0:
		queue_free()
		return

	# Pedra tem arco parabólico
	if proj_type == ProjType.ROCK:
		_velocity.y += GRAVITY * gravity_scale * delta

	position += _velocity * delta

	# Rotacionar visualmente na direção do movimento
	rotation = _velocity.angle()

func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return

	# Acertou jogador
	if body.is_in_group("player") and not deflected:
		_hit_player(body)
		return

	# Deflectido acertou inimigo
	if body.is_in_group("enemies") and deflected:
		body.take_damage(damage)
		queue_free()
		return

	# Colidiu com parede/chão
	_on_hit_world()

func _on_area_entered(area: Node) -> void:
	pass

func _hit_player(player: Node) -> void:
	match proj_type:
		ProjType.ICE_RAY:
			player.take_damage(damage)
			player.apply_status("frozen", 1.0)
			game.speak("Gelo")
		ProjType.SHADOW_BLAST:
			player.take_damage(damage)
			# Knockback
			var kb = (player.global_position - global_position).normalized() * 300
			player.velocity += kb
			game.speak("Explosão de sombra")
		_:
			player.take_damage(damage)
	queue_free()

func _on_hit_world() -> void:
	match proj_type:
		ProjType.TORCH:
			_spawn_fire()
		_:
			pass
	queue_free()

func try_deflect(player: Node) -> bool:
	match proj_type:
		ProjType.ARROW:
			# Volta pro atirador
			deflected = true
			direction = -direction
			_velocity  = direction * speed
			if shooter:
				var aim = (shooter.global_position - global_position).normalized()
				_velocity = aim * speed
			game.speak("Deflectido")
			return true
		ProjType.ROCK:
			# Some
			game.speak("Bloqueado")
			queue_free()
			return true
		ProjType.TORCH:
			# Cai no chão e cria fogo
			_velocity = Vector2(0, 200)
			gravity_scale = 1.0
			deflected = true
			game.speak("Tocha deflectida")
			return true
		ProjType.ICE_RAY, ProjType.SHADOW_BLAST:
			# Não pode deflectir
			return false
	return false

func _spawn_fire() -> void:
	var fire_scene = load("res://scenes/trap.tscn")
	if not fire_scene:
		return
	var fire = fire_scene.instantiate()
	fire.trap_type = 1  # FIRE
	fire.fire_duration = fire_duration
	fire.global_position = global_position
	get_parent().add_child(fire)
