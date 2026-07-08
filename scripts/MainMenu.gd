# MainMenu.gd — Menu principal com TTS

extends Control

@onready var game: Node = $"/root/GameManager"

var menu_items: Array = ["Novo Jogo", "Continuar", "Opções", "Sair"]
var focused_index: int = 0

func _ready() -> void:
	game.speak("Brave Adventurers: Alistair. Menu Principal. " + menu_items[focused_index])

func _on_item_focused(index: int) -> void:
	focused_index = index
	game.speak(menu_items[index])

func _on_new_game_pressed() -> void:
	game.speak("Iniciando novo jogo. Capítulo um. Cinzas sobre Vargheim.")
	get_tree().change_scene_to_file("res://scenes/chapter_screen.tscn")

func _on_continue_pressed() -> void:
	game.speak("Continuar não disponível ainda")

func _on_options_pressed() -> void:
	game.speak("Opções")
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func _on_quit_pressed() -> void:
	game.speak("Saindo")
	get_tree().quit()
