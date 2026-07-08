# EnemyTroll.gd — Troll: lento, forte, arremessa pedras em arco parabólico

extends CharacterBody2D

@export var speed: float           = 45.0
@export var max_hp: float          = 120.0
@export var melee_damage: float    = 22.0
@export var rock_damage: float     = 18.0
@export var melee_range: float     = 80.0
@export var throw_range: float     = 300.0
@export var detection_range: float = 400.0
@export var attack_cooldown: float = 2.2

const GRAVITY: float = 980.0

var hp: float          = 120.0
var state: String      = "patrol"
var player: Node       = null
var _atk_timer: float  = 0.0
var facing_right: bool = false
var stun_timer: float  = 0.0
var patrol_dir: float  = 1.0
var patrol_timer: float = 2.0

@onready var game: Node = $"/root/GameManager"

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_atk_timer = max(_atk_timer - delta, 0.0)

	if stun_timer > 0:
		stun_timer -= delta
		velocity.x = 0
		move_and_slide()
		return

	if not player:
		_do_patrol(delta)
		move_and_slide()
		return

	var dist = global_position.distance_to(player.global_position)

	if dist > detection_range:
		_do_patrol(delta)
		move_and_slide()
		return

	if dist <= melee_range:
		_do_melee()
	elif dist <= throw_range:
		_do_throw()
	else:
		# Avança
		var dir = (player.global_position - global_position).normalized()
		velocity.x = dir.x * speed
		facing_right = dir.x > 0

	move_and_slide()

func _do_patrol(delta: float) -> void:
	patrol_timer -= delta
	if patrol_timer <= 0:
		patrol_dir  *= -1
		patrol_timer = randf_range(2.0, 4.0)
	velocity.x   = speed * patrol_dir * 0.4
	facing_right = patrol_dir > 0

func _do_melee() -> void:
	velocity.x = 0
	if _atk_timer > 0:
		return
	_atk_timer = attack_cooldown
	# Avisa parry
	if player.has_method("open_parry_window"):
		player.open_parry_window()
	get_tree().create_timer(0.4).timeout.connect(func():
		if player and global_position.distance_to(player.global_position) <= melee_range * 1.2:
			player.take_damage(melee_damage)
	)

func _do_throw() -> void:
	velocity.x = 0
	if _atk_timer > 0:
		return
	_atk_timer = attack_cooldown + 0.5
	game.speak("Projétil")
	var proj_scene = load("res://scenes/projectile.tscn")
	if not proj_scene:
		return
	var rock = proj_scene.instantiate()
	rock.proj_type     = 1  # ROCK
	rock.damage        = rock_damage
	rock.speed         = 200.0
	rock.gravity_scale = 0.4
	# Mira com arco: aponta levemente pra cima para compensar gravidade
	var raw_dir = (player.global_position - global_position).normalized()
	var arc_dir = (raw_dir + Vector2(0, -0.35)).normalized()
	rock.direction         = arc_dir
	rock.shooter           = self
	rock.global_position   = global_position + arc_dir * 40
	get_parent().add_child(rock)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		_die()

func stun(duration: float) -> void:
	stun_timer = duration
	velocity.x  = 0

func _die() -> void:
	remove_from_group("enemies")
	await get_tree().create_timer(0.5).timeout
	queue_free()
