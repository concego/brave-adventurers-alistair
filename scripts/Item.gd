# Item.gd — Item de chão coletado automaticamente ao tocar
# Tipos: 0=comida, 1=pocao_pequena, 2=pocao_grande, 3=elixir

extends Area2D

enum ItemType { COMIDA, POCAO_PEQUENA, POCAO_GRANDE, ELIXIR }

@export var item_type: int = ItemType.COMIDA

const ITEM_DATA = {
	ItemType.COMIDA:        { "hp": 20,  "energy": 0,  "name": "Pão. Vida recuperada",          "color": Color(0.85, 0.65, 0.20) },
	ItemType.POCAO_PEQUENA: { "hp": 0,   "energy": 30, "name": "Poção. Energia recuperada",      "color": Color(0.20, 0.50, 0.90) },
	ItemType.POCAO_GRANDE:  { "hp": 0,   "energy": 60, "name": "Poção forte. Energia recuperada","color": Color(0.10, 0.20, 0.80) },
	ItemType.ELIXIR:        { "hp": 15,  "energy": 15, "name": "Elixir. Vida e energia",          "color": Color(0.20, 0.80, 0.30) },
}

@onready var sprite: ColorRect = $ColorRect
@onready var game: Node        = $"/root/GameManager"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_visuals()

func _apply_visuals() -> void:
	var data = ITEM_DATA.get(item_type, ITEM_DATA[ItemType.COMIDA])
	if sprite:
		sprite.color = data["color"]

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var data = ITEM_DATA.get(item_type, ITEM_DATA[ItemType.COMIDA])
	if data["hp"] > 0 and body.has_method("heal"):
		body.heal(data["hp"])
	if data["energy"] > 0 and body.has_method("restore_energy"):
		body.restore_energy(data["energy"])
	game.speak(data["name"])
	queue_free()
