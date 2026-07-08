# ChapterScreen.gd — Tela de capítulo (livro)
# Exibe texto narrativo sobre o livro aberto, com sprites laterais e TTS
# Transição: swipe direita ou toque para continuar

extends Control

signal chapter_finished

@export var chapter_number: int = 1
@export var next_scene: String = "res://scenes/game.tscn"

const CHAPTER_TITLES = {
	1: "Capítulo I — Cinzas sobre Vargheim",
	2: "Capítulo II — O Que os Corvos Ouviram",
	3: "Capítulo III — O Selo e a Mentira",
	4: "Capítulo IV — A Confissão do Mercenário",
	5: "Capítulo V — Diante do Rei",
	6: "Epílogo — O Lobo Volta para Casa"
}

const CHAPTER_TEXTS = {
	1: "Ouça, tu que carregas o peso dos anos.\nOuça, como os lobos perderam sua terra.\n\nVargheim foi erguida onde Yggdrasil lança sua sombra mais longa. Ali, o povo do Lobo esculpiu runas nas pedras antes mesmo de haver reis para temer.\n\nVeio o sul com papéis em vez de espadas. Cada runa apagada. Cada nome antigo proibido.\n\nMas as sombras não esperam a vitória de ninguém.\n\nKyle Alistair ficou de joelhos entre as cinzas.\nE clamou ao Pai de Todos.\nAo Pendurado. Ao Senhor dos Corvos.\n\nAssim foi forjado o último paladino de Vargheim.",
	2: "Os derrotados não escolhem quem os salva.\n\nEntre as pedras de Vargheim, Kyle encontrou soldados do rei — feridos e abandonados pela própria coroa.\n\nKyle os curou com as mesmas mãos que havia usado para lutar.\n\nFoi um deles quem falou:\n\n\"O Conde Mervyn mandou abrir os portões do leste.\nEle deixou os orques passar.\"\n\nOs orques não haviam vindo do acaso.\nAlguém os havia convidado.\nE esse alguém usava o brasão do rei.",
	3: "A guerra aberta tem sua honra.\nA traição não tem nenhuma.\n\nFoi entre os refugiados que a segunda peça se encaixou.\n\nUma criança trouxe nas mãos um objeto encontrado num acampamento orque abandonado.\nUm selo.\nCom o brasão do Conde Mervyn.\n\nAs Nornas às vezes deixam uma ponta solta — para que os atentos possam puxar.\n\nKyle guardou o selo junto ao escudo do Lobo.\nE adentrou a floresta.",
	4: "Há palavras que só saem quando não há mais escolha.\n\nNa floresta, entre os trolls, moviam-se homens com espadas sem brasão. Mercenários.\n\nKyle capturou um.\n\n\"Mervyn prometeu as terras do norte aos líderes orques. Um rei enfraquecido abdica. Mervyn sobe. O norte vira recompensa de guerra.\"\n\nKyle olhou para o céu através das copas.\nDois corvos pousaram num galho alto.\nObservaram. Voaram.\n\nO Pendurado já sabia o que precisava ser feito.",
	5: "Há salões que foram construídos para intimidar.\nO salão do Rei Aldric era um deles.\n\nKyle entrou com o escudo do Lobo no braço e o selo do traidor na mão.\n\nO rei o encarou do alto do trono.\nKyle encarou de volta — sem curvar a cabeça.\n\nKyle pôs o selo sobre os degraus de pedra.\n\n\"Conde Mervyn abriu as portas para os invasores. Seu povo e o meu sangraram pelo ambicioso de um único homem.\"\n\nO Conde Mervyn ainda respirava dentro daquelas paredes.",
	6: "Kyle Alistair não aceitou o título.\n\nO rei o ofereceu com toda a pompa. Kyle ouviu em silêncio. E falou apenas uma coisa:\n\n\"Devolva Vargheim ao seu povo.\"\n\nO decreto foi assinado ao amanhecer.\n\nKyle partiu antes do meio-dia, sem fanfarra, sem escolta.\nSó o escudo. Só a estrada. Só os dois corvos que subiram ao céu, satisfeitos.\n\nO Pendurado cuida dos seus.\nMas os seus precisam saber o que pedir.\n\nVargheim o esperava.\nO Lobo voltou para casa.\n\n— Fim da Saga de Kyle Alistair —"
}

@onready var book_bg: TextureRect         = $BookBG
@onready var title_label: Label           = $BookContent/Title
@onready var text_label: Label            = $BookContent/Text
@onready var continue_label: Label        = $ContinueHint
@onready var page_flip_sound: AudioStreamPlayer = $PageFlipSound
@onready var raven_sprite: AnimatedSprite2D = $RavenSprite
@onready var anim: AnimationPlayer        = $AnimationPlayer
@onready var game_manager: Node           = $"/root/GameManager"

var _can_continue: bool = false

func _ready() -> void:
	title_label.text = CHAPTER_TITLES.get(chapter_number, "")
	text_label.text  = CHAPTER_TEXTS.get(chapter_number, "")
	continue_label.modulate.a = 0.0
	_can_continue = false

	# Música de capítulo
	game_manager.play_music(GameManager.MusicTrack.CHAPTER)

	# Som de virar página
	page_flip_sound.play()

	# Animação de entrada
	anim.play("fade_in")

	# TTS lê título + texto
	await get_tree().create_timer(0.8).timeout
	var full_text = CHAPTER_TITLES.get(chapter_number, "") + ". " + CHAPTER_TEXTS.get(chapter_number, "")
	game_manager.speak(full_text)

	var read_time = full_text.length() * 0.045
	await get_tree().create_timer(read_time).timeout
	_can_continue = true
	_pulse_continue()

func _pulse_continue() -> void:
	continue_label.modulate.a = 1.0
	var tween = create_tween().set_loops()
	tween.tween_property(continue_label, "modulate:a", 0.2, 0.8)
	tween.tween_property(continue_label, "modulate:a", 1.0, 0.8)

func _input(event: InputEvent) -> void:
	if not _can_continue:
		return
	if event is InputEventScreenTouch and event.pressed:
		_go_next()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_go_next()

func _go_next() -> void:
	_can_continue = false
	page_flip_sound.play()
	anim.play("fade_out")
	await anim.animation_finished
	# Fade music antes de entrar na fase
	game_manager.fade_music(0.5)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file(next_scene)
