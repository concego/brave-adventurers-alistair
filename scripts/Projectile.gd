# Projectile.gd — Projétil genérico com suporte a deflect por tipo
# Regra universal: afeta qualquer CharacterBody2D (Kyle ou inimigo)
# Tipos: "arrow"=0, "rock"=1, "torch"=2, "ice_ray"=3, "shadow_blast"=4

extends Area2D

enum ProjType { ARROW, ROCK, TORCH, ICE_RAY, SHADOW_BLAST }

@export var proj_type: int        = ProjType.ARROW
@export var speed: float          = 300.0
@export var damage: float         = 12.0
@export var gravity_scale: float  = 0.0
@export var fire_duration: float  = 3.0

var direction: Vector2  = Vector2.RIGHT
var shooter: Node       = null
var deflected: bool     = false
var _velocity: Vector2  = Vector2.ZERO
var _lifetime: float    = 4.0

const GRAVITY: float = 980.0

@onready var game: Node = $"/root/GameManager"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

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

	if proj_type == ProjType.ROCK:
		_velocity.y += GRAVITY * gravity_scale * delta

	position += _velocity * delta
	rotation   = _velocity.angle()

func _on_body_entered(body: Node) -> void:
	# Nunca acerta quem atirou
	if body == shooter:
		return

	# Jogador — lógica especial (status, knockback)
	if body.is_in_group("player"):
		if deflected:
			return   # projétil deflectido não volta pro jogador
		_hit_character(body, true)
		return

	# Inimigo — fogo amigo ou deflectido
	if body.is_in_group("enemies"):
		_hit_character(body, false)
		return

	# Colidiu com geometria do mundo
	_on_hit_world()

func _hit_character(body: Node, is_player: bool) -> void:
	match proj_type:
		ProjType.ICE_RAY:
			body.take_damage(damage)
			if body.has_method("apply_status"):
				body.apply_status("frozen", 1.2)
			if is_player:
				game.speak("Gelo")

		ProjType.SHADOW_BLAST:
			body.take_damage(damage)
			var kb = (body.global_position - global_position).normalized() * 300
			if body.has_method("apply_knockback"):
				body.apply_knockback(kb)
			if is_player:
				game.speak("Explosão de sombra")

		_:
			body.take_damage(damage)

	queue_free()

func _on_hit_world() -> void:
	if proj_type == ProjType.TORCH:
		_spawn_fire()
	queue_free()

func try_deflect(player: Node) -> bool:
	match proj_type:
		ProjType.ARROW:
			deflected  = true
			var aim    = Vector2.RIGHT
			if shooter:
				aim = (shooter.global_position - global_position).normalized()
			_velocity  = aim * speed
			direction  = aim
			game.speak("Deflectido")
			return true

		ProjType.ROCK:
			game.speak("Bloqueado")
			queue_free()
			return true

		ProjType.TORCH:
			_velocity      = Vector2(randf_range(-80, 80), 200)
			gravity_scale  = 1.0
			deflected      = true
			game.speak("Tocha deflectida")
			return true

		ProjType.ICE_RAY, ProjType.SHADOW_BLAST:
			return false

	return false

func _spawn_fire() -> void:
	var fire_scene = load("res://scenes/trap.tscn")
	if not fire_scene:
		return
	var fire = fire_scene.instantiate()
	fire.trap_type      = 1  # FIRE
	fire.fire_duration  = fire_duration
	fire.global_position = global_position
	get_parent().add_child(fire)
