# EnemyArcher.gd — Arqueiro goblin: mantém distância e atira flechas

extends CharacterBody2D

@export var speed: float           = 60.0
@export var max_hp: float          = 35.0
@export var arrow_damage: float    = 12.0
@export var preferred_range: float = 220.0  # tenta manter essa distância
@export var detection_range: float = 350.0
@export var fire_cooldown: float   = 2.0

const GRAVITY: float = 980.0

var hp: float          = 35.0
var state: String      = "idle"
var player: Node       = null
var _fire_timer: float = 0.0
var facing_right: bool = false
var stun_timer: float  = 0.0

@onready var game: Node = $"/root/GameManager"

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_fire_timer = max(_fire_timer - delta, 0.0)

	if stun_timer > 0:
		stun_timer -= delta
		velocity.x = 0
		move_and_slide()
		return

	if not player:
		move_and_slide()
		return

	var dist = global_position.distance_to(player.global_position)

	if dist > detection_range:
		velocity.x = 0
		move_and_slide()
		return

	# Avisa projétil se estiver mirando
	if dist <= preferred_range * 1.2:
		_maybe_warn_player(dist)

	# Mantém distância preferida
	if dist < preferred_range - 30:
		# Muito perto — recua
		var dir = (global_position - player.global_position).normalized()
		velocity.x = dir.x * speed
		facing_right = dir.x > 0
	elif dist > preferred_range + 30:
		# Muito longe — avança
		var dir = (player.global_position - global_position).normalized()
		velocity.x = dir.x * speed
		facing_right = dir.x > 0
	else:
		velocity.x = 0

	# Atira se na faixa certa e cooldown zerado
	if dist <= preferred_range and _fire_timer <= 0:
		_fire_arrow()

	move_and_slide()

func _maybe_warn_player(dist: float) -> void:
	# TTS avisa quando arqueiro está prestes a atirar
	if _fire_timer <= 0.3 and dist <= preferred_range:
		game.speak("Projétil")

func _fire_arrow() -> void:
	_fire_timer = fire_cooldown
	var proj_scene = load("res://scenes/projectile.tscn")
	if not proj_scene:
		return
	var arrow = proj_scene.instantiate()
	arrow.proj_type = 0  # ARROW
	arrow.damage    = arrow_damage
	var dir = (player.global_position - global_position).normalized()
	arrow.direction = dir
	arrow.shooter   = self
	arrow.speed     = 280.0
	arrow.global_position = global_position + dir * 30
	get_parent().add_child(arrow)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		_die()

func stun(duration: float) -> void:
	stun_timer = duration
	velocity.x  = 0

func _die() -> void:
	remove_from_group("enemies")
	await get_tree().create_timer(0.3).timeout
	queue_free()
