# Aba DEV — Efeitos Visuais

Parque de testes dos efeitos visuais. Abre em **Options > DEV** (tanto no menu
principal quanto no menu de pause). Tudo é aplicado na hora, sem reiniciar, e
salvo em `user://settings.cfg` junto com o resto das opções.

O botão **Reset This Tab** volta a aba inteira pros valores padrão.

## Arquivos

| Arquivo | Papel |
|---|---|
| `Scripts/Core/settings.gd` | `SCHEMA["dev"]` — lista de opções (o menu é gerado a partir dela) |
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
| Speed Lines | tela 2D — riscos radiais a partir do centro |
| Distortion | tela 2D — onda senoidal na UV |
| Film Grain | tela 2D — ruído somado |
| Color Grading | tela 2D — exposure / contrast / saturation / temperature / tint |
| Chromatic Aberration | tela 2D — deslocamento radial de R e B |
| Pixelation | tela 2D — UV em grade (+ quantização opcional de cor) |

## Detalhes que importam

* O `ColorRect` dos efeitos 2D vive num `CanvasLayer` de layer **0**, abaixo da
  UI (que usa layer 1). Isso deixa a HUD, a mira e os menus fora dos efeitos e
  legíveis.
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
