# HUD.gd — Interface do jogador
# Barras de HP e Energia + feedback de stats

extends CanvasLayer

@onready var hp_bar: ProgressBar     = $HUDContainer/HPBar
@onready var energy_bar: ProgressBar = $HUDContainer/EnergyBar
@onready var hp_label: Label         = $HUDContainer/HPLabel
@onready var energy_label: Label     = $HUDContainer/EnergyLabel
@onready var stat_label: Label       = $StatPopup
@onready var stat_timer: Timer       = $StatTimer

func _ready() -> void:
	# Conectar sinais do Kyle assim que ele entrar na cena
	call_deferred("_connect_player")
	stat_label.modulate.a = 0.0

func _connect_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.hp_changed.connect(_on_hp_changed)
		player.energy_changed.connect(_on_energy_changed)
		player.stat_increased.connect(_on_stat_increased)
		# Inicializar barras
		_on_hp_changed(player.hp, player.max_hp)
		_on_energy_changed(player.energy, player.max_energy)

func _on_hp_changed(new_hp: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = new_hp
	hp_label.text = "Vida: " + str(int(new_hp)) + "/" + str(int(max_hp))
	# Pulsa vermelho quando HP baixo
	if new_hp / max_hp <= 0.25:
		hp_bar.modulate = Color(1.0, 0.3, 0.3)
	else:
		hp_bar.modulate = Color(1.0, 1.0, 1.0)

func _on_energy_changed(new_energy: float, max_energy: float) -> void:
	energy_bar.max_value = max_energy
	energy_bar.value = new_energy
	energy_label.text = "Energia: " + str(int(new_energy)) + "/" + str(int(max_energy))
	if new_energy / max_energy <= 0.30:
		energy_bar.modulate = Color(1.0, 0.7, 0.2)
	else:
		energy_bar.modulate = Color(1.0, 1.0, 1.0)

func _on_stat_increased(stat_name: String, new_value: float) -> void:
	var txt = ""
	if stat_name == "ataque":
		txt = "⚔ Ataque " + str(int(new_value))
	elif stat_name == "defesa":
		txt = "🛡 Defesa " + str(int(new_value * 100)) + "%"
	stat_label.text = txt
	# Fade in / out do popup
	var tween = create_tween()
	tween.tween_property(stat_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.5)
	tween.tween_property(stat_label, "modulate:a", 0.0, 0.4)
