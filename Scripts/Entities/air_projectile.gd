extends RigidBody3D

class_name AirProjectile

@export var DAMAGE := 12
@export var LIFETIME := 3.0
@export var REDIRECT_FORCE := 6.0  # empurrão leve em objetos móveis atingidos (ex: rock sling)

var element: int = 3  # ElementsEnum.Element.AIR
var tag: String = "projectile"
var owner_peer_id: int = -1

var has_hit := false

@onready var area_3d: Area3D = $Area3D


func _ready() -> void:
	area_3d.body_entered.connect(_on_body_entered)
	area_3d.area_entered.connect(_on_area_entered)

	if is_multiplayer_authority():
		get_tree().create_timer(LIFETIME).timeout.connect(func():
			if is_instance_valid(self):
				queue_free()
		)


func _on_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority() or has_hit:
		return

	# Não acerta quem lançou (o slash nasce bem perto/atrás do próprio jogador)
	if owner_peer_id > 0 and body.name == str(owner_peer_id):
		return

	if body.has_method('take_damage'):
		has_hit = true
		body.take_damage(DAMAGE, owner_peer_id, element)
		queue_free()


func _on_area_entered(other: Area3D) -> void:
	if not is_multiplayer_authority():
		return

	# RockSling anda com o próprio corpo em layer 0 (invisível pra body_entered), mas o Area3D
	# dele tem layer real — é assim que outros projéteis o detectam (mesmo padrão do fireball.gd)
	if other.owner is RockSling:
		other.owner.apply_central_impulse(linear_velocity.normalized() * REDIRECT_FORCE)
