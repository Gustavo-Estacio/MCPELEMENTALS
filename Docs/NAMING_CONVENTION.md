# Convenção de Nomeação - Sistema Elemental

## 🎯 Problema Resolvido

Conflitos de nomeação foram eliminados com esta convenção clara:

```
❌ ANTES:
  Elements.gd         → classe genérica
  elements.gd         → enums
  Ability.gd          → classe genérica
  ElementKit.gd       → classe genérica

✅ DEPOIS:
  ElementsEnum.gd     → APENAS enums (não Node)
  AbilityResource.gd  → Resource que pode ser .tres
  ElementKitResource.gd → Resource que pode ser .tres
  ReactionDatabaseBase.gd → classe base
  ReactionDatabase.gd → autoload singleton
```

---

## 📋 Guia Completo de Nomeação

### **1. Enums - Não são classes**

```gdscript
# ✅ CORRETO: ElementsEnum.gd (não extends Node)
class_name ElementsEnum

enum Element {
    FIRE = 0,
    WATER = 1,
    EARTH = 2,
    ...
}

# Uso:
var element = ElementsEnum.Element.FIRE  # ✅ claro

# ❌ ERRADO: Elements.gd (ambíguo, pode ser classe)
# var element = Elements.Element.FIRE  # confuso
```

---

### **2. Resources - Sufixo `_Resource`**

Resources são dados que podem ser salvos como `.tres` no editor.

```gdscript
# ✅ AbilityResource.gd
extends Resource
class_name AbilityResource

@export var ability_name: String
@export var element: int
@export var cooldown: float

# Uso:
var ability: AbilityResource = load("res://data/abilities/fire_q.tres")

# ✅ ElementKitResource.gd
extends Resource
class_name ElementKitResource

@export var element: int
@export var abilities: Array[AbilityResource]

# ❌ ERRADO: Ability.gd ou ElementKit.gd
# (nome genérico, confunde com classe)
```

---

### **3. Interfaces - Sufixo `_Interface`**

Classes que definem contrato/interface para outras classes implementarem.

```gdscript
# ✅ ElementalCarrierInterface.gd
extends Node
class_name ElementalCarrierInterface

var element: int
var tag: String
var infused_with: int

# Implementação em outras classes:
class FireBall(RigidBody3D):
    # Herda implicitamente o contrato
    var element: int = ElementsEnum.Element.FIRE
    var tag: String = "projectile"

# ❌ ERRADO: ElementalCarrier.gd
# (confunde interface com implementação)
```

---

### **4. Classes Base - Sufixo `_Base`**

Classes abstratas que definem comportamento comum.

```gdscript
# ✅ ReactionDatabaseBase.gd
extends Node
class_name ReactionDatabaseBase

func find_rule(elem_a, tag_a, elem_b, tag_b):
    # implementação

# ❌ ERRADO: ReactionDatabase.gd
# (nome já usado para autoload/instância)
```

---

### **5. Singletons/Autoloads - Nome direto (SEM class_name)**

Instâncias que são usadas como autoloads. **IMPORTANTE: NÃO use class_name** para evitar conflito com o nome do autoload.

```gdscript
# ✅ reaction_database_instance.gd (sem class_name!)
extends ReactionDatabaseBase

# NÃO adicione: class_name ReactionDatabase
# (conflitaria com o autoload nomeado "ReactionDatabase")

# No project.godot:
[autoload]
ReactionDatabase="*res://Scripts/Core/reaction_database_instance.gd"

# Uso em qualquer script:
var db = get_node("/root/ReactionDatabase")  # ✅ acesso correto
var rule = db.find_rule(...)  # ✅ funciona

# ❌ ERRADO:
# ReactionDatabase.find_rule(...)  # não é estático
# var db = ReactionDatabase.new()  # não faz sense para autoload
# class_name ReactionDatabase  # conflita com autoload
```

---

### **6. Scripts Utilitários - Nome direto**

Funções estáticas e helpers (não Resource, não extends Node se não precisa).

```gdscript
# ✅ ReactionResolver.gd
class_name ReactionResolver

static func resolve(obj_a: Node, obj_b: Node) -> void:
    # executar reação

# Uso:
ReactionResolver.resolve(rock, fireball)

# ✅ DamageInfo.gd
extends RefCounted
class_name DamageInfo

var amount: float
var element: int
# ... dados

# Uso:
var info = DamageInfo.new()
```

---

## 🗂️ Estrutura Final de Pastas

