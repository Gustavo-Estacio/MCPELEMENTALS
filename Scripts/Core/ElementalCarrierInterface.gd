extends Node

class_name ElementalCarrierInterface

# Interface padrão para qualquer objeto que carrega um elemento
# Implementar: RockSling, FireBall, RockDecal, qualquer projectile
# Qualquer objeto que interaja com o sistema de reações deve implementar isso

var element: int = 0  # ElementsEnum.Element
var tag: String = ""  # "projectile", "decal", "charge", etc
var owner_user_id: int = -1
var infused_with: int = -1  # -1 = não infundido
