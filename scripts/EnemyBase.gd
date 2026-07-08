# EnemyBase.gd — Comportamentos universais herdados por todos os inimigos
# Status: frozen, knockback, detecção de fosso

extends CharacterBody2D

# --- Stats base (sobrescrever no filho) ---
@export var speed: float           = 80.0
@export var max_hp: float          = 50.0
@export var detection_range: float = 300.0
@export var pit_awareness: float   = 0.7   # 0=cego, 1=perfeito. Controla chance de detectar fosso

const GRAVITY: float  = 980.0
const PIT_RAY_DIST: float = 48.0   # distância do raycast à frente para detectar vazio

var hp: float          = 50.0
var player: Node       = null
var stun_timer: float  = 0.0
var facing_right: bool = false

# --- Status ---
var _statuses: Dictionary = {}   # {"frozen": 1.2, "slow": 2.0}
var _knockback: Vector2   = Vector2.ZERO

func _ready_base() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")

# Chamar no _physics_process do filho antes de qualquer lógica
func _process_base(delta: float) -> bool:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Knockback decai
	if _knockback.length() > 0:
		velocity += _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, 600 * delta)

	# Status tick
	_tick_statuses(delta)

	# Congelado — não faz nada
	if stun_timer > 0:
		stun_timer -= delta
		velocity.x = 0
		move_and_slide()
		return true   # bloqueado

	if has_status("frozen"):
		velocity.x = 0
		move_and_slide()
		return true   # bloqueado

	return false   # livre pra agir

func _tick_statuses(delta: float) -> void:
	var expired = []
	for s in _statuses:
		_statuses[s] -= delta
		if _statuses[s] <= 0:
			expired.append(s)
	for s in expired:
		_statuses.erase(s)

# --- API pública ---
func apply_status(status: String, duration: float) -> void:
	_statuses[status] = duration

func has_status(status: String) -> bool:
	return _statuses.has(status)

func apply_knockback(force: Vector2) -> void:
	_knockback += force

func stun(duration: float) -> void:
	stun_timer = duration
	velocity.x = 0

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		_die()

func _die() -> void:
	remove_from_group("enemies")
	_maybe_drop_item()
	await get_tree().create_timer(0.4).timeout
	queue_free()

func _maybe_drop_item() -> void:
	if randf() > 0.30:
		return
	var item_scene = load("res://scenes/item.tscn")
	if not item_scene:
		return
	var item = item_scene.instantiate()
	var weights = [0.40, 0.30, 0.15, 0.15]
	var roll = randf()
	var acc  = 0.0
	var tipo = 0
	for i in range(weights.size()):
		acc += weights[i]
		if roll <= acc:
			tipo = i
			break
	item.item_type        = tipo
	item.global_position  = global_position
	get_parent().add_child(item)

# --- Detecção de fosso ---
# Retorna true se há vazio à frente (baseado em pit_awareness)
func _pit_ahead() -> bool:
	# Chance de ignorar o fosso baseada em pit_awareness
	# pit_awareness=1.0 → sempre detecta; 0.0 → nunca detecta (cego)
	if randf() > pit_awareness:
		return false

	var space   = get_world_2d().direct_space_state
	var dir_x   = 1.0 if facing_right else -1.0
	var origin  = global_position + Vector2(dir_x * 20, 0)
	var target  = origin + Vector2(0, PIT_RAY_DIST)
	var query   = PhysicsRayQueryParameters2D.create(origin, target)
	query.exclude = [self]
	var result  = space.intersect_ray(query)
	return result.is_empty()   # sem chão à frente = fosso

# --- Movimento seguro (usa detecção de fosso) ---
# Retorna a velocidade X ajustada; filho chama isso no lugar de setar velocity.x direto
func _safe_move_toward(target_pos: Vector2, spd: float) -> float:
	var dir = sign(target_pos.x - global_position.x)
	facing_right = dir > 0

	if _pit_ahead():
		# Tenta parar ou recuar dependendo do tipo
		return _pit_reaction(dir, spd)

	return dir * spd

func _pit_reaction(move_dir: float, spd: float) -> float:
	# Base: para na borda — filhos sobrescrevem pra pular ou recuar
	return 0.0
