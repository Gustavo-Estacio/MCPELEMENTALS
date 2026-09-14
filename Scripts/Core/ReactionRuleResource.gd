extends Resource

class_name ReactionRuleResource

# Resource que define UMA regra de reação elemental
# Pode ser salva como .tres: earth_fire_reaction.tres, etc

enum Outcome {
	SPAWN_AND_SPAWN,   # os dois somem, nasce um efeito novo
	INFUSE,            # A absorve B, muda visual/comportamento
	DELAYED_TRIGGER,   # nada acontece na hora, um timer começa, depois explode
	MUTATE_DECAL,      # um decal no chão muda de estado
}

@export var element_a: int = 0  # ElementsEnum.Element.FIRE
@export var element_b: int = 1  # ElementsEnum.Element.WATER
@export var tag_a: String = ""  # "" = qualquer contexto, ou "projectile"/"decal"
@export var tag_b: String = ""

@export var outcome: Outcome = Outcome.SPAWN_AND_SPAWN
@export var result_scene: PackedScene  # explosão, ou o "estado infundido" da boulder
@export var delay: float = 0.0  # usado em DELAYED_TRIGGER
