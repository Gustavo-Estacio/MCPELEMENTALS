# Testing Guide - Rock Sling + FireBall

## ✅ Pre-requisitos para Testar

1. **Abrir o Editor Godot** do projeto
2. **Cenas devem estar criadas** (já estão):
   - Scenes/Player/Player.tscn
   - Scenes/World/World.tscn
   - Scenes/Effects/rock_sling.tscn
   - Scenes/Effects/fireball.tscn
   - Scenes/Effects/fire_particles.tscn
   - Scenes/Effects/rock_decal.tscn

3. **Scripts devem estar presentes** (já estão):
   - Todos os scripts em Scripts/Core/
   - Todos os scripts em Scripts/Abilities/
   - Todos os scripts em Scripts/Entities/

## 🎮 Como Testar

### Opção 1: No Editor (Mais Fácil)

```
1. Abrir Scenes/World/World.tscn
2. Apertar Play (▶️)
3. Você entra como Server (host)
4. Seu personagem aparece na cena
```

### Opção 2: Multiplayer Local

```
1. Abrir Debug → Monitor → Threads Debug (para ver multiplayer)
2. Play Scene 1 (Servidor) → Espera conectar
3. Abrir segunda janela do Godot
4. Jogar mesma cena 2 (Cliente) → Conecta ao servidor
5. Testar abilities em ambos clientes
```

## 🎯 Testando Cada Habilidade

### **Q - Rock Sling** (Projectile)

**Ação:**
```
1. Apertar Q
2. Segurar por ~1 segundo (charging)
3. Soltar Q
→ Bola marrom viaja em arco
→ Bate no chão e deixa decal
```

**Esperado:**
- ✅ Bola marrom aparece à frente do player
- ✅ Viaja em arco (gravidade natural)
- ✅ Ao bater no chão: desaparece
- ✅ Decal marrom permanece no chão
- ✅ Dano: 10-25 (baseado carregamento)

**Se não funcionar:**
```
❌ Problema: Rock não aparece
→ Verificar: spawn_container está adicionado em World.tscn?
→ Verificar: Global.spawn_container está setado em World._ready()?

❌ Problema: Rock não cai (fica flutuando)
→ Verificar: collision_mask = 8 em rock_sling.tscn?
→ Verificar: Layer 4 existe no mundo?

❌ Problema: Decal não aparece
→ Verificar: rock_decal.tscn existe em res://Scenes/Effects/?
→ Verificar: preload() em rock_sling.gd aponta ao caminho correto?
```

---

### **E - FireBall** (Special Skill)

**Ação:**
```
1. Apertar E
2. Segurar por ~1 segundo (charging)
3. Soltar E
→ Bola vermelha aparece e viaja reto
→ Emite luz laranja
→ Solta partículas de fogo
```

**Esperado:**
- ✅ Bola vermelha/alaranjada aparece
- ✅ Brilha (OmniLight3D pulsante)
- ✅ Partículas saem dela continuamente
- ✅ Ao bater: desaparece
- ✅ Dano: 15-30 (baseado carregamento)
- ✅ Status: BURN (2s)

**Teste com Rock Sling:**
```
1. Disparar Rock Sling (Q)
2. Enquanto rock está voando, disparar FireBall (E)
3. Se FireBall toca Rock:
   → Rock vira laranja/incandescente (material muda)
   → Partículas de fogo saem do rock
   → Ambos desaparecem (reação INFUSE)
```

**Se não funcionar:**
```
❌ Problema: FireBall não brilha
→ Verificar: OmniLight3D existe em fireball.tscn?
→ Verificar: Range > 0, Energy > 0?

❌ Problema: Partículas não saem
→ Verificar: GPUParticles3D existe em fireball.tscn?
→ Verificar: Amount > 0, Lifetime > 0?

❌ Problema: Não infunde o rock
→ Verificar: Area3D em fireball.tscn detecta rock?
→ Verificar: ReactionDatabase tem as regras?
```

---

### **SHIFT - Dash** (Placeholder)

**Ação:**
```
1. Apertar SHIFT
→ Player ganha velocidade na direção que está olhando
```

**Esperado:**
- ✅ Velocidade aumentada por um frame
- ✅ Vira na direção da câmera

---

