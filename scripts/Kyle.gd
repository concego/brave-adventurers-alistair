# Kyle.gd — Controlador do personagem principal
# Sistema: Energia única, parry, ataque focado, progressão por uso

extends CharacterBody2D

signal hp_changed(new_hp: float, max_hp: float)
signal energy_changed(new_energy: float, max_energy: float)
signal stat_increased(stat_name: String, new_value: float)
signal player_died

# --- Stats base ---
@export var speed: float         = 200.0
@export var jump_force: float    = -400.0
@export var max_hp: float        = 100.0
@export var max_energy: float    = 100.0

# --- Progressão ---
var attack_power: float  = 10.0
var defense_reduction: float = 0.30   # 30% redução bloqueio normal
var attack_hits: int     = 0
var block_uses: int      = 0

const ATK_XP_PER_LEVEL: int   = 8
const DEF_XP_PER_LEVEL: int   = 6
const ATK_GAIN: float          = 3.0
const DEF_GAIN: float          = 0.05
const DEF_MAX: float           = 0.80

# --- Estado ---
var hp: float            = 100.0
var energy: float        = 100.0
var is_attacking: bool   = false
var is_blocking: bool    = false
var is_shielded: bool    = false
var shield_timer: float  = 0.0
var facing_right: bool   = true
var in_combat: bool      = false
var combat_timer: float  = 0.0

# --- Ataque focado ---
var charge_time: float   = 0.0
var is_charging: bool    = false
const CHARGE_MAX: float  = 0.8    # segundos para carga máxima
const CHARGE_MIN: float  = 0.3    # mínimo para ativar crítico

# --- Parry ---
var parry_window: bool   = false  # true quando inimigo sinalizou ataque

# --- Energia ---
const ENERGY_REGEN_COMBAT: float    = 8.0
const ENERGY_REGEN_OUT: float       = 20.0
const ENERGY_ATTACK_QUICK: float    = 10.0
const ENERGY_ATTACK_FOCUSED: float  = 25.0
const ENERGY_PARRY: float           = 15.0
const ENERGY_BLOCK_PER_SEC: float   = 5.0
const ENERGY_PARRY_BONUS: float     = 20.0
const ENERGY_LOW_THRESHOLD: float   = 30.0

const GRAVITY: float = 980.0
const FRAME_W: int   = 80
const FRAME_H: int   = 96
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
var _energy_warned: bool = false

func _ready() -> void:
	add_to_group("player")
	sprite.texture = load("res://assets/sprites/kyle_spritesheet.webp")
	_set_frame("idle", 0)
	anim_timer.wait_time = 1.0 / ANIM_FPS["idle"]
	anim_timer.autostart = true
	anim_timer.timeout.connect(_advance_frame)
	gesture.swipe_detected.connect(_on_swipe)
	gesture.hold_started.connect(_on_hold_started)
	gesture.hold_released.connect(_on_hold_released)
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

# --- Física e regeneração ---
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Carga de ataque focado
	if is_charging:
		charge_time += delta
		if charge_time >= CHARGE_MAX:
			charge_time = CHARGE_MAX  # cap

	# Bloqueio consome energia por segundo
	if is_blocking:
		_spend_energy(ENERGY_BLOCK_PER_SEC * delta)

	# Regeneração de energia
	var regen = ENERGY_REGEN_COMBAT if in_combat else ENERGY_REGEN_OUT
	_gain_energy(regen * delta)

	# Timer de combate (sai do combate após 4s sem tomar/dar dano)
	if in_combat:
		combat_timer -= delta
		if combat_timer <= 0:
			in_combat = false

	# Movimento
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

# --- Energia ---
func _spend_energy(amount: float) -> void:
	energy = max(energy - amount, 0.0)
	emit_signal("energy_changed", energy, max_energy)
	if energy < ENERGY_LOW_THRESHOLD and not _energy_warned:
		_energy_warned = true
		game.speak("Energia baixa")
	elif energy >= ENERGY_LOW_THRESHOLD:
		_energy_warned = false

func _gain_energy(amount: float) -> void:
	var before = energy
	energy = min(energy + amount, max_energy)
	if energy != before:
		emit_signal("energy_changed", energy, max_energy)

func _has_energy(amount: float) -> bool:
	if energy < amount:
		game.speak("Sem energia")
		return false
	return true

# --- Swipes ---
func _on_swipe(hand: String, direction: String) -> void:
	if hand == "right":
		match direction:
			"right": _attack_quick()
			"up":    _jump()
			"down":  _try_parry()
			"left":  game.use_skill(get_nearest_enemy())
	elif hand == "left":
		match direction:
			"up":   game.next_skill()
			"down": game.prev_skill()

