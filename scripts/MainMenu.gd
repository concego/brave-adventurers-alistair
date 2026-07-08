# MainMenu.gd — Menu principal com TTS e música

extends Control

@onready var game: Node = $"/root/GameManager"

var menu_items: Array = ["Novo Jogo", "Continuar", "Opções", "Sair"]
var focused_index: int = 0

# --- Áudio UI ---
@onready var sfx_select:  AudioStreamPlayer = $SfxSelect
@onready var sfx_confirm: AudioStreamPlayer = $SfxConfirm

func _ready() -> void:
	# Iniciar música do menu
	game.play_music(GameManager.MusicTrack.MENU)
	game.speak("Brave Adventurers: Alistair. Menu Principal. " + menu_items[focused_index])

func _on_item_focused(index: int) -> void:
	focused_index = index
	sfx_select.play()
	game.speak(menu_items[index])

func _on_new_game_pressed() -> void:
	sfx_confirm.play()
	game.speak("Iniciando novo jogo. Capítulo um. Cinzas sobre Vargheim.")
	game.fade_music(0.8)
	await get_tree().create_timer(0.9).timeout
	get_tree().change_scene_to_file("res://scenes/chapter_screen.tscn")

func _on_continue_pressed() -> void:
	sfx_select.play()
	game.speak("Continuar não disponível ainda")

func _on_options_pressed() -> void:
	sfx_confirm.play()
	game.speak("Opções")
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func _on_quit_pressed() -> void:
	sfx_confirm.play()
	game.speak("Saindo")
	game.fade_music(0.5)
	await get_tree().create_timer(0.6).timeout
	get_tree().quit()
