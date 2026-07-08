# Kyle.gd — Controlador do personagem principal
# Progressão por uso: ataque aumenta ao acertar, defesa ao usar escudo
# Sprite: kyle_spritesheet.webp (6 anims x 4 frames: Idle/Walk/Run/Attack/Jump/Dead)

extends CharacterBody2D

signal hp_changed(new_hp)
signal player_died
signal stat_increased(stat_name: String, new_value: float)

@export var speed: float = 200.0
@export var jump_force: float = -400.0
@export var max_hp: float = 100.0

# --- Stats base (crescem com uso) ---
var attack_power: float  = 25.0   # +2 a cada acerto confirmado
var defense_rate: float  = 0.80   # redução de dano ao bloquear — começa em 80%, sobe até 95%
var attack_hits: int     = 0      # contador de acertos
var block_uses: int      = 0      # contador de bloqueios usados

const ATTACK_XP_PER_LEVEL: int = 5   # acertos para subir ataque
const DEFENSE_XP_PER_LEVEL: int = 4  # bloqueios para subir defesa
const ATTACK_GAIN: float        = 2.0
const DEFENSE_GAIN: float       = 0.02   # +2% de redução por nível
const DEFENSE_MAX: float        = 0.95   # cap: 95% de redução

var hp: float = 100.0
var is_attacking: bool = false
var is_blocking: bool  = false
var is_shielded: bool  = false
var shield_timer: float = 0.0
var facing_right: bool = true

const GRAVITY: float = 980.0
const FRAME_W: int = 80
const FRAME_H: int = 96
const ANIM_ROW = {
	"idle": 0, "walk": 1, "run": 2, "attack": 3, "jump": 4, "death": 5
}
const ANIM_FRAMES = {
	"idle": 4, "walk": 4, "run": 4, "attack": 4, "jump": 4, "death": 4
}
const ANIM_FPS = {
	"idle": 8, "walk": 10, "run": 12, "attack": 14, "jump": 8, "death": 6
}

@onready var sprite: Sprite2D  = $Sprite2D
@onready var anim_timer: Timer = $AnimTimer
@onready var gesture: Node     = $"/root/GestureController"
@onready var game: Node        = $"/root/GameManager"

var _cur_anim: String = "idle"
var _cur_frame: int   = 0

func _ready() -> void:
	add_to_group("player")
	sprite.texture = load("res://assets/sprites/kyle_spritesheet.webp")
	_set_frame("idle", 0)
	anim_timer.wait_time = 1.0 / ANIM_FPS["idle"]
	anim_timer.autostart = true
	anim_timer.timeout.connect(_advance_frame)
	gesture.swipe_detected.connect(_on_swipe)
	game.player_heal.connect(_on_heal)
	game.player_shield.connect(_on_shield)

# --- Sprite ---
func _set_frame(anim: String, frame: int) -> void:
	sprite.region_enabled = true
	sprite.region_rect = Rect2(frame * FRAME_W, ANIM_ROW[anim] * FRAME_H, FRAME_W, FRAME_H)
	sprite.flip_h = not facing_right

func _play_anim(anim: String) -> void:
	if _cur_anim == anim:
		return
	_cur_anim = anim
	_cur_frame = 0
	anim_timer.wait_time = 1.0 / ANIM_FPS[anim]
	anim_timer.start()
	_set_frame(anim, 0)

func _advance_frame() -> void:
	_cur_frame = (_cur_frame + 1) % ANIM_FRAMES[_cur_anim]
	_set_frame(_cur_anim, _cur_frame)

# --- Física ---
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var dir = gesture.get_left_hold_direction()
	if dir == "right":
		velocity.x = speed
		facing_right = true
		_play_anim("walk")
	elif dir == "left":
		velocity.x = -speed
		facing_right = false
		_play_anim("walk")
	else:
		velocity.x = 0
		if not is_attacking and not is_blocking and is_on_floor():
			_play_anim("idle")

	move_and_slide()

	if is_shielded:
		shield_timer -= delta
		if shield_timer <= 0:
			is_shielded = false

# --- Ações ---
func _on_swipe(hand: String, direction: String) -> void:
	if hand == "right":
		match direction:
			"right": _attack_basic()
			"up":    _jump()
			"down":  _block()
			"left":  game.use_skill(get_nearest_enemy())
	elif hand == "left":
		match direction:
			"up":   game.next_skill()
			"down": game.prev_skill()

func _attack_basic() -> void:
	if is_attacking:
		return
	is_attacking = true
	_play_anim("attack")

	var dir_x = 1.0 if facing_right else -1.0
	var hit_area = Rect2(global_position + Vector2(dir_x * 40, -30), Vector2(60, 60))
	var hit_something = false

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if hit_area.has_point(enemy.global_position):
			enemy.take_damage(attack_power)
			hit_something = true

	if hit_something:
		_register_attack_hit()

	await get_tree().create_timer(0.35).timeout
	is_attacking = false

func _jump() -> void:
	if is_on_floor():
		velocity.y = jump_force
		_play_anim("jump")

func _block() -> void:
	is_blocking = true
	_register_block_use()
	await get_tree().create_timer(0.5).timeout
	is_blocking = false

# --- Progressão por uso ---
func _register_attack_hit() -> void:
	attack_hits += 1
	if attack_hits % ATTACK_XP_PER_LEVEL == 0:
		attack_power += ATTACK_GAIN
		var level = attack_hits / ATTACK_XP_PER_LEVEL
		game.speak("Ataque fortalecido. Nível " + str(level) + ". Dano: " + str(int(attack_power)))
		emit_signal("stat_increased", "ataque", attack_power)

func _register_block_use() -> void:
	block_uses += 1
	if block_uses % DEFENSE_XP_PER_LEVEL == 0:
		defense_rate = min(defense_rate + DEFENSE_GAIN, DEFENSE_MAX)
		var pct = int(defense_rate * 100)
		var level = block_uses / DEFENSE_XP_PER_LEVEL
		game.speak("Defesa fortalecida. Nível " + str(level) + ". Redução: " + str(pct) + " por cento")
		emit_signal("stat_increased", "defesa", defense_rate)

# --- Dano / cura ---
func take_damage(amount: float) -> void:
	if is_blocking:
		amount *= (1.0 - defense_rate)
	if is_shielded:
		amount = 0.0
	hp -= amount
	emit_signal("hp_changed", hp)
	if hp <= 0:
		_die()

func _on_heal(amount: float) -> void:
	hp = min(hp + amount, max_hp)
	emit_signal("hp_changed", hp)

func _on_shield(duration: float) -> void:
	is_shielded = true
	shield_timer = duration

func _die() -> void:
	_play_anim("death")
	emit_signal("player_died")

# --- Utilitário ---
func get_nearest_enemy() -> Node:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node = null
	var nearest_dist: float = INF
	for e in enemies:
		var d = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest
