extends RigidBody3D

class_name WaterPellet

@onready var area_3d: Area3D = $Area3D

var element: int = ElementsEnum.Element.WATER
var tag: String = "projectile"
var owner_peer_id: int = -1

var has_collided := false

@export var LIFETIME := 3.0
@export var DAMAGE := 8
@export var HEAL := 24  # em player, agua cura em vez de machucar (3x)


func _ready() -> void:
	area_3d.body_entered.connect(_on_body_entered)

	if is_multiplayer_authority():
		get_tree().create_timer(LIFETIME).timeout.connect(func():
			if is_instance_valid(self):
				queue_free()
		)


func _on_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return

	# Agua cura player e machuca inimigo (ver Player.heal)
	if body.is_in_group('Players') and body.has_method('heal'):
		body.heal(HEAL)
	elif body.has_method('take_damage'):
		body.take_damage(DAMAGE, owner_peer_id, element)

	_on_impact()


func _on_impact() -> void:
	if has_collided:
		return

	has_collided = true
	queue_free()
