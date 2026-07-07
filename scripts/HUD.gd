# HUD.gd — Interface de jogo
# Mostra HP do Kyle e habilidade ativa

extends CanvasLayer

@onready var hp_label: Label = $Container/HPLabel
@onready var skill_label: Label = $Container/SkillLabel
@onready var skill_level_label: Label = $Container/SkillLevelLabel
@onready var game: Node = $"/root/GameManager"

func _ready() -> void:
	# Conectar ao Kyle quando a cena estiver pronta
	call_deferred("_connect_to_kyle")
	_update_skill_display()

func _connect_to_kyle() -> void:
	var kyle = get_tree().get_first_node_in_group("player")
	if kyle:
		kyle.hp_changed.connect(_on_hp_changed)

func _on_hp_changed(new_hp: float) -> void:
	hp_label.text = "HP: %d" % int(new_hp)
	# Mudar cor conforme HP
	if new_hp > 60:
		hp_label.modulate = Color(0.2, 1.0, 0.3, 1)   # verde
	elif new_hp > 30:
		hp_label.modulate = Color(1.0, 0.8, 0.1, 1)   # amarelo
	else:
		hp_label.modulate = Color(1.0, 0.2, 0.1, 1)   # vermelho

func _update_skill_display() -> void:
	var skill = game.current_skill
	var name = game.SKILL_NAMES[skill]
	var level = game.skill_levels[skill]
	skill_label.text = "Habilidade: " + name
	skill_level_label.text = "Nv." + str(level)

func _process(_delta: float) -> void:
	# Atualizar habilidade em tempo real
	_update_skill_display()
