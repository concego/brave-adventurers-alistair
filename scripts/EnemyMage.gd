# EnemyMage.gd — Mago esqueleto: gelo e explosão de sombra, não pode ser deflectido

extends CharacterBody2D

@export var speed: float            = 50.0
@export var max_hp: float           = 45.0
@export var ice_damage: float       = 14.0
@export var shadow_damage: float    = 25.0
@export var preferred_range: float  = 250.0
@export var detection_range: float  = 380.0
@export var cast_cooldown: float    = 3.0

const GRAVITY: float = 980.0

var hp: float           = 45.0
var player: Node        = null
var _cast_timer: float  = 0.0
var _spell_index: int   = 0   # alterna entre gelo e sombra
var facing_right: bool  = false
var stun_timer: float   = 0.0

@onready var game: Node = $"/root/GameManager"

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_cast_timer = max(_cast_timer - delta, 0.0)

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

	# Mantém distância preferida
	if dist < preferred_range - 40:
		var dir = (global_position - player.global_position).normalized()
		velocity.x = dir.x * speed
		facing_right = dir.x > 0
	elif dist > preferred_range + 40:
		var dir = (player.global_position - global_position).normalized()
		velocity.x = dir.x * speed
		facing_right = dir.x > 0
	else:
		velocity.x = 0

	# Conjura magia
	if dist <= preferred_range and _cast_timer <= 0:
		_cast_spell()

	move_and_slide()

func _cast_spell() -> void:
	_cast_timer = cast_cooldown
	_spell_index = (_spell_index + 1) % 2

	var proj_scene = load("res://scenes/projectile.tscn")
	if not proj_scene:
		return

	var spell = proj_scene.instantiate()
	var dir   = (player.global_position - global_position).normalized()

	if _spell_index == 0:
		# Raio de gelo
		spell.proj_type = 3  # ICE_RAY
		spell.damage    = ice_damage
		spell.speed     = 320.0
		game.speak("Magia de gelo")
	else:
		# Explosão de sombra — mais lenta, mais dano
		spell.proj_type = 4  # SHADOW_BLAST
		spell.damage    = shadow_damage
		spell.speed     = 180.0
		game.speak("Magia sombria")

	spell.direction        = dir
	spell.shooter          = self
	spell.global_position  = global_position + dir * 30
	get_parent().add_child(spell)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		_die()

func stun(duration: float) -> void:
	stun_timer = duration
	velocity.x  = 0

func _die() -> void:
	remove_from_group("enemies")
	await get_tree().create_timer(0.4).timeout
	queue_free()
