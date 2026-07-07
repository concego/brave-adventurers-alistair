# Kyle.gd — Controlador do personagem principal
# Recebe eventos do GestureController e executa ações

extends CharacterBody2D

@export var speed: float = 200.0
@export var max_hp: float = 100.0

var hp: float = 100.0
var is_attacking: bool = false
var is_blocking: bool = false
var is_shielded: bool = false
var shield_timer: float = 0.0

@onready var gesture: Node = $"/root/GestureController"
@onready var game: Node = $"/root/GameManager"
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	gesture.swipe_detected.connect(_on_swipe)
	game.player_heal.connect(_on_heal)
	game.player_shield.connect(_on_shield)

func _physics_process(delta: float) -> void:
	# Movimento contínuo — mão esquerda segurando
	var dir = gesture.get_left_hold_direction()
	if dir == "right":
		velocity.x = speed
		anim.play("walk")
	elif dir == "left":
		velocity.x = -speed
		anim.play("walk")
	else:
		velocity.x = 0
		if not is_attacking and not is_blocking:
			anim.play("idle")

	move_and_slide()

	# Escudo com timer
	if is_shielded:
		shield_timer -= delta
		if shield_timer <= 0:
			is_shielded = false

func _on_swipe(hand: String, direction: String) -> void:
	if hand == "right":
		match direction:
			"right":
				_attack_basic()
			"up":
				_jump()
			"down":
				_block()
			"left":
				game.use_skill(get_nearest_enemy())
	elif hand == "left":
		match direction:
			"up":
				game.next_skill()
			"down":
				game.prev_skill()

func _attack_basic() -> void:
	if is_attacking:
		return
	is_attacking = true
	anim.play("attack")
	await anim.animation_finished
	is_attacking = false

func _jump() -> void:
	anim.play("jump")

func _block() -> void:
	is_blocking = true
	anim.play("block")
	await get_tree().create_timer(0.5).timeout
	is_blocking = false

func _on_heal(amount: float) -> void:
	hp = min(hp + amount, max_hp)
	emit_signal("hp_changed", hp)

func _on_shield(duration: float) -> void:
	is_shielded = true
	shield_timer = duration

func take_damage(amount: float) -> void:
	if is_blocking:
		amount *= 0.2  # 80% de redução ao bloquear
	if is_shielded:
		amount = 0.0
	hp -= amount
	emit_signal("hp_changed", hp)
	if hp <= 0:
		_die()

func _die() -> void:
	anim.play("death")
	emit_signal("player_died")

func get_nearest_enemy() -> Node:
	# Retorna o inimigo mais próximo na cena
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node = null
	var nearest_dist: float = INF
	for e in enemies:
		var d = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest

signal hp_changed(new_hp)
signal player_died
