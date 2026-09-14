# FireBall - Implementação Completa

## 🔥 O que é FireBall?

**Habilidade E (SPECIAL_SKILL)** do elemento FIRE

Uma bola de fogo que viaja pelo ar, emitindo luz e partículas, e pode infundir o Rock Sling com poder de lava.

## ✨ Características Visuais

### 🟠 Aparência da Bola
- **Cor**: Vermelho-alaranjado brilhante
- **Material**: Emission + Light
- **Tamanho**: 0.3 de raio (um pouco maior que Rock)
- **Textura**: `red/texture_11.png` do Kenney
- **Emissão**: Brilho constante (1.5x energia)

### 💡 Luz
- **OmniLight3D** pulsante (0.3s ciclo)
- **Range**: 8 metros
- **Cor**: Laranja-avermelhado
- **Efeito**: Pulsa de 2.0 a 1.0 de energia

### 🌪️ Partículas
- **Quantidade**: 20 partículas simultâneas
- **Lifetime**: 1.5s
- **Velocidade**: 1.5-3.0 m/s
- **Spread**: 180° (todas as direções)
- **Forma**: Pequenas esferas laranja
- **Efeito de Gravidade**: Cai lentamente

## 🎮 Mecânicas

### Carregamento (Charging)
- **Tempo máximo**: 1.5s
- **Poder mínimo**: 1.0x
- **Poder máximo**: 2.0x
- **Dano base**: 15 damage

```
Sem carregar: 15 dano
Carregado 100%: 30 dano
```

### Movimento
- **Velocidade base**: 25 m/s
- **Velocidade com carga**: até 50 m/s
- **Arco**: Leve arco (Y+5)
- **Física**: RigidBody3D com gravidade

### Impacto
- **Dano**: 15x power (max 30)
- **Status**: Burn por 2 segundos
- **Knockback**: 7.0x force
- **Efeito**: Desaparece ao bater

## 🪨 Interação com Rock Sling

Quando FireBall toca Rock Sling **no ar**:

1. **Aplica Infusão**:
   - Material muda para laranja/vermelho brilhante
   - Emissão ativada
   - Mesh fica incandescente

2. **Spawna Partículas de Fogo**:
   - Sobre o rock
   - Continuam emitindo enquanto ele voa
   - Criam trilha visual de lava

3. **Efeito Especial**:
   - Rock fica visualmente "inflamável"
   - Potencial de reações diferente ao cair

4. **Reação ReactionDatabase**:
   - Procura por regra de FIRE + EARTH
   - Se encontrar, executa ReactionResolver

## 🔄 Reações Possíveis

### FIRE projectile + EARTH projectile

Há 3 possíveis reações baseado no contexto:

#### 1. **SPAWN_AND_SPAWN** (Explosão)
```
Condição: Ambos em ar ou colidem violentamente
Resultado: Explosão no ponto médio
Ambos: Desaparecem
Efeito: mega_explosion.tscn
```

#### 2. **INFUSE** (Lava)
```
Condição: FireBall toca Rock em voo
Resultado: Rock absorve poder do fogo
Rock: Fica inflamável, muda material
Fogo: Desaparece
Efeito: Partículas de fogo emitidas pelo rock
```

#### 3. **DELAYED_TRIGGER** (Bomba)
```
Condição: FireBall toca o Rock Decal (no chão)
Resultado: Timer de 2s começa
Decal: Para de emitir dano periódico
Após 2s: Mega explosão no local
```

## 📊 Configuração do Material

```gdscript
var material = StandardMaterial3D.new()
material.albedo_color = Color(1.0, 0.5, 0.0, 1.0)  # Laranja
material.emission_enabled = true
material.emission = Color(1.0, 0.4, 0.0)           # Laranja escuro
material.emission_energy_multiplier = 1.5
```

## 🎨 Efeito de Lava (aplicado ao Rock)

```gdscript
var lava_material = StandardMaterial3D.new()
lava_material.albedo_color = Color(1.0, 0.4, 0.0, 1.0)
lava_material.emission_enabled = true
lava_material.emission = Color(1.0, 0.5, 0.0)
lava_material.emission_energy_multiplier = 1.5
```

## 🚀 Como Usar

### No Player.gd

```gdscript
var fireball_ability: FireBallAbility

func _ready():
	fireball_ability = FireBallAbility.new()

func _process(_delta):
	# E = SPECIAL_SKILL (habilidade especial)
	if Input.is_action_just_pressed("ability_e"):
		fireball_ability.start_charge()
		
	if Input.is_action_just_released("ability_e"):
		_cast_fireball()

func _cast_fireball() -> void:
	var direction = -global_transform.basis.z
	var fireball = fireball_ability.cast(self, direction)
	Global.spawn_container.add_child(fireball)
```

### No Global.gd (RPC)

```gdscript
# Já adicionado, você pode chamar:
Global.cast_ability.rpc("fireball", position, direction)
```

## 📁 Arquivos Criados

```
Scripts/
├── Entities/
│   └── fireball.gd              ✨ Lógica do projectile
├── Abilities/
│   └── fireball_ability.gd      ✨ Controle da habilidade
└── Data/
    └── reaction_rules_example.gd ✨ Exemplos de regras

Scenes/
├── Effects/
│   ├── fireball.tscn            ✨ Cena do projectile
│   └── fire_particles.tscn      ✨ Partículas extras
```

## ⚙️ Componentes da Cena

```
FireBall (RigidBody3D)
├── CollisionShape3D (Física)
├── MeshInstance3D (Esfera vermelha)
├── OmniLight3D (Luz pulsante)
├── GPUParticles3D (Partículas)
├── MultiplayerSynchronizer (Rede)
└── Area3D (Detecção de reação)
```

## 🎯 Status Effect: BURN

Quando FireBall acerta um alvo:
- **Effect**: "burn"
- **Duration**: 2.0 segundos
- **Visual**: Textura vermelha ou shader de fogo
- **Dano**: Periódico (implementar em HealthComponent)

## 🔮 Próximos Passos

1. **Explosão Visual**
   - Criar cena explosion.tscn com efeito visual
   - Partículas brilhantes
   - Som de explosão

2. **Shader Dinâmico**
   - Shader que faz rock "queimar" enquanto está infundido
   - Efeito de lava escorrendo

3. **Audio**
   - SFX ao carregar fireball
   - Som de lançamento
   - Som de impacto
   - Som de absorção pelo rock

4. **Mais Reações**
   - FIRE + WATER = Steam
   - FIRE + AIR = Whirlwind
   - FIRE + ELECTRIC = Lightning
