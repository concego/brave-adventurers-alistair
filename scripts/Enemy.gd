# Enemy.gd — IA de inimigo com sinalização de ataque para parry

extends CharacterBody2D

signal enemy_fleeing

@export var speed: float              = 80.0
@export var max_hp: float             = 50.0
@export var attack_damage: float      = 10.0
@export var attack_range: float       = 60.0
@export var detection_range: float    = 300.0
@export var flee_hp_threshold: float  = 0.25
@export var parry_window_time: float  = 0.35  # janela de parry em segundos

const GRAVITY: float = 980.0
const FRAME_W: int   = 80
const FRAME_H: int   = 96

var hp: float           = 50.0
var state: String       = "patrol"
var player: Node        = null
var patrol_dir: float   = 1.0
var patrol_timer: float = 0.0
var attack_cooldown: float = 0.0
var stun_timer: float   = 0.0
var facing_right: bool  = false

@onready var sprite: Sprite2D  = $Sprite2D
@onready var anim_timer: Timer = $AnimTimer

var _cur_anim: String = "idle"
var _cur_frame: int   = 0

const ANIM_ROW    = {"idle": 0, "walk": 1, "attack": 2, "hit": 3, "death": 4}
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
	sprite.region_enabled = true
	sprite.region_rect = Rect2(_cur_frame * FRAME_W, ANIM_ROW.get(_cur_anim, 0) * FRAME_H, FRAME_W, FRAME_H)
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

	# Atordoado — não faz nada
	if stun_timer > 0:
		stun_timer -= delta
		velocity.x = 0
		move_and_slide()
		return

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
		_play_anim("idle")
		return

	# --- Sinaliza o ataque: abre janela de parry no jogador ---
	if player.has_method("open_parry_window"):
		player.open_parry_window()

	_play_anim("attack")
	attack_cooldown = 1.4

	# Delay antes do golpe — tempo para o jogador reagir
	get_tree().create_timer(parry_window_time + 0.05).timeout.connect(func():
		if player and global_position.distance_to(player.global_position) <= attack_range * 1.2:
			if not player.is_blocking:
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

func stun(duration: float) -> void:
	stun_timer = duration
	velocity.x = 0

func _die() -> void:
	remove_from_group("enemies")
	_play_anim("death")
	_maybe_drop_item()
	await get_tree().create_timer(0.8).timeout
	queue_free()

func _maybe_drop_item() -> void:
	if randf() > 0.30:  # 30% de chance de drop
		return
	var item_scene = load("res://scenes/item.tscn")
	if not item_scene:
		return
	var item = item_scene.instantiate()
	# Tipo aleatório: 0=comida, 1=pocao_pequena, 2=pocao_grande, 3=elixir
	var weights = [0.40, 0.30, 0.15, 0.15]
	var roll = randf()
	var acc = 0.0
	var tipo = 0
	for i in range(weights.size()):
		acc += weights[i]
		if roll <= acc:
			tipo = i
			break
	item.item_type = tipo
	item.global_position = global_position
	get_parent().add_child(item)
