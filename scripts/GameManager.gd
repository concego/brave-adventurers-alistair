# GameManager.gd — Autoload singleton
# Gerencia estado global: TTS, skills do Kyle, level, HP

extends Node

# --- TTS ---
func speak(text: String) -> void:
	if OS.get_name() == "Android":
		DisplayServer.tts_speak(text, DisplayServer.tts_get_voices()[0] if DisplayServer.tts_get_voices().size() > 0 else "", 100)
	else:
		print("[TTS] " + text)

# --- Kyle Alistair — Habilidades ---
enum Skill {
	GOLPE_SAGRADO,
	IMPOSICAO_DE_MAOS,
	ESCUDO_DA_FE,
	JULGAMENTO
}

const SKILL_NAMES = {
	Skill.GOLPE_SAGRADO:        "Golpe Sagrado",
	Skill.IMPOSICAO_DE_MAOS:   "Imposição de Mãos",
	Skill.ESCUDO_DA_FE:        "Escudo da Fé",
	Skill.JULGAMENTO:          "Julgamento"
}

var skill_levels = {
	Skill.GOLPE_SAGRADO:     1,
	Skill.IMPOSICAO_DE_MAOS: 1,
	Skill.ESCUDO_DA_FE:      1,
	Skill.JULGAMENTO:        1
}

var skill_xp = {
	Skill.GOLPE_SAGRADO:     0,
	Skill.IMPOSICAO_DE_MAOS: 0,
	Skill.ESCUDO_DA_FE:      0,
	Skill.JULGAMENTO:        0
}

const XP_PER_LEVEL = 10

var current_skill: Skill = Skill.GOLPE_SAGRADO
var skills_list: Array = [
	Skill.GOLPE_SAGRADO,
	Skill.IMPOSICAO_DE_MAOS,
	Skill.ESCUDO_DA_FE,
	Skill.JULGAMENTO
]
var current_skill_index: int = 0

func next_skill() -> void:
	current_skill_index = (current_skill_index + 1) % skills_list.size()
	current_skill = skills_list[current_skill_index]
	speak(SKILL_NAMES[current_skill])

func prev_skill() -> void:
	current_skill_index = (current_skill_index - 1 + skills_list.size()) % skills_list.size()
	current_skill = skills_list[current_skill_index]
	speak(SKILL_NAMES[current_skill])

func use_skill(target_node: Node) -> void:
	var skill = current_skill
	skill_xp[skill] += 1
	if skill_xp[skill] >= XP_PER_LEVEL * skill_levels[skill]:
		skill_levels[skill] += 1
		speak(SKILL_NAMES[skill] + " nivel " + str(skill_levels[skill]))
	match skill:
		Skill.GOLPE_SAGRADO:
			_golpe_sagrado(target_node)
		Skill.IMPOSICAO_DE_MAOS:
			_imposicao_de_maos()
		Skill.ESCUDO_DA_FE:
			_escudo_da_fe()
		Skill.JULGAMENTO:
			_julgamento(target_node)

func _golpe_sagrado(target: Node) -> void:
	var dmg = 30 + (skill_levels[Skill.GOLPE_SAGRADO] * 10)
	if target and target.has_method("take_damage"):
		target.take_damage(dmg)

func _imposicao_de_maos() -> void:
	var heal = 20 + (skill_levels[Skill.IMPOSICAO_DE_MAOS] * 5)
	emit_signal("player_heal", heal)

func _escudo_da_fe() -> void:
	var duration = 3.0 + (skill_levels[Skill.ESCUDO_DA_FE] * 0.5)
	emit_signal("player_shield", duration)

func _julgamento(_target: Node) -> void:
	var dmg = 20 + (skill_levels[Skill.JULGAMENTO] * 8)
	emit_signal("area_damage", dmg)

signal player_heal(amount)
signal player_shield(duration)
signal area_damage(amount)
