# Aba DEV — Efeitos Visuais

Parque de testes dos efeitos visuais. Abre em **Options > DEV** (tanto no menu
principal quanto no menu de pause). Tudo é aplicado na hora, sem reiniciar, e
salvo em `user://settings.cfg` junto com o resto das opções.

O botão **Reset This Tab** volta a aba inteira pros valores padrão. O botão
**Salvar essa configuração** (canto de baixo à esquerda, só na aba DEV) grava o
estado atual em `Presets/<nome>.cfg`, e o dropdown ao lado carrega de volta.

Nas outras abas o menu fica centralizado, com o fundo escurecido. Ao entrar na
aba **DEV** ele vira um painel encostado na esquerda ocupando 1/4 da tela, e o
escurecido some: dá pra mexer nos sliders vendo o jogo mudar atrás. Quem faz
isso é `OptionsMenu._update_layout()` — o painel é reparentado entre o
`CenterContainer` e o dock da esquerda, e as linhas da aba DEV encolhem
(rótulo, controle e fonte) pra caber no painel estreito.

## Arquivos

| Arquivo | Papel |
|---|---|
| `Scripts/Core/settings.gd` | `SCHEMA["dev"]` — lista de opções (o menu é gerado a partir dela) |
| `Scripts/UI/options_menu.gd` | monta o menu; a aba DEV vira dock de 1/4 da tela |
| `Scripts/UI/skill_hud.gd` | HUD de cooldowns/cargas embaixo no meio da tela |
| `Scripts/Core/dev_fx.gd` | autoload `DevFX` — cria e alimenta tudo em runtime |
| `Shaders/PostFX/screen_fx.gdshader` | pós-processamento 2D (uber shader) |
| `Shaders/PostFX/depth_fx.gdshader` | quad de tela cheia que lê o depth buffer |
| `Shaders/PostFX/toon.gdshader` | material toon aplicado por superfície |

## Como cada efeito é feito

| Efeito | Onde roda |
|---|---|
| Cel Shading | tela 2D — posteriza a luminância da imagem final |
| Outline | quad 3D — segunda derivada da profundidade (silhueta) |
| Rim Light | quad 3D — normal reconstruída do depth buffer |
| Bloom | `Environment.glow` do WorldEnvironment da cena |
| Toon Shader | `ShaderMaterial` por superfície, com `light()` em faixas |
| Distortion | tela 2D — onda senoidal na UV |
| Film Grain | tela 2D — ruído somado |
| Color Grading | tela 2D — exposure / contrast / saturation / temperature / tint |
| Chromatic Aberration | tela 2D — deslocamento radial de R e B |
| Pixelation | tela 2D — UV em grade (+ quantização opcional de cor) |

## Speed Lines (fora da aba DEV)

As speed lines não são opção de menu: quem liga é o gameplay. Os presets ficam
em `DevFX.SPEEDLINES_PRESETS` e a API é:

| Chamada | Uso |
|---|---|
| `DevFX.speedlines_start(preset)` | liga até alguém parar (efeito de duração variável) |
| `DevFX.speedlines_burst(preset, hold, fade)` | opacidade cheia por `hold`, some em `fade` |
| `DevFX.speedlines_stop(fade, preset)` | desliga; `preset` opcional só desliga se for aquele |

Quem dispara, em `Scripts/Player/Player.gd`:

| Situação | Preset | Duração |
|---|---|---|
| Speed boost andando fora de combate | `walk` | enquanto o boost durar |
| Boulder Dash (Earth) | `dash` | toda a duração do dash |
| Fire Dash (Fire) | `dash` | toda a duração do dash |
| Air Dash (Air) | `dash` | cheio até 1.0s, 100% → 0% até 1.4s |

`_update_speedlines_state()` roda todo frame de física e decide o estado a
partir de `is_boulder` / `is_fire_dashing` / `is_boosted`, então os dashes com
duração variável não precisam de hook no início e no fim. O Air Dash é a
exceção: tem tempo próprio (`AIR_DASH_LINES_HOLD` / `AIR_DASH_LINES_FADE`) e
usa `speedlines_burst`.

**Fora de combate**: o speed boost agora exige andar (`BOOST_DELAY`) **e** estar
`OUT_OF_COMBAT_DELAY` segundos (5s) sem usar skill e sem tomar dano. Usar
qualquer ação de `Player.COMBAT_ACTIONS` ou tomar dano chama `_enter_combat()`,
que zera os dois contadores e derruba o boost na hora. O pulo fica fora da
lista de propósito.

## HUD de cooldowns

`Scripts/UI/skill_hud.gd` (`SkillHUD`) desenha os slots de skill centralizados
embaixo no meio da tela. Ela é criada em runtime pelo Player, dentro do
`CanvasLayer` dele, e só existe pro jogador local.

A HUD não sabe nada das skills: todo frame ela lê `Player.get_skill_slots()`,
que devolve, pro elemento atual, uma lista de `{key, name, ratio, remaining,
charges, max_charges, active}`. O preenchimento sobe de baixo pra cima conforme
recarrega (cheio = pronto), os pips em cima do slot são as cargas (Air Dash 3,
duplo pulo 1) e o número no meio é o tempo que falta.

Os cooldowns vivem em `Player._cooldowns` e existem **só pra HUD**: quem
continua controlando o uso das skills são as flags `busy` de cada uma.
`_start_cooldown(id, duração)` é chamado junto com a flag e `_clear_cooldown(id)`
corta a barra quando a skill termina antes (soltar o Flamethrower, cancelar o
Boulder Dash).

## Presets

`Presets/` guarda um `.cfg` por configuração salva, com todas as chaves `dev_`.
Salvar escreve em `res://`, o que só funciona rodando do editor — é ferramenta
de desenvolvimento, não opção de jogador. A vantagem é que o preset entra no
repositório junto com o resto do projeto.

API em `Settings`: `save_preset(nome)`, `load_preset(nome)`, `preset_names()`.

## Detalhes que importam

* O `ColorRect` dos efeitos 2D vive num `CanvasLayer` de layer **0**, abaixo da
  UI (que usa layer 1). Isso deixa a HUD, a mira e os menus fora dos efeitos e
  legíveis.
* As speed lines ignoram o toggle mestre da aba DEV: são gameplay, não teste.
* O quad do outline/rim escreve `POSITION` direto em clip space, então ele não
  precisa ser filho da câmera — mora no próprio autoload e usa
  `extra_cull_margin` pra nunca ser descartado.
* O **Toon Shader** troca o material das superfícies e guarda o original num
  meta (`devfx_toon_originals`); desligar o toggle devolve tudo. Ele pula:
  * quem já usa `ShaderMaterial` (lava, céu);
  * material `unshaded` ou transparente (trails, decals, partículas);
  * quem tem `material_override` próprio;
  * qualquer nó no grupo `no_toon` — use esse grupo pra proteger um objeto.
* O toon não escreve `ALPHA` de propósito. Qualquer escrita em `ALPHA` marca o
  material como transparente e a malha sai da passada opaca (o chão passa a
  cobrir tudo que estiver atrás dele).
* Bloom é a única opção que mexe num recurso da cena (`Environment`). A mudança
  é só em runtime, o `.tscn` não é tocado.

## Adicionar um efeito novo

1. Descreva as opções em `SCHEMA["dev"]` (`bool`, `range`, `enum`, `header`).
2. Trate as chaves novas em `dev_fx.gd` (`_apply_screen`, `_apply_depth`, ...).
3. Se for pós-processamento 2D, some as uniforms no `screen_fx.gdshader` e
   coloque a chave do toggle em `DevFX.SCREEN_TOGGLES`.
