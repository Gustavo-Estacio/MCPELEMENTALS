extends RigidBody3D

class_name FireBall

@onready var area_3d: Area3D = $Area3D
@onready var light_3d: OmniLight3D = $OmniLight3D
@onready var particles: GPUParticles3D = $GPUParticles3D

var element: int = ElementsEnum.Element.FIRE
var tag: String = "projectile"
var owner_peer_id: int = -1
var infused_with: int = -1
var charge_power: float = 1.0

var has_collided := false

@export var SPIN_SPEED := 10.0


func _ready() -> void:
	area_3d.area_entered.connect(_on_area_entered)
	area_3d.body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return

	# Gira em torno do próprio eixo de deslocamento, sem alterar a direção do voo
	if linear_velocity.length() > 0.01:
		angular_velocity = linear_velocity.normalized() * SPIN_SPEED


func _on_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return

	if body.has_method('take_damage'):
		var damage = int(20.0 * charge_power)
		body.take_damage(damage, owner_peer_id, element)

	_on_impact()


func _on_area_entered(other: Area3D) -> void:
	if not is_multiplayer_authority():
		return

	# Verifica se é um RockSling via proprietário/tag
	if other.is_in_group("RockSling") or (other.owner and other.owner is RockSling):
		if other.owner is RockSling:
			if other.owner.ignitable:
				_infuse_rock_with_fire(other.owner)
			_on_impact()
			return

	if other is RockDecal:
		if has_node("/root/ReactionDatabase"):
			var db = get_node("/root/ReactionDatabase")
			var rule = db.find_rule(element, tag, other.element, other.tag)
			if rule:
				ReactionResolver.resolve(self, other)
		return


func _infuse_rock_with_fire(rock: RockSling) -> void:
	# Busca a reação
	if has_node("/root/ReactionDatabase"):
		var db = get_node("/root/ReactionDatabase")
		var rule = db.find_rule(element, tag, rock.element, rock.tag)
		if rule:
			ReactionResolver.resolve(self, rock)

	# Aplica shader de lava e partículas no rock (via RPC pra todos os peers verem)
	rock.set_infused_with.rpc(ElementsEnum.Element.FIRE)


func _on_impact() -> void:
	if has_collided:
		return

	has_collided = true
	queue_free()