### **SPACE - Jump** (Original)

**Ação:**
```
1. Apertar SPACE (quando em chão)
→ Player pula
```

**Esperado:**
- ✅ Jump original ainda funciona
- ✅ Pode adicionar ability depois

---

## 🔧 Debugando Issues

### Verificar se as Classes estão Carregadas

```gdscript
# No Console (F8) ou no Script, adicionar:
print("Elements: ", Elements)
print("ReactionDatabase: ", ReactionDatabase)
print("RockSlingAbility: ", RockSlingAbility)
print("FireBallAbility: ", FireBallAbility)
```

### Verificar Rede (Multiplayer)

```gdscript
# No _ready() do Player, adicionar:
print("Is Authority: ", is_multiplayer_authority())
print("Peer ID: ", get_multiplayer_authority())
print("Unique ID: ", multiplayer.get_unique_id())
```

### Verificar Spawn

```gdscript
# No rock_sling.gd, adicionar debug:
func _ready() -> void:
	print("Rock spawned at ", global_position)
	print("Owner peer: ", owner_peer_id)
```

### Verificar Reação

```gdscript
# No reaction_resolver.gd, adicionar:
static func resolve(obj_a: Node, obj_b: Node) -> void:
	print("Reação entre: ", obj_a.name, " e ", obj_b.name)
	print("Outcome: ", rule.outcome)
```

## 📊 Checklist de Teste Completo

```
ROCK SLING:
☐ Aparece ao apertar Q
☐ Carrega (Y aumenta com poder)
☐ Viaja em arco
☐ Colide com chão
☐ Deixa decal
☐ Inflige dano
☐ Pode ser infundido por fogo

FIREBALL:
☐ Aparece ao apertar E
☐ Carrega (aumenta velocidade)
☐ Brilha (luz pulsante)
☐ Emite partículas
☐ Viaja reto
☐ Colide com alvo
☐ Inflige dano + BURN
☐ Aplica lava ao rock

REAÇÕES:
☐ Rock + FireBall = Infusão (lava)
☐ Rock Decal + FireBall = Delayed trigger

MULTIPLAYER:
☐ Dois players podem disparar habilidades
☐ Ambos veem os projectiles
☐ Reações funcionam entre players
☐ RPC sincroniza corretamente

PERFOR MANCE:
☐ Sem lag ao disparar abilities
☐ Partículas não travam
☐ Luz não causa FPS drop
```

## 🐛 Erros Comuns

### "Undefined class RockSlingAbility"
```
Solução: Adicionar autoload em project.godot:
[autoload]
RockSlingAbility="*res://Scripts/Abilities/rock_sling_ability.gd"

Ou chamar diretamente sem autoload (já feito no código)
```

### "cast_ability not found"
```
Solução: Verificar que o método está em Player.gd
Deve ser: @rpc("authority") func cast_ability(...)
```

### "Rock não dispara"
```
Passos:
1. Verificar se Input action 'skill_q' existe
2. Verificar se RockSlingAbility._new() funciona
3. Verificar se Global.spawn_container existe
4. Verificar collision_mask do mundo
```

### "FireBall não infunde rock"
```
Passos:
1. Verificar se Area3D em fireball.tscn existe
2. Verificar if other is RockSling no fireball.gd
3. Verificar ReactionDatabase tem regras
4. Adicionar print() para debug
```

## 🚀 Próximos Testes

1. **Criar Explosion visual** quando reactions acontecem
2. **Testar com múltiplos players** (3+)
3. **Testar persitência** (decal fica por tempo X)
4. **Testar sound effects** (quando implementar)
5. **Testar UI** (mostrar carregamento)
6. **Testar cooldown** (cada habilidade tem cooldown)

## 📝 Template de Bug Report

Se encontrar issue, descrever assim:

```
**Título:** FireBall não infunde Rock Sling

**Passos para reproduzir:**
1. Disparar Rock Sling (Q)
2. Disparar FireBall (E) para atingir rock em voo
3. Esperado: Rock vira laranja
4. Atual: Rock continua marrom

**Logs:**
```
[Output do console]
```

**Ambiente:**
- Godot 4.6
- MCPELEMENTALS branch master
- Multiplayer local
```

---

**Bom teste! 🎮**
