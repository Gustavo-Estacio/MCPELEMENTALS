extends RefCounted

class_name PlayerStats

## Stats base do jogador, mostrados no painel da direita enquanto o TAB está segurado.
##
## Por enquanto são só números: NADA aqui está ligado às spells, ao dano ou ao
## movimento ainda — é a base pra ligar depois (ver DEFINITIONS pra adicionar
## um stat novo, o painel do HUD se monta sozinho a partir dessa lista).

signal stat_changed(key: String, value: float)

enum Format {
	FLAT,        # 3000
	PERCENT,     # 0%
	MULTIPLIER,  # 1x
}

# Ordem aqui = ordem na tela.
const DEFINITIONS := [
	{"key": "health", "label": "Vida", "default": 3000.0, "format": Format.FLAT},
	{"key": "damage", "label": "Dano", "default": 100.0, "format": Format.FLAT},
	{"key": "area_size", "label": "Tamanho de Área", "default": 0.0, "format": Format.PERCENT},
	{"key": "range", "label": "Alcance", "default": 25.0, "format": Format.FLAT},
	{"key": "move_speed", "label": "Move Speed", "default": 200.0, "format": Format.FLAT},
	{"key": "duration", "label": "Duração", "default": 1.0, "format": Format.MULTIPLIER},
	{"key": "crit_chance", "label": "Crit Chance", "default": 0.0, "format": Format.PERCENT},
	{"key": "crit_damage", "label": "Crit Damage", "default": 100.0, "format": Format.PERCENT},
	{"key": "armor", "label": "Armor", "default": 10.0, "format": Format.FLAT},
	{"key": "cdr", "label": "CDR", "default": 0.0, "format": Format.MULTIPLIER},
	{"key": "knockback", "label": "Knockback", "default": 20.0, "format": Format.FLAT},
	{"key": "attack_speed", "label": "Attack Speed", "default": 1.0, "format": Format.MULTIPLIER},
	{"key": "lifesteal", "label": "Lifesteal", "default": 0.0, "format": Format.PERCENT},
]

var values := {}


func _init() -> void:
	reset()


func reset() -> void:
	for definition in DEFINITIONS:
		values[definition["key"]] = float(definition["default"])


func get_definition(key: String) -> Dictionary:
	for definition in DEFINITIONS:
		if definition["key"] == key:
			return definition
	return {}


func get_stat(key: String) -> float:
	return float(values.get(key, 0.0))


func set_stat(key: String, value: float) -> void:
	if not values.has(key):
		push_warning("Stat desconhecido: %s" % key)
		return
	if is_equal_approx(values[key], value):
		return
	values[key] = value
	stat_changed.emit(key, value)


func add_stat(key: String, amount: float) -> void:
	set_stat(key, get_stat(key) + amount)


func format_stat(key: String) -> String:
	return format_value(get_definition(key).get("format", Format.FLAT), get_stat(key))


static func format_value(format: int, value: float) -> String:
	match format:
		Format.PERCENT:
			return "%s%%" % _trim(value)
		Format.MULTIPLIER:
			return "%sx" % _trim(value)
		_:
			return _trim(value)


# 3000.0 -> "3000", 1.5 -> "1.5" (sem zeros à toa nos stats inteiros)
static func _trim(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return "%.2f" % value
