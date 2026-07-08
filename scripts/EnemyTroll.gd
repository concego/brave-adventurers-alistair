# EnemyTroll.gd — Troll pesado: tenta pular fossos, às vezes cai
# pit_awareness=0.5: 50% de chance de detectar fosso

extends "res://scripts/EnemyBase.gd"

@export var melee_damage: float    = 22.0
@export var rock_damage: float     = 18.0
@export var melee_range: float     = 80.0
@export var throw_range: float     = 300.0
@export var attack_cooldown: float = 2.2
@export var jump_force: float      = -380.0

var state: String      = "patrol"
var _atk_timer: float  = 0.0
var patrol_dir: float  = 1.0
var patrol_timer: float = 2.0

@onready var game: Node = $"/root/GameManager"

func _ready() -> void:
	pit_awareness = 0.5
	speed         = 45.0
	max_hp        = 120.0
	hp            = max_hp
	_ready_base()

func _physics_process(delta: float) -> void:
	if _process_base(delta): return

	_atk_timer = max(_atk_timer - delta, 0.0)

	if not player:
		_do_patrol(delta)
		move_and_slide()
		return

	var dist = global_position.distance_to(player.global_position)

	if dist > detection_range:
		_do_patrol(delta)
	elif dist <= melee_range:
		_do_melee()
	elif dist <= throw_range:
		_do_throw()
	else:
		velocity.x = _safe_move_toward(player.global_position, speed)

	move_and_slide()

func _do_patrol(delta: float) -> void:
	patrol_timer -= delta
	if patrol_timer <= 0:
		patrol_dir   *= -1
		patrol_timer  = randf_range(2.0, 4.0)
	velocity.x = _safe_move_toward(global_position + Vector2(patrol_dir * 100, 0), speed * 0.4)

func _do_melee() -> void:
	velocity.x = 0
	if _atk_timer > 0: return
	_atk_timer = attack_cooldown
	if player.has_method("open_parry_window"):
		player.open_parry_window()
	get_tree().create_timer(0.4).timeout.connect(func():
		if player and global_position.distance_to(player.global_position) <= melee_range * 1.2:
			player.take_damage(melee_damage)
	)

func _do_throw() -> void:
	velocity.x = 0
	if _atk_timer > 0: return
	_atk_timer = attack_cooldown + 0.5
	game.speak("Projétil")
	var proj_scene = load("res://scenes/projectile.tscn")
	if not proj_scene: return
	var rock             = proj_scene.instantiate()
	rock.proj_type       = 1  # ROCK
	rock.damage          = rock_damage
	rock.speed           = 200.0
	rock.gravity_scale   = 0.4
	rock.shooter         = self
	var raw_dir          = (player.global_position - global_position).normalized()
	var arc_dir          = (raw_dir + Vector2(0, -0.35)).normalized()
	rock.direction       = arc_dir
	rock.global_position = global_position + arc_dir * 40
	get_parent().add_child(rock)

# Troll tenta pular o fosso
func _pit_reaction(dir: float, _spd: float) -> float:
	if is_on_floor():
		velocity.y = jump_force   # pula
	return dir * speed            # continua avançando durante o pulo
