extends Resource

class_name ElementProfileResource

# Identidade/apresentação de um elemento: tudo que muda "só porque o elemento é
# outro" e NÃO é comportamento. Salvo como .tres em res://Resources/Elements/,
# então dá pra ajustar tinta, texto de controles ou rig pelo inspector, sem
# mexer em código.
#
# O que cada tecla FAZ não mora aqui: fica nos kits de habilidade do Player.gd
# (seção 6). kit_element diz qual kit este elemento usa — é assim que o GOLEM
# joga exatamente igual ao EARTH, só com outro modelo.

@export var element: int = ElementsEnum.Element.EARTH
@export var display_name: String = ""

# Qual kit de habilidades usar (GOLEM -> EARTH) e qual botão da hotbar acender.
@export var kit_element: int = ElementsEnum.Element.EARTH
@export var hotbar_element: int = ElementsEnum.Element.EARTH

# Visual: rig do golem em vez do Mannequin, e a tinta aplicada no modelo.
# O golem já vem com pedra/musgo pintados no material próprio, por isso
# applies_tint = false nele.
@export var uses_golem_rig: bool = false
@export var applies_tint: bool = true
@export var tint: Color = Color.WHITE

@export_multiline var controls_text: String = ""