```
Scripts/Core/
├── ❌ OLD (remover):
│   ├── elements.gd
│   ├── ability.gd
│   ├── element_kit.gd
│   ├── elemental_carrier.gd
│   ├── reaction_database.gd
│   └── reaction_rule.gd
│
├── ✅ NEW (manter):
│   ├── ElementsEnum.gd              # Apenas enums
│   ├── AbilityResource.gd           # Resource
│   ├── ElementKitResource.gd        # Resource
│   ├── ElementalCarrierInterface.gd # Interface
│   ├── ReactionRuleResource.gd      # Resource
│   ├── ReactionDatabaseBase.gd      # Classe base
│   ├── reaction_database_instance.gd # Autoload (vira ReactionDatabase)
│   ├── ReactionResolver.gd          # Utilidade estática
│   ├── DamageInfo.gd               # Dado/RefCounted
```

---

## 📝 Regras Simples

| Tipo | Padrão | Exemplo | Uso |
|------|--------|---------|-----|
| **Enum** | `XxxxEnum.gd` | `ElementsEnum.gd` | `ElementsEnum.Element.FIRE` |
| **Resource** | `XxxxResource.gd` | `AbilityResource.gd` | `load("...tres")` |
| **Interface** | `XxxxInterface.gd` | `ElementalCarrierInterface.gd` | Contrato |
| **Base** | `XxxxBase.gd` | `ReactionDatabaseBase.gd` | Herança |
| **Autoload** | `XxxxName.gd` | `reaction_database_instance.gd` | `get_node("/root/ReactionDatabase").find_rule()` |
| **Utilitário** | `XxxxName.gd` | `ReactionResolver.gd` | `ReactionResolver.resolve()` |
| **Dado** | `XxxxInfo.gd` | `DamageInfo.gd` | `DamageInfo.new()` |

---

## 🔧 Referência Rápida

### **Onde usar qual classe?**

```gdscript
# Em FireBall.gd
var element: int = ElementsEnum.Element.FIRE  # ✅ Use ElementsEnum

# Em rock_sling_ability.gd
var element: int = ElementsEnum.Element.EARTH  # ✅ Use ElementsEnum

# Em rock_sling.gd (reação)
if has_node("/root/ReactionDatabase"):
    var db = get_node("/root/ReactionDatabase")  # ✅ Use ReactionDatabase
    var rule = db.find_rule(...)

# Criar ability resource
var ability = AbilityResource.new()  # ✅ Use AbilityResource

# Criar damage info
var info = DamageInfo.new()  # ✅ Use DamageInfo

# Resolver reação
ReactionResolver.resolve(obj_a, obj_b)  # ✅ Use ReactionResolver
```

---

## ✅ Checklist de Implementação

Arquivos a manter/renomear:

- [x] **ElementsEnum.gd** - Enums centralizadas
- [x] **AbilityResource.gd** - Resource de habilidade
- [x] **ElementKitResource.gd** - Resource de kit elemental
- [x] **ElementalCarrierInterface.gd** - Interface comum
- [x] **ReactionRuleResource.gd** - Resource de regra
- [x] **ReactionDatabaseBase.gd** - Classe base
- [x] **ReactionDatabase.gd** (autoload) - Singleton
- [x] **ReactionResolver.gd** - Executor de reações
- [x] **DamageInfo.gd** - Info de dano

Arquivos a deletar (OLD):
- [ ] `elements.gd` (usar ElementsEnum.gd)
- [ ] `ability.gd` (usar AbilityResource.gd)
- [ ] `element_kit.gd` (usar ElementKitResource.gd)
- [ ] `elemental_carrier.gd` (usar ElementalCarrierInterface.gd)
- [ ] `reaction_rule.gd` (usar ReactionRuleResource.gd)
- [ ] `reaction_database.gd` (usar ReactionDatabaseBase.gd)
- [ ] `reaction_database_instance.gd` (renomear para o autoload)

---

## 🎓 Por que essa convenção?

1. **Clareza**: Nome deixa claro o tipo (Resource, Interface, Base, etc)
2. **Sem conflitos**: `Elements` vs `ElementsEnum` não confundem
3. **Escalabilidade**: Fácil adicionar novos tipos sem quebrar padrão
4. **Git-friendly**: Nomes consistentes facilitam busca/refactor
5. **Reutilização**: Claro qual classe herdar vs instanciar vs carregar

---

## 💡 Próximas Fases

- [ ] Deletar arquivos OLD (após testes)
- [ ] Atualizar todas as referências nos scripts
- [ ] Criar exemplo completo de uso
- [ ] Documentar em docstrings
