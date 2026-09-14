extends Node

class_name ReactionDatabaseBase

# Classe base para banco de dados de reações
# Instância autoload deve herdar dessa classe

@export var rules: Array[ReactionRuleResource] = []


func find_rule(elem_a: int, tag_a: String, elem_b: int, tag_b: String) -> ReactionRuleResource:
	for rule in rules:
		# Verifica correspondência direta
		var match_direct = (rule.element_a == elem_a and rule.element_b == elem_b and
			(rule.tag_a == "" or rule.tag_a == tag_a) and
			(rule.tag_b == "" or rule.tag_b == tag_b))

		# Verifica correspondência invertida
		var match_swapped = (rule.element_a == elem_b and rule.element_b == elem_a and
			(rule.tag_a == "" or rule.tag_a == tag_b) and
			(rule.tag_b == "" or rule.tag_b == tag_a))

		if match_direct or match_swapped:
			return rule

	return null
