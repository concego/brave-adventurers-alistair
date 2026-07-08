# EnemyArcher.gd — Arqueiro goblin
# pit_awareness=0.9: quase sempre detecta fosso, recua

extends "res://scripts/EnemyBase.gd"

@export var arrow_damage: float    = 12.0
@export var preferred_range: float = 220.0
@export var fire_cooldown: float   = 2.0

var _fire_timer: float = 0.0

@onready var game: Node = $"/root/GameManager"

func _ready() -> void:
	pit_awareness = 0.9
	hp            = max_hp
	_ready_base()

func _physics_process(delta: float) -> void:
	if _process_base(delta): return

	_fire_timer = max(_fire_timer - delta, 0.0)

	if not player:
		move_and_slide()
		return

	var dist = global_position.distance_to(player.global_position)
	if dist > detection_range:
		velocity.x = 0
		move_and_slide()
		return

	# Aviso de projétil iminente
	if dist <= preferred_range and _fire_timer <= 0.3:
		game.speak("Projétil")

	# Mantém distância preferida
	if dist < preferred_range - 30:
		# Recua — mas verifica fosso atrás também
		velocity.x = _safe_move_toward(global_position - (player.global_position - global_position).normalized() * preferred_range, speed)
	elif dist > preferred_range + 30:
		velocity.x = _safe_move_toward(player.global_position, speed)
	else:
		velocity.x = 0

	if dist <= preferred_range and _fire_timer <= 0:
		_fire_arrow()

	move_and_slide()

func _fire_arrow() -> void:
	_fire_timer = fire_cooldown
	var proj_scene = load("res://scenes/projectile.tscn")
	if not proj_scene: return
	var arrow            = proj_scene.instantiate()
	arrow.proj_type      = 0  # ARROW
	arrow.damage         = arrow_damage
	arrow.speed          = 280.0
	arrow.shooter        = self
	var dir              = (player.global_position - global_position).normalized()
	arrow.direction      = dir
	arrow.global_position = global_position + dir * 30
	get_parent().add_child(arrow)

# Arqueiro recua do fosso
func _pit_reaction(dir: float, spd: float) -> float:
	return -dir * spd   # recua
