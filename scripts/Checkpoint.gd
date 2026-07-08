# Checkpoint.gd — Ponto de salvamento fixo na fase
# Ao ativar: salva posição do jogador e anuncia via TTS
# Ao morrer: GameManager chama respawn() no checkpoint ativo

extends Area2D

signal checkpoint_activated(checkpoint: Node)

@export var checkpoint_id: int = 0

var is_active: bool = false

@onready var game: Node   = $"/root/GameManager"
@onready var sprite: Node = $Sprite2D

# --- Áudio ---
@onready var sfx_checkpoint: AudioStreamPlayer = $SfxCheckpoint

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("checkpoints")
	_update_visual()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if is_active:
		return
	_activate()

func _activate() -> void:
	is_active = true
	emit_signal("checkpoint_activated", self)
	game.set_active_checkpoint(self)
	sfx_checkpoint.play()
	game.speak("Checkpoint ativado")
	_update_visual()

func respawn(player: Node) -> void:
	if not player or not is_instance_valid(player):
		return
	player.global_position = global_position + Vector2(0, -40)
	player.velocity        = Vector2.ZERO
	player.hp              = player.max_hp
	player.energy          = player.max_energy
	game.speak("Respawn")

func deactivate() -> void:
	is_active = false
	_update_visual()

func _update_visual() -> void:
	if not sprite:
		return
	if sprite.has_method("set"):
		sprite.modulate = Color(1.0, 0.85, 0.1) if is_active else Color(0.5, 0.5, 0.5)
