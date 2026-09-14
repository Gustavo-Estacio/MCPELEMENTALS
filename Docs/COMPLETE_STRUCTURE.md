# Estrutura Completa - Rock Sling + FireBall

## 📦 Todos os Arquivos Criados

### 🔧 Core System (Sistema Base de Elementos)

```
Scripts/Core/
├── elements.gd
│   └── Enums: Element (FIRE, WATER, EARTH, AIR, ELECTRIC)
│             Slot (AUTO_ATTACK, SPECIAL_ATTACK, PROJECTILE, SPECIAL_SKILL, DASH, JUMP, ULTIMATE)
│
├── elemental_carrier.gd
│   └── Classe base para objetos que carregam elementos
│
├── ability.gd
│   └── Resource base para habilidades (pode ser salva como .tres)
│
├── element_kit.gd
│   └── Agrupa 7 Abilities (uma por slot)
│
├── damage_info.gd
│   └── Informações padronizadas de dano/status
│
├── reaction_rule.gd
│   └── Define uma regra: elem_a + elem_b + context → outcome + efeito
│
├── reaction_database.gd
│   └── Banco de dados com todas as regras
│   └── Método: find_rule(elem_a, tag_a, elem_b, tag_b) → ReactionRule
│
├── reaction_database_instance.gd
│   └── Singleton autoload da database
│
└── reaction_resolver.gd
    └── Executa reações (SPAWN_AND_SPAWN, INFUSE, DELAYED_TRIGGER, MUTATE_DECAL)
```

### 🪨 Rock Sling (Habilidade Q)

```
Scripts/Entities/
├── rock_sling.gd
│   ├── Extends RigidBody3D
│   ├── Elemento: EARTH
│   ├── Tag: "projectile"
│   ├── Features:
│   │   ├── Carregável (1x a 2.5x power)
│   │   ├── Detecta colisão (body_entered)
│   │   ├── Detecta reações (area_entered)
│   │   └── Spawna decal ao impactar
│   └── Métodos: _on_body_entered, _on_area_entered, _spawn_decal_and_cleanup
│
├── rock_decal.gd
│   ├── Extends Area3D
│   ├── Elemento: EARTH
│   ├── Tag: "decal"
│   ├── Features:
│   │   ├── Persistente no chão
│   │   ├── Detecta reações
│   │   └── Pode ser infundido
│   └── Métodos: _on_area_entered, _update_visual_infusion

Scripts/Abilities/
└── rock_sling_ability.gd
    ├── Controla carregamento (max 2s)
    ├── Calcula poder (1.0x a 2.5x)
    ├── Método: cast(player, direction) → RockSling
    └── Movimento: lançamento oblíquo horizontal

Scenes/Effects/
├── rock_sling.tscn
│   ├── RigidBody3D (massa 2.0)
│   ├── MeshInstance3D: Esfera (raio 0.25)
│   ├── Material: dark/texture_11.png (marrom escuro)
│   ├── CollisionShape3D: Sphere
│   ├── Area3D: Esfera de detecção (raio 0.5)
│   └── MultiplayerSynchronizer
│
└── rock_decal.tscn
    ├── Area3D (no collision layer)
    ├── MeshInstance3D: Box (2.0x2.0)
    ├── Material: dark/texture_01.png (terra)
    ├── CollisionShape3D: Box
    └── DetectionArea: Box de reação (2.5x2.5)
```

### 🔥 FireBall (Habilidade E)

```
Scripts/Entities/
└── fireball.gd
    ├── Extends RigidBody3D
    ├── Elemento: FIRE
    ├── Tag: "projectile"
    ├── Features:
    │   ├── Emite luz (OmniLight3D pulsante)
    │   ├── Partículas de fogo
    │   ├── Detecta colisão
    │   ├── Infunde rock sling com lava
    │   ├── Status effect: BURN (2s)
    │   └── Knockback aumentado (7.0x force)
    ├── Métodos:
    │   ├── _on_body_entered(body)
    │   ├── _on_area_entered(other)
    │   ├── _infuse_rock_with_fire(rock)
    │   ├── _create_lava_material()
    │   └── _on_impact()
    └── Dano: 15 base (até 30 carregado)

Scripts/Abilities/
└── fireball_ability.gd
    ├── Controla carregamento (max 1.5s)
    ├── Calcula poder (1.0x a 2.0x)
    ├── Método: cast(player, direction) → FireBall
    └── Movimento: reto com arco leve

Scenes/Effects/
├── fireball.tscn
│   ├── RigidBody3D (massa 1.5)
│   ├── MeshInstance3D: Esfera (raio 0.3)
│   ├── Material: red/texture_11.png (vermelho)
│   ├── Emission: Brilho constante
│   ├── OmniLight3D: 
│   │   ├── Range: 8m
│   │   ├── Pulsação: 2.0 → 1.0 (0.3s ciclo)
│   │   └── Energy: 1.5
│   ├── GPUParticles3D:
│   │   ├── Quantidade: 20
│   │   ├── Lifetime: 1.5s
│   │   ├── Spread: 180°
│   │   └── Velocidade: 1.5-3.0 m/s
│   ├── CollisionShape3D: Sphere (raio 0.3)
│   ├── Area3D: Esfera detecção (raio 0.6)
│   └── MultiplayerSynchronizer
│
└── fire_particles.tscn
    ├── GPUParticles3D (standalone)
    ├── Quantidade: 30
    ├── Lifetime: 2.0s
    ├── Spread: 90°
    ├── Velocidade: 2.0-4.0 m/s
    └── Emissão: Laranja brilhante
```

