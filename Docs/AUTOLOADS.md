# ⚙️ Autoloads - Configuração Correta

## 🚨 PROBLEMA: Autoload não pode ter o mesmo nome que uma classe

```
❌ ERRADO:
  Arquivo: reaction_database_instance.gd
  Classe:  class_name ReactionDatabase
  Autoload: ReactionDatabase="*res://Scripts/Core/reaction_database_instance.gd"
  
  CONFLITO! Ambos são nomeados "ReactionDatabase"

✅ CORRETO:
  Arquivo: reaction_database_instance.gd
  Classe:  (SEM class_name)
  Autoload: ReactionDatabase="*res://Scripts/Core/reaction_database_instance.gd"
  
  Sem conflito! O autoload é só um nó da cena
```

---

## 📋 Configuração Final do project.godot

Abra `project.godot` e procure a seção `[autoload]`. Deve ficar assim:

```ini
[autoload]

Network="*uid://wy3ovkd8ingn"
TileRunInstancesGlobal="*uid://b6fg6pu2bfi14"
Global="*uid://c3dabc82f0rq5"
ReactionDatabase="*res://Scripts/Core/reaction_database_instance.gd"
```

**Importante:**
- `ReactionDatabase` é o **nome do nó** (node name), não uma classe
- O arquivo `reaction_database_instance.gd` **NÃO deve ter `class_name ReactionDatabase`**

---

## 📁 Arquivos Envolvidos

### Arquivo 1: reaction_database_instance.gd
```gdscript
extends ReactionDatabaseBase

# ❌ NÃO ADICIONE: class_name ReactionDatabase
# (conflitaria com autoload)

# ✅ Comente explicando:
# Instância singleton do banco de dados de reações
# NÃO USE class_name aqui para evitar conflito com autoload
# O autoload será nomeado "ReactionDatabase" no project.godot
# Acesso: get_node("/root/ReactionDatabase").find_rule(...)

func _ready() -> void:
	name = "ReactionDatabase"
	# Regras iniciais aqui
```

### Arquivo 2: ReactionDatabaseBase.gd
```gdscript
extends Node
class_name ReactionDatabaseBase  # ✅ Pode ter class_name (é base)

@export var rules: Array[ReactionRuleResource] = []

func find_rule(elem_a: int, tag_a: String, elem_b: int, tag_b: String) -> ReactionRuleResource:
	# implementação
```

---

## 🎯 Como Acessar os Autoloads

### ✅ CORRETO

```gdscript
# Em qualquer script
if has_node("/root/ReactionDatabase"):
	var db = get_node("/root/ReactionDatabase")
	var rule = db.find_rule(elem_a, tag_a, elem_b, tag_b)
```

### ❌ ERRADO

```gdscript
# Não faça isso:
ReactionDatabase.find_rule(...)  # ReactionDatabase não é classe

# Não faça isso:
var db = ReactionDatabase.new()  # É um autoload, não uma instância

# Não faça isso:
class_name ReactionDatabase  # Conflita com o autoload
```

---

## 🔍 Verificação

Abra o Godot Editor:

```
Projeto → Configuração do Projeto → Autoload
```

Deve aparecer:
```
Network      uid://...
TileRunInstancesGlobal  uid://...
Global       uid://...
ReactionDatabase  res://Scripts/Core/reaction_database_instance.gd
```

Se aparecer erro ou símbolo ⚠️, significa:
1. Arquivo não existe
2. Arquivo tem erro de sintaxe
3. Há class_name conflitando

---

## 🛠️ Checklist

- [ ] `reaction_database_instance.gd` **NÃO tem** `class_name ReactionDatabase`
- [ ] `ReactionDatabaseBase.gd` **TEM** `class_name ReactionDatabaseBase`
- [ ] `project.godot` tem `ReactionDatabase="*res://Scripts/Core/reaction_database_instance.gd"`
- [ ] No editor, Autoload mostra sem ⚠️
- [ ] Código usa `get_node("/root/ReactionDatabase")` (não `ReactionDatabase.`)
- [ ] Nenhum script tenta `class_name ReactionDatabase`

---

## 🚀 Resumo Ultra-Rápido

| Preciso De | O Quê Fazer |
|-----------|------------|
| Acessar reações | `get_node("/root/ReactionDatabase").find_rule(...)` |
| Criar nova base de reações | `extends ReactionDatabaseBase` (com `class_name`) |
| Usar singleton ReactionDatabase | Apenas um autoload, sem classe com mesmo nome |
| Adicionar regras | Colocar em `reaction_database_instance.gd` → `_ready()` |

---

## 📝 Exemplos Completos

### Exemplo: Acessar e usar o banco de reações

```gdscript
# Em fireball.gd
func _on_area_entered(other: Area3D) -> void:
	if not is_multiplayer_authority():
		return

	if other is RockDecal:
		# ✅ CORRETO
		if has_node("/root/ReactionDatabase"):
			var db = get_node("/root/ReactionDatabase")
			var rule = db.find_rule(element, tag, other.element, other.tag)
			if rule:
				ReactionResolver.resolve(self, other)
```

### Exemplo: Adicionar regras inicialmente

```gdscript
# Em reaction_database_instance.gd
func _ready() -> void:
	name = "ReactionDatabase"
	
	# Adicionar regra: EARTH + FIRE = INFUSE
	var rule = ReactionRuleResource.new()
	rule.element_a = 2  # EARTH
	rule.element_b = 0  # FIRE
	rule.tag_a = "projectile"
	rule.tag_b = "projectile"
	rule.outcome = ReactionRuleResource.Outcome.INFUSE
	
	rules.append(rule)
```

---

## ⚠️ Se Ainda Tiver Erro

1. **"Cannot find class ReactionDatabase"**
   - Verificar se arquivo existe
   - Verificar se não há `class_name ReactionDatabase` no arquivo

2. **"Cannot call find_rule() on the class directly"**
   - Use `get_node("/root/ReactionDatabase")` primeiro
   - ReactionDatabase é um nó, não uma classe

3. **Symbol icon appears in Autoload**
   - Arquivo tem erro de sintaxe
   - Arquivo não foi salvo
   - Reload do projeto: Project → Reload Current Project

---

**Regra de Ouro:**
```
Autoload name ≠ class_name

ReactionDatabase (autoload) ≠ ReactionDatabase (class)
Um é nó, o outro é classe. Não podem ter mesmo nome!
```
