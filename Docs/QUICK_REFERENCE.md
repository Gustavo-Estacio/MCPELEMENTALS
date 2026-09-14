# Quick Reference - Qual Usar Aonde?

## 🎯 Respostas Rápidas

### "Preciso usar os valores FIRE, WATER, EARTH..."
```gdscript
# ✅ CORRETO:
var element = ElementsEnum.Element.FIRE
var slot = ElementsEnum.Slot.PROJECTILE

# ❌ ERRADO:
# var element = Elements.Element.FIRE  (não existe mais)
```

### "Preciso de uma regra de reação..."
```gdscript
# ✅ CORRETO:
extends ReactionRuleResource
# ou
var rule: ReactionRuleResource = load("res://data/reactions/fire_earth.tres")

# ❌ ERRADO:
# extends ReactionRule
```

### "Preciso de uma habilidade..."
```gdscript
# ✅ CORRETO:
extends AbilityResource
# ou
var ability: AbilityResource = load("res://data/abilities/fire_q.tres")

# ❌ ERRADO:
# extends Ability
```

### "Preciso de um kit de habilidades..."
```gdscript
# ✅ CORRETO:
var kit: ElementKitResource = load("res://data/kits/fire_kit.tres")

# ❌ ERRADO:
# var kit: ElementKit
```

### "Preciso verificar elemento do objeto..."
```gdscript
# ✅ CORRETO:
var carrier: ElementalCarrierInterface
if other is RockSling:
    carrier = other

# ❌ ERRADO:
# extends ElementalCarrier  (use ElementalCarrierInterface)
```

### "Preciso acessar o banco de reações..."
```gdscript
# ✅ CORRETO:
if has_node("/root/ReactionDatabase"):
    var db = get_node("/root/ReactionDatabase")  # get_node é seguro
    var rule = db.find_rule(elem_a, tag_a, elem_b, tag_b)

# ❌ ERRADO:
# var rule = ReactionDatabase.find_rule(...)  (não é estático)
# ReactionDatabase é um autoload, não uma classe
# (reaction_database_instance.gd NÃO tem class_name para evitar conflito)
```

### "Preciso executar uma reação..."
```gdscript
# ✅ CORRETO:
ReactionResolver.resolve(object_a, object_b)

# ❌ ERRADO:
# (ReactionResolver é estático, certo!)
```

### "Preciso criar info de dano..."
```gdscript
# ✅ CORRETO:
var info = DamageInfo.new()
info.amount = 15
info.element = ElementsEnum.Element.FIRE

# ❌ ERRADO:
# (DamageInfo está correto)
```

---

## 📁 Arquivo → Quando Usar

| Arquivo | Class Name | Tipo | Quando Usar |
|---------|-----------|------|-------------|
| `ElementsEnum.gd` | `ElementsEnum` | Enum | **SEMPRE** para valores de elemento/slot |
| `AbilityResource.gd` | `AbilityResource` | Resource | Criar/salvar habilidades .tres |
| `ElementKitResource.gd` | `ElementKitResource` | Resource | Agrupar 7 abilities |
| `ElementalCarrierInterface.gd` | `ElementalCarrierInterface` | Interface | Contrato para objetos que carregam elementos |
| `ReactionRuleResource.gd` | `ReactionRuleResource` | Resource | Criar/salvar regras de reação .tres |
| `ReactionDatabaseBase.gd` | `ReactionDatabaseBase` | Base Class | Herdar para criar novo database |
| `reaction_database_instance.gd` | (sem class_name) | Singleton | **AUTOLOAD** - acesso via `get_node("/root/ReactionDatabase")` |
| `ReactionResolver.gd` | `ReactionResolver` | Utility | Executar reações |
| `DamageInfo.gd` | `DamageInfo` | Data | Passar info de dano |

---

## 🔗 Exemplos Completos

### Exemplo 1: Em rock_sling_ability.gd
```gdscript
extends Node
class_name RockSlingAbility

var element := ElementsEnum.Element.EARTH  # ✅
var slot := ElementsEnum.Slot.PROJECTILE  # ✅
var base_force := 20.0

func cast(player: Node3D, direction: Vector3) -> RockSling:
    var scene = preload("res://Scenes/Effects/rock_sling.tscn")
    var rock = scene.instantiate()
    rock.element = element  # ✅ use ElementsEnum.Element.EARTH
    rock.tag = "projectile"
    # ...
    return rock
```

