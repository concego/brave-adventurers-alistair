# Enemy.gd — IA básica de inimigo
# Estados: patrol → chase → attack → flee (quando HP baixo)

extends CharacterBody2D

signal heavy_attack_warning
signal enemy_fleeing

@export var speed: float = 80.0
@export var max_hp: float = 50.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 60.0
@export var detection_range: float = 300.0
@export var flee_hp_threshold: float = 0.25

const GRAVITY: float = 980.0
const FRAME_W: int = 80
const FRAME_H: int = 96

var hp: float = 50.0
var state: String = "patrol"
var player: Node = null
var patrol_dir: float = 1.0
var patrol_timer: float = 0.0
var attack_cooldown: float = 0.0
var facing_right: bool = false

@onready var sprite: Sprite2D  = $Sprite2D
@onready var anim_timer: Timer = $AnimTimer

var _cur_anim: String = "idle"
var _cur_frame: int   = 0

# Spritesheet placeholder (vermelho monocromático até ter sprite definitivo)
const ANIM_ROW = {
	"idle": 0, "walk": 1, "attack": 2, "hit": 3, "death": 4
}
const ANIM_FRAMES = {"idle": 2, "walk": 4, "attack": 3, "hit": 2, "death": 4}
const ANIM_FPS    = {"idle": 6, "walk": 8, "attack": 12, "hit": 8, "death": 5}

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	if $AnimTimer:
		$AnimTimer.timeout.connect(_advance_frame)
		$AnimTimer.start(1.0 / ANIM_FPS["idle"])

func _advance_frame() -> void:
	if not sprite or not sprite.texture:
		return
	_cur_frame = (_cur_frame + 1) % ANIM_FRAMES.get(_cur_anim, 1)
	var row = ANIM_ROW.get(_cur_anim, 0)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(_cur_frame * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
	sprite.flip_h = facing_right

func _play_anim(anim: String) -> void:
	if _cur_anim == anim:
		return
	_cur_anim = anim
	_cur_frame = 0
	if $AnimTimer:
		$AnimTimer.wait_time = 1.0 / ANIM_FPS.get(anim, 6)
		$AnimTimer.start()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	attack_cooldown = max(attack_cooldown - delta, 0.0)

	match state:
		"patrol": _patrol(delta)
		"chase":  _chase()
		"attack": _do_attack()
		"flee":   _flee()

	move_and_slide()

func _patrol(delta: float) -> void:
	patrol_timer -= delta
	if patrol_timer <= 0:
		patrol_dir *= -1
		patrol_timer = randf_range(1.5, 3.0)

	velocity.x = speed * patrol_dir * 0.5
	facing_right = patrol_dir > 0
	_play_anim("walk")

	if player and global_position.distance_to(player.global_position) < detection_range:
		state = "chase"

func _chase() -> void:
	if not player:
		state = "patrol"
		return
	var dist = global_position.distance_to(player.global_position)
	if dist <= attack_range:
		state = "attack"
		return
	if dist > detection_range * 1.5:
		state = "patrol"
		return
	var dir = (player.global_position - global_position).normalized()
	velocity.x = dir.x * speed
	facing_right = dir.x > 0
	_play_anim("walk")

func _do_attack() -> void:
	if not player:
		state = "patrol"
		return
	var dist = global_position.distance_to(player.global_position)
	if dist > attack_range:
		state = "chase"
		return
	if attack_cooldown > 0.0:
		velocity.x = 0
		return

	# Avisa o jogador antes de golpear (cue acessível)
	emit_signal("heavy_attack_warning")
	_play_anim("attack")
	attack_cooldown = 1.2

	# Aplica dano depois de um pequeno delay (tempo para o jogador reagir)
	get_tree().create_timer(0.4).timeout.connect(func():
		if player and global_position.distance_to(player.global_position) <= attack_range:
			player.take_damage(attack_damage)
	)

func _flee() -> void:
	if not player:
		state = "patrol"
		return
	var dir = (global_position - player.global_position).normalized()
	velocity.x = dir.x * speed * 1.3
	facing_right = dir.x > 0
	_play_anim("walk")

func take_damage(amount: float) -> void:
	hp -= amount
	_play_anim("hit")
	if hp <= 0:
		_die()
		return
	if hp / max_hp <= flee_hp_threshold:
		state = "flee"
		emit_signal("enemy_fleeing")

func _die() -> void:
	remove_from_group("enemies")
	_play_anim("death")
	await get_tree().create_timer(0.8).timeout
	queue_free()
