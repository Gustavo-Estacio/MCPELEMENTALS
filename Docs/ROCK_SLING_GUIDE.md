# Rock Sling - Implementação Completa

## 📋 O que foi criado

### Scripts Core (Sistema de Elementos)
- **elements.gd** - Enums centralizados (Element, Slot)
- **elemental_carrier.gd** - Interface base para objetos que carregam elementos
- **ability.gd** - Resource base para habilidades
- **element_kit.gd** - Resource que agrupa 7 abilities
- **damage_info.gd** - Informações padronizadas de dano
- **reaction_rule.gd** - Configuração de uma reação elemental
- **reaction_database.gd** - Banco de dados de reações
- **reaction_resolver.gd** - Executor de reações
- **reaction_database_instance.gd** - Singleton autoload

### Scripts da Habilidade
- **rock_sling_ability.gd** - Lógica da habilidade Q (carregável, arco)
- **rock_sling.gd** - Script do projectile (bola que voa)
- **rock_decal.gd** - Script do decal persistente no chão

### Cenas
- **rock_sling.tscn** - Prefab do projectile (esfera marrom)
- **rock_decal.tscn** - Prefab do decal no chão

## 🎮 Características do Rock Sling

✅ **Elemento**: EARTH (Slot Q - PROJECTILE)
✅ **Carregável**: Tempo máximo 2s, poder de 1.0x a 2.5x
✅ **Lançamento Oblíquo**: Automático via RigidBody3D + gravidade
✅ **Deixa Decal**: Ao colidir com o chão, cria decal persistente
✅ **Inflamável**: Pode reagir ao FIRE
✅ **Movível**: Pode ser infundido por água/ar

## 🔧 Como Integrar ao Player

### 1. Adicionar ReactionDatabase como autoload

No `project.godot`, adicionar:
```
[autoload]
ReactionDatabase="*res://Scripts/Core/reaction_database_instance.gd"
Elements="*res://Scripts/Core/elements.gd"
```

Ou no Player.gd, antes de usar:
```gdscript
if not has_node("/root/ReactionDatabase"):
	add_to_group("_root")
	var db = ReactionDatabase.new()
	get_tree().root.add_child(db)
	db.name = "ReactionDatabase"
```

### 2. No Player.gd, adicionar processamento da habilidade Q

```gdscript
var rock_sling_ability: RockSlingAbility
var is_charging := false

func _ready():
	rock_sling_ability = RockSlingAbility.new()

func _process(delta):
	if Input.is_action_just_pressed("ability_q"):
		rock_sling_ability.start_charge()
		is_charging = true

	if Input.is_action_just_released("ability_q") and is_charging:
		_cast_rock_sling()
		is_charging = false

func _cast_rock_sling() -> void:
	var direction = -global_transform.basis.z  # Direção pra frente do player
	var rock = rock_sling_ability.cast(self, direction)
	Global.spawn_container.add_child(rock)
	rock.rpc_id(1, "set_owner_peer_id", multiplayer.get_unique_id())
```

### 3. Criar uma ReactionRule de teste

Na Godot Editor, criar um novo Resource do tipo ReactionRule:
- element_a: FIRE
- element_b: EARTH
- tag_a: "projectile"
- tag_b: "decal"
- outcome: SPAWN_AND_SPAWN
- result_scene: (criar um simple effect que é uma explosão)

## 🎯 Fluxo de Funcionamento

1. Player aperta Q (começa a carregar)
2. Player solta Q (dispara o rock)
3. Rock viaja em arco pelo ar
4. Rock colide com chão (body_entered)
5. Rock cria decal e desaparece
6. Se houver reação (ex: fireball toca decal):
   - ReactionDatabase encontra a ReactionRule
   - ReactionResolver executa o resultado

## 📦 Arquivos de Dados a Criar

Para completar o sistema, você precisa criar Resources .tres:

1. **Rock Sling Ability Resource** (se quiser usar o sistema de Ability.tres)
2. **Earth Element Kit** (agrupa todas as 7 abilities da terra)
3. **Reaction Rules** (EARTH projectile + FIRE projectile = explosion, etc)

## 🚀 Próximos Passos

1. Criar cenas de efeitos visuais (explosão ao bater)
2. Adicionar shaders para infusão (decal muda cor)
3. Implementar outros elementos (Fire, Water, Air, Electric)
4. Criar reaction rules completas
5. Adicionar sons e feedback visual

## ⚡ Exemplo de Reação

**Rock Sling + Fireball = Explosão**

```
EARTH (projectile) + FIRE (projectile)
→ Outcome: SPAWN_AND_SPAWN
→ Result: explosion_scene (com partículas)
→ Ambos desaparecem, explosão nasce no meio
```

**Earth Decal + Fireball = Delayed Trigger**

```
EARTH (decal) + FIRE (projectile)
→ Outcome: DELAYED_TRIGGER (delay: 2s)
→ Result: mega_explosion_scene
→ Decal espera 2s e explode com poder aumentado
```