### Exemplo 2: Em fireball.gd
```gdscript
extends RigidBody3D
class_name FireBall

var element: int = ElementsEnum.Element.FIRE  # ✅

func _on_area_entered(other: Area3D) -> void:
    if not is_multiplayer_authority():
        return
    
    if other.owner and other.owner is RockSling:  # ✅
        _infuse_rock_with_fire(other.owner)

func _infuse_rock_with_fire(rock: RockSling) -> void:
    # Acessa database
    if has_node("/root/ReactionDatabase"):  # ✅
        var db = get_node("/root/ReactionDatabase")
        var rule = db.find_rule(element, tag, rock.element, rock.tag)
        if rule:
            ReactionResolver.resolve(self, rock)  # ✅
```

### Exemplo 3: Em Player.gd
```gdscript
extends CharacterBody3D
class_name Player

var rock_sling_ability: RockSlingAbility
var fireball_ability: FireBallAbility

func _ready():
    rock_sling_ability = RockSlingAbility.new()  # ✅
    fireball_ability = FireBallAbility.new()  # ✅

func _cast_rock_sling() -> void:
    var direction = get_ability_direction()
    cast_ability.rpc_id(1, "rock_sling", global_position, direction)

@rpc("authority")
func cast_ability(ability_type: String, pos: Vector3, dir: Vector3) -> void:
    if not is_multiplayer_authority():
        return
    
    match ability_type:
        "rock_sling":
            var rock = rock_sling_ability.cast(self, dir)  # ✅
            rock.owner_peer_id = multiplayer.get_unique_id()
            Global.spawn_container.add_child(rock)
```

### Exemplo 4: Criar ReactionRule no editor
```gdscript
# No Inspector, criar um novo Resource do tipo ReactionRuleResource ✅

element_a: 2 (EARTH, ver ElementsEnum.Element)
element_b: 0 (FIRE)
tag_a: "projectile"
tag_b: "projectile"
outcome: INFUSE
result_scene: res://Scenes/Effects/fire_particles.tscn
delay: 0.0
```

---

## ✅ Checklist de Uso Correto

```
[ ] Usando ElementsEnum.Element.X? (não Elements.Element.X)
[ ] Habilidades como AbilityResource? (não Ability)
[ ] Regras como ReactionRuleResource? (não ReactionRule)
[ ] Kits como ElementKitResource? (não ElementKit)
[ ] ReactionDatabase acessado via get_node()? (não estático)
[ ] ReactionResolver.resolve() chamado? (é estático ✅)
[ ] DamageInfo.new() usado? (está correto ✅)
[ ] Banco de dados verificado com has_node()? (null-safe)
```

---

## 🚨 Erros Comuns e Soluções

| Erro | Causa | Solução |
|------|-------|---------|
| `Undefined class "Elements"` | Renomeado para `ElementsEnum` | Use `ElementsEnum.Element.FIRE` |
| `Cannot call "find_rule()" on class` | Não é estático | Use `get_node("/root/ReactionDatabase").find_rule()` |
| `Type check "RockSling" failed` | Area3D não é RockSling | Use `other.owner is RockSling` |
| `Undefined class "Ability"` | Renomeado para `AbilityResource` | Use `extends AbilityResource` |
| `Cannot access ReactionDatabase` | Não é autoload | Verificar `project.godot` |

---

## 📝 Resumo Ultra-Rápido

### Valores / Enums
→ **ElementsEnum**

### Dados salvos como .tres
→ **XxxxResource** (Ability, ElementKit, ReactionRule)

### Classe base para herança
→ **XxxxBase** (ReactionDatabaseBase)

### Acesso global / Singleton
→ **Nome direto** (ReactionDatabase, ReactionResolver)

### Info temporária
→ **XxxxInfo** (DamageInfo)

### Interface / Contrato
→ **XxxxInterface** (ElementalCarrierInterface)

---

**Dúvida? Procure `NAMING_CONVENTION.md` para explicação detalhada!**
