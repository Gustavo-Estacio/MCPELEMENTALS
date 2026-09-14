extends Resource

class_name AbilityResource

# Resource que define uma habilidade (pode ser salva como .tres)
# Exemplo: fire_q.tres, earth_q.tres, etc

@export var ability_name: String = ""
@export var slot: int = 0  # ElementsEnum.Slot
@export var element: int = 0  # ElementsEnum.Element
@export var cooldown: float = 1.0
@export var resource_cost: float = 0.0  # mana/stamina, se um dia existir
@export var effect_scene: PackedScene
@export var icon: Texture2D
@export var tags: Array[String] = []  # ex: ["projectile", "aoe", "charge"]
