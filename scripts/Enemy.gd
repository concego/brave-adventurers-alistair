# Enemy.gd — IA básica de inimigo
# Estados: patrol → chase ‒ attack → flee (quando HP baixo)

extends CharacterBody2D

@export var speed: float = 80.0
@export var max_hp: float = 50.0
@export var attack_range: float = 60.0
@export var detection_range: float = 300.0
@export var flee_hp_threshold: float = 0.25  # fuge com 25% de HP

var hp: float = 50.0
var state: String = "patrol"
var player: Node = null
var patrol_dir: float = 1.0
var patrol_timer: float = 0.0

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	match state:
		"patrol":
			_patrol(delta)
		"chase":
			_chase(delta)
		"attack":
			_attack_player()
		"flee":
			_flee(delta)

func _patrol(delta: float) -> void:
	patrol_timer -= delta
	if patrol_timer <= 0:
		patrol_dir *= -1
		patrol_timer = randf_range(1.5, 3.0)

	velocity.x = speed * patrol_dir * 0.5
	move_and_slide()
	anim.play("walk")

	if player and global_position.distance_to(player.global_position) < detection_range:
		state = "chase"

func _chase(delta: float) -> void:
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
	move_and_slide()
	anim.play("walk")

func _attack_player() -> void:
	if not player:
		state = "patrol"
		return
	var dist = global_position.distance_to(player.global_position)
	if dist > attack_range:
		state = "chase"
		return
	# Som de preparação de golpe ─ sinal para o jogador reagir
	emit_signal("heavy_attack_warning")
	anim.play("attack")

func _flee(delta: float) -> void:
	if not player:
		state = "patrol"
		return
	var dir = (global_position - player.global_position).normalized()
	velocity.x = dir.x * speed * 1.3
	move_and_slide()
	anim.play("walk")

func take_damage(amount: float) -> void:
	bp -= amount
	anim.play("hit")
	if hp <= 0:
		_die()
		return
	if hp / max_hp <= flee_hp_threshold:
		state = "flee"
		emit_signal("enemy_fleeing")

func _die() -> void:
	remove_from_group("enemies")
	anim.play("death")
	await anim.animation_finished
	queue_free()

signal heavy_attack_warning
signal enemy_fleeing
