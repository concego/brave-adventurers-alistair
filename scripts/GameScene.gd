# GameScene.gd — Controlador da fase (Fase 1: Vargheim)
# Responsabilidades: iniciar música, detectar vitória/derrota, transição

extends Node2D

@onready var game: Node = $"/root/GameManager"

func _ready() -> void:
	# Música da fase começa
	game.play_music(GameManager.MusicTrack.GAMEPLAY)
	game.speak("Capítulo um. Cinzas sobre Vargheim. Avance e encontre o Conde Mervyn.")

	# Conectar sinal de morte do Kyle
	var kyle = get_tree().get_first_node_in_group("player")
	if kyle:
		kyle.player_died.connect(_on_player_died)

func _on_player_died() -> void:
	# GameManager.respawn_player() já é chamado pelo Kyle._die()
	# Aqui podemos fazer efeitos extras futuramente
	pass

# Chamado quando todos os inimigos da fase morrem (pode ser conectado por sinal)
func _check_victory() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		_phase_complete()

func _phase_complete() -> void:
	game.speak("Fase concluída. Vargheim está livre.")
	game.fade_music(1.5)
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/chapter_screen.tscn")
