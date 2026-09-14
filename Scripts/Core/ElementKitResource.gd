extends Resource

class_name ElementKitResource

# Resource que agrupa 7 habilidades de um elemento
# Um jogador escolhe um elemento = ganha automaticamente todas as 7 abilities

@export var element: int = 0  # ElementsEnum.Element
@export var display_name: String = ""
@export var abilities: Array[AbilityResource] = []  # sempre 7, uma por Slot