### 📋 Dados e Exemplos

```
Scripts/Data/
└── reaction_rules_example.gd
    ├── create_earth_fire_rules()
    │   ├── EARTH + FIRE projectile → SPAWN_AND_SPAWN (explosão)
    │   ├── EARTH + FIRE projectile → INFUSE (lava)
    │   └── EARTH decal + FIRE projectile → DELAYED_TRIGGER (2s)
    ├── create_water_fire_rules()
    ├── create_air_rules()
    └── create_electric_rules()
```

### 🌐 Global System

```
Scripts/
└── global.gd (ATUALIZADO)
    ├── _ready(): Cria Elements e ReactionDatabase como autoloads
    ├── shoot_ball(pos, dir, force): RPC existente
    └── cast_ability(ability_type, pos, dir): RPC nova
        ├── "rock_sling": Cria RockSling
        └── "fireball": Cria FireBall
```

## 🎬 Fluxo Visual

### Quando Player aperta Q (Rock Sling)

```
Carregar (max 2s)
    ↓
Soltar
    ↓
Rock voa em arco (gravidade natural)
    ↓
Colide com chão (body_entered)
    ├→ Inflige dano
    ├→ Spawna decal marrom
    └→ Rock desaparece

Se FireBall toca o Rock em voo:
    ├→ Material do rock vira laranja/vermelho (infusão)
    ├→ Partículas de fogo spawnam no rock
    ├→ Rock continua voando inflamável
    └→ ReactionResolver processa a regra
```

### Quando Player aperta E (FireBall)

```
Carregar (max 1.5s)
    ↓
Soltar
    ↓
Bola vermelha viaja pelo ar
├→ OmniLight pulsa
├→ Partículas de fogo emanam
└→ Deixa trilha de luz

Se toca Rock Sling:
    ├→ Rock absorve material lava
    ├→ Fire_particles spawnam no rock
    ├→ FireBall desaparece
    └→ ReactionResolver processa infusão

Se toca inimigo:
    ├→ 15-30 dano (baseado carga)
    ├→ Status: BURN 2s
    ├→ Knockback forte (7.0x)
    └→ Partículas de impacto

Se toca decal:
    ├→ Decal inicia timer de 2s
    ├→ Decal para de fazer dano periódico
    └→ Mega explosão após delay
```

## 🔗 Integração de Rede (Multiplayer)

```
Client (Player aperta tecla)
    ↓
cast_ability.rpc() → Global
    ↓
Server (is_multiplayer_authority)
    ↓
Cria RockSling/FireBall
    ├→ Spawna no spawn_container
    ├→ MultiplayerSynchronizer replica
    └→ Todos os clientes veem

Colisão/Reação:
    ├→ Servidor detecta (is_multiplayer_authority)
    ├→ ReactionResolver executa
    ├→ Efeitos spawnam sincronizados
    └→ Todos veem o resultado
```

## 📊 Configuração Técnica

### Camadas de Física

```
collision_layer: 0    (nenhuma)
collision_mask: 8     (layer 4 = mundo/chão)
```

### Replicação de Rede

```
RockSling / FireBall:
├→ position (spawn + replication)
├→ rotation (spawn + replication)
└→ linear_velocity (replication only)

RockDecal:
└→ Estático (não precisa replicação)
```

## 📚 Documentação Criada

```
ROCK_SLING_GUIDE.md         → Como usar Rock Sling
FIREBALL_GUIDE.md           → Como usar FireBall
IMPLEMENTATION_SUMMARY.md   → Resumo da arquitetura
COMPLETE_STRUCTURE.md       → Este arquivo
```

## 🚀 Como Testar

### Mínimo Viável

1. Adicionar autoloads ao `project.godot`:
```ini
[autoload]
Elements="*res://Scripts/Core/elements.gd"
ReactionDatabase="*res://Scripts/Core/reaction_database_instance.gd"
```

2. No Player.gd adicionar:
```gdscript
func _process(_delta):
    if Input.is_action_just_pressed("ui_select"):
        var rock_sling = RockSlingAbility.new().cast(self, -global_transform.basis.z)
        get_tree().root.get_node("World/spawn_container").add_child(rock_sling)
```

3. Testar no editor:
   - Player aperta tecla → Rock aparece e voa
   - Rock bate no chão → Decal aparece
   - FireBall toca rock → Material muda (se implementar)

### Com Reações

1. Criar ReactionRule resource (.tres)
2. Adicionar ao ReactionDatabase
3. Disparar dois projectiles
4. Resultado acontece automaticamente

## ⚡ Performance

- **RigidBody3D**: Otimizado para física
- **Area3D**: Triggers de reação (sem física)
- **MultiplayerSynchronizer**: Apenas posição+velocidade
- **Partículas GPU**: Renderizadas na GPU
- **Luz**: Eficiente com range limitado (8m)

## 🎯 Próximos Elementos

Com a arquitetura pronta, adicionar novos elementos é simples:

1. Criar `{element}_ability.gd`
2. Criar `{element}.tscn` + `{element}.gd`
3. Criar ReactionRules para combinações
4. Adicionar ao `cast_ability()` em Global

Exemplo: Water seria apenas ~200 linhas totais (similar ao Fire).
