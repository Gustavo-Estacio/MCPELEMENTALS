# 🎯 REFERÊNCIA FINAL - Qual Usar Aonde

## ⚡ Tl;dr (super rápido)

```gdscript
ElementsEnum.Element.FIRE         ← enums
ElementsEnum.Slot.PROJECTILE      ← enums

extends AbilityResource           ← abilities
extends ElementKitResource        ← kits
extends ReactionRuleResource      ← reactions
extends ReactionDatabaseBase      ← novo database

get_node("/root/ReactionDatabase") ← acessar reações
ReactionResolver.resolve()        ← executar reação
DamageInfo.new()                  ← criar dano
```

---

## 📊 TABELA DEFINITIVA

| Necessidade | Arquivo | Class_name | Tipo | Uso |
|-------------|---------|-----------|------|-----|
| **Valor FIRE, WATER, etc** | ElementsEnum.gd | ElementsEnum | Enum | `ElementsEnum.Element.FIRE` |
| **Valor PROJECTILE, DASH, etc** | ElementsEnum.gd | ElementsEnum | Enum | `ElementsEnum.Slot.PROJECTILE` |
| **Habilidade salvável** | AbilityResource.gd | AbilityResource | Resource | `extends AbilityResource` |
| **Kit de abilities** | ElementKitResource.gd | ElementKitResource | Resource | `extends ElementKitResource` |
| **Regra de reação** | ReactionRuleResource.gd | ReactionRuleResource | Resource | `extends ReactionRuleResource` |
| **Interface comum** | ElementalCarrierInterface.gd | ElementalCarrierInterface | Interface | `var element: int` |
| **Base para novo DB** | ReactionDatabaseBase.gd | ReactionDatabaseBase | Class | `extends ReactionDatabaseBase` |
| **Banco de reações** | reaction_database_instance.gd | (nenhum) | Singleton | `get_node("/root/ReactionDatabase")` |
| **Executar reação** | ReactionResolver.gd | ReactionResolver | Utility | `ReactionResolver.resolve()` |
| **Info de dano** | DamageInfo.gd | DamageInfo | Data | `DamageInfo.new()` |

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

### Antes de começar
- [ ] Li `Docs/INDEX.md`
- [ ] Li `Docs/QUICK_REFERENCE.md`

### Setup do Projeto
- [ ] `project.godot` tem: `ReactionDatabase="*res://Scripts/Core/reaction_database_instance.gd"`
- [ ] `reaction_database_instance.gd` **SEM** `class_name ReactionDatabase`
- [ ] Editor abre sem erros de autoload (⚠️)

### Implementação
- [ ] Todos usam `ElementsEnum.Element.X` (não `Elements.Element.X`)
- [ ] Todos usam `ElementsEnum.Slot.X` (não `Elements.Slot.X`)
- [ ] Habilidades estendem `AbilityResource` ou `ElementKitResource`
- [ ] Regras estendem `ReactionRuleResource`
- [ ] Acessam database via `get_node("/root/ReactionDatabase")`
- [ ] Nenhuma classe se chama `ReactionDatabase` (apenas autoload)

### Testes
- [ ] Rock Sling (Q) aparece ao apertar
- [ ] FireBall (E) aparece ao apertar
- [ ] Ambos causam dano
- [ ] Podem ser infundidos

---

## 🔍 VERIFICAÇÃO RÁPIDA

### Erro: "Cannot call find_rule() on class"
```gdscript
# ❌ ERRADO
var rule = ReactionDatabase.find_rule(...)

# ✅ CORRETO
var db = get_node("/root/ReactionDatabase")
var rule = db.find_rule(...)
```

### Erro: "Undefined class Elements"
```gdscript
# ❌ ERRADO
var elem = Elements.Element.FIRE

# ✅ CORRETO
var elem = ElementsEnum.Element.FIRE
```

### Erro: "Cannot inherit from Ability"
```gdscript
# ❌ ERRADO
extends Ability

# ✅ CORRETO
extends AbilityResource
```

### Erro: Symbol icon in Autoload (⚠️)
```gdscript
# ❌ ERRADO (em reaction_database_instance.gd)
class_name ReactionDatabase

# ✅ CORRETO (sem class_name)
# (deixa vazio, é só um nó)
```

---

## 🎬 FLUXO DE USO

### Criar Habilidade
```gdscript
# 1. Extends AbilityResource
extends AbilityResource

@export var ability_name = "Rock Sling"
@export var element = ElementsEnum.Element.EARTH  # ✅ use ElementsEnum
@export var cooldown = 1.0

# 2. Salve como rock_sling_ability.tres
```

### Usar Habilidade
```gdscript
# 1. Create ability
var ability = RockSlingAbility.new()

# 2. Cast projectile
var rock = ability.cast(player, direction)
rock.element = ElementsEnum.Element.EARTH  # ✅ use ElementsEnum

# 3. Add to scene
spawn_container.add_child(rock)
```

### Detectar Reação
```gdscript
# 1. Get database
var db = get_node("/root/ReactionDatabase")  # ✅ use get_node

# 2. Find rule
var rule = db.find_rule(elem_a, tag_a, elem_b, tag_b)

# 3. Execute
if rule:
    ReactionResolver.resolve(obj_a, obj_b)  # ✅ use ReactionResolver
```

---

## 📁 ESTRUTURA FINAL

```
Scripts/Core/
├── ElementsEnum.gd                ← SEMPRE para enums
├── AbilityResource.gd             ← extends para abilities
├── ElementKitResource.gd          ← extends para kits
├── ElementalCarrierInterface.gd   ← implementar em carriers
├── ReactionRuleResource.gd        ← extends para regras
├── ReactionDatabaseBase.gd        ← extends para novo DB
├── reaction_database_instance.gd  ← autoload (SEM class_name)
├── ReactionResolver.gd            ← use para resolver
├── DamageInfo.gd                  ← instantiate para dano

Docs/
├── INDEX.md                       ← LEIA PRIMEIRO
├── QUICK_REFERENCE.md            ← Respostas rápidas
├── NAMING_CONVENTION.md          ← Entenda o POR QUÊ
├── AUTOLOADS.md                  ← Configurar autoload
└── (outros guias...)
```

---

## 🚀 COMEÇAR AGORA

1. **Abra `Docs/INDEX.md`** - Guia de navegação
2. **Leia `Docs/QUICK_REFERENCE.md`** - Respostas rápidas (5 min)
3. **Configure autoload** - Ver `Docs/AUTOLOADS.md`
4. **Teste no editor** - Ver `Docs/TESTING_GUIDE.md`

---

## 🎓 SISTEMA PRONTO!

✅ Sem conflitos de nomeação
✅ Autoloads corretamente configurados
✅ Documentação completa em /Docs
✅ Exemplos funcionais em cada script
✅ Pronto para estender (novo elemento = 1 arquivo)

**Status:** 🟢 PRONTO PARA USAR

Divirta-se desenvolvendo! 🎮
