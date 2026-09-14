extends ReactionDatabaseBase

# Instância singleton do banco de dados de reações
# NÃO USE class_name aqui para evitar conflito com autoload
# O autoload será nomeado "ReactionDatabase" no project.godot
# Acesso: get_node("/root/ReactionDatabase").find_rule(...)

func _ready() -> void:
	name = "ReactionDatabase"
	# Aqui você pode adicionar regras via código ou carregar de Resources
	# Por enquanto, deixa vazio - as regras serão adicionadas depois
