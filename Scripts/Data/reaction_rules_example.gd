# Este arquivo mostra exemplos de como adicionar ReactionRules ao database
# Para usar, chamar essas funções em reaction_database_instance.gd _ready()

extends Node

class_name ReactionRulesExample


static func create_earth_fire_rules() -> Array[ReactionRule]:
	var rules: Array[ReactionRule] = []

	# Regra 1: EARTH projectile + FIRE projectile = SPAWN_AND_SPAWN (explosão)
	var rule1 = ReactionRule.new()
	rule1.element_a = 2  # ElementsEnum.Element.EARTH
	rule1.element_b = 0  # ElementsEnum.Element.FIRE
	rule1.tag_a = "projectile"
	rule1.tag_b = "projectile"
	rule1.outcome = ReactionRule.Outcome.SPAWN_AND_SPAWN
	# rule1.result_scene = preload("res://Scenes/Effects/explosion.tscn")
	rules.append(rule1)

	# Regra 2: EARTH projectile + FIRE projectile (no ar) = INFUSE
	# Quando FireBall toca RockSling antes de cair
	var rule2 = ReactionRule.new()
	rule2.element_a = 2  # ElementsEnum.Element.EARTH
	rule2.element_b = 0  # ElementsEnum.Element.FIRE
	rule2.tag_a = "projectile"
	rule2.tag_b = "projectile"
	rule2.outcome = ReactionRule.Outcome.INFUSE
	# rule2.result_scene = preload("res://Scenes/Effects/lava_sparkles.tscn")
	rules.append(rule2)

	# Regra 3: EARTH decal + FIRE projectile = DELAYED_TRIGGER
	var rule3 = ReactionRule.new()
	rule3.element_a = 2  # ElementsEnum.Element.EARTH
	rule3.element_b = 0  # ElementsEnum.Element.FIRE
	rule3.tag_a = "decal"
	rule3.tag_b = "projectile"
	rule3.outcome = ReactionRule.Outcome.DELAYED_TRIGGER
	rule3.delay = 2.0
	# rule3.result_scene = preload("res://Scenes/Effects/mega_explosion.tscn")
	rules.append(rule3)

	return rules


static func create_water_fire_rules() -> Array[ReactionRule]:
	var rules: Array[ReactionRule] = []

	# WATER + FIRE = STEAM explosion
	var rule = ReactionRule.new()
	rule.element_a = 1  # ElementsEnum.Element.WATER
	rule.element_b = 0  # ElementsEnum.Element.FIRE
	rule.tag_a = "projectile"
	rule.tag_b = "projectile"
	rule.outcome = ReactionRule.Outcome.SPAWN_AND_SPAWN
	# rule.result_scene = preload("res://Scenes/Effects/steam_explosion.tscn")
	rules.append(rule)

	return rules


static func create_air_rules() -> Array[ReactionRule]:
	var rules: Array[ReactionRule] = []

	# AIR + qualquer coisa = knock back aumentado
	# (você pode adicionar regras de ar aqui)

	return rules


static func create_electric_rules() -> Array[ReactionRule]:
	var rules: Array[ReactionRule] = []

	# ELECTRIC + WATER = Chain lightning
	# ELECTRIC + METAL = Amplificado

	return rules
