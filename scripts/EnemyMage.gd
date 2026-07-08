# EnemyMage.gd — Mago esqueleto: para na borda, conjura de longe
# pit_awareness=1.0: sempre detecta fosso, nunca cai

extends "res://scripts/EnemyBase.gd"

@export var ice_damage: float       = 14.0
@export var shadow_damage: float    = 25.0
@export var preferred_range: float  = 250.0
@export var cast_cooldown: float    = 3.0

var _cast_timer: float = 0.0
var _spell_index: int  = 0

@onready var game: Node = $"/root/GameManager"

func _ready() -> void:
	pit_awareness = 1.0
	speed         = 50.0
	max_hp        = 45.0
	hp            = max_hp
	_ready_base()

func _physics_process(delta: float) -> void:
	if _process_base(delta): return

	_cast_timer = max(_cast_timer - delta, 0.0)

	if not player:
		move_and_slide()
		return

	var dist = global_position.distance_to(player.global_position)
	if dist > detection_range:
		velocity.x = 0
		move_and_slide()
		return

	# Mantém distância — para no fosso em vez de cruzar
	if dist < preferred_range - 40:
		velocity.x = _safe_move_toward(global_position - (player.global_position - global_position).normalized() * preferred_range, speed)
	elif dist > preferred_range + 40:
		velocity.x = _safe_move_toward(player.global_position, speed)
	else:
		velocity.x = 0

	if dist <= preferred_range and _cast_timer <= 0:
		_cast_spell()

	move_and_slide()

func _cast_spell() -> void:
	_cast_timer  = cast_cooldown
	_spell_index = (_spell_index + 1) % 2
	var proj_scene = load("res://scenes/projectile.tscn")
	if not proj_scene: return
	var spell        = proj_scene.instantiate()
	var dir          = (player.global_position - global_position).normalized()
	spell.shooter    = self
	spell.direction  = dir
	if _spell_index == 0:
		spell.proj_type = 3  # ICE_RAY
		spell.damage    = ice_damage
		spell.speed     = 320.0
		game.speak("Magia de gelo")
	else:
		spell.proj_type = 4  # SHADOW_BLAST
		spell.damage    = shadow_damage
		spell.speed     = 180.0
		game.speak("Magia sombria")
	spell.global_position = global_position + dir * 30
	get_parent().add_child(spell)

# Mago para na borda — nunca pula
func _pit_reaction(_dir: float, _spd: float) -> float:
	return 0.0