# --- Ataque rápido ---
func _attack_quick() -> void:
	if is_attacking or not _has_energy(ENERGY_ATTACK_QUICK):
		return
	_spend_energy(ENERGY_ATTACK_QUICK)
	is_attacking = true
	in_combat = true
	combat_timer = 4.0
	_play_anim("attack")
	var dir_x = 1.0 if facing_right else -1.0
	var hit_area = Rect2(global_position + Vector2(dir_x * 40, -30), Vector2(60, 60))
	var hit = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if hit_area.has_point(enemy.global_position):
			enemy.take_damage(attack_power)
			hit = true
	if hit:
		_register_attack_hit(1)
	await get_tree().create_timer(0.3).timeout
	is_attacking = false

# --- Ataque focado (hold) ---
func _on_hold_started(hand: String) -> void:
	if hand == "right" and not is_attacking:
		is_charging = true
		charge_time = 0.0

func _on_hold_released(hand: String) -> void:
	if hand != "right" or not is_charging:
		return
	is_charging = false
	if charge_time >= CHARGE_MIN and _has_energy(ENERGY_ATTACK_FOCUSED):
		_attack_focused()
	else:
		_attack_quick()

func _attack_focused() -> void:
	if is_attacking:
		return
	_spend_energy(ENERGY_ATTACK_FOCUSED)
	is_attacking = true
	in_combat = true
	combat_timer = 4.0
	_play_anim("attack")
	var ratio = clamp(charge_time / CHARGE_MAX, 0.0, 1.0)
	var damage = attack_power * (1.5 + ratio * 0.5)  # 1.5x a 2.0x
	var stun_time = 0.5 + ratio * 0.5
	var dir_x = 1.0 if facing_right else -1.0
	var hit_area = Rect2(global_position + Vector2(dir_x * 40, -40), Vector2(80, 80))
	var hit = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if hit_area.has_point(enemy.global_position):
			enemy.take_damage(damage)
			enemy.stun(stun_time)
			hit = true
	if hit:
		game.speak("Golpe crítico")
		_register_attack_hit(3)
	await get_tree().create_timer(0.4).timeout
	is_attacking = false

# --- Parry ---
func _try_parry() -> void:
	if parry_window and _has_energy(ENERGY_PARRY):
		# Parry bem-sucedido
		_spend_energy(ENERGY_PARRY)
		_gain_energy(ENERGY_PARRY_BONUS)
		is_blocking = true
		game.speak("Parry")
		_register_block_use(3)
		# Atordoa todos os inimigos que estavam atacando
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.has_method("stun"):
				enemy.stun(1.0)
		await get_tree().create_timer(0.3).timeout
		is_blocking = false
	else:
		# Bloqueio normal
		if not _has_energy(5.0):
			return
		is_blocking = true
		_register_block_use(1)
		await get_tree().create_timer(0.5).timeout
		is_blocking = false

func open_parry_window() -> void:
	parry_window = true
	await get_tree().create_timer(0.35).timeout
	parry_window = false

# --- Pulo ---
func _jump() -> void:
	if is_on_floor():
		velocity.y = jump_force
		_play_anim("jump")

# --- Progressão ---
func _register_attack_hit(xp: int) -> void:
	attack_hits += xp
	var level = attack_hits / ATK_XP_PER_LEVEL
	var prev_level = (attack_hits - xp) / ATK_XP_PER_LEVEL
	if level > prev_level:
		attack_power += ATK_GAIN
		game.speak("Ataque fortalecido. Nível " + str(level) + ". Dano " + str(int(attack_power)))
		emit_signal("stat_increased", "ataque", attack_power)

func _register_block_use(xp: int) -> void:
	block_uses += xp
	var level = block_uses / DEF_XP_PER_LEVEL
	var prev_level = (block_uses - xp) / DEF_XP_PER_LEVEL
	if level > prev_level:
		defense_reduction = min(defense_reduction + DEF_GAIN, DEF_MAX)
		var pct = int(defense_reduction * 100)
		game.speak("Defesa fortalecida. Nível " + str(level) + ". Redução " + str(pct) + " por cento")
		emit_signal("stat_increased", "defesa", defense_reduction)

# --- Dano / cura ---
func take_damage(amount: float) -> void:
	in_combat = true
	combat_timer = 4.0
	if is_blocking:
		amount *= (1.0 - defense_reduction)
	if is_shielded:
		amount = 0.0
	hp -= amount
	emit_signal("hp_changed", hp, max_hp)
	if hp <= 0:
		_die()

func _on_heal(amount: float) -> void:
	hp = min(hp + amount, max_hp)
	emit_signal("hp_changed", hp, max_hp)

func _on_shield(duration: float) -> void:
	is_shielded = true
	shield_timer = duration

func heal(amount: float) -> void:
	hp = min(hp + amount, max_hp)
	emit_signal("hp_changed", hp, max_hp)

func restore_energy(amount: float) -> void:
	_gain_energy(amount)

func _die() -> void:
	_play_anim("death")
	emit_signal("player_died")

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
