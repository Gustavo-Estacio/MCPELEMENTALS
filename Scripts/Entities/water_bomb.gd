extends RigidBody3D

class_name WaterBomb

@onready var area_3d: Area3D = $Area3D

var element: int = ElementsEnum.Element.WATER
var tag: String = "projectile"
var owner_peer_id: int = -1

var has_landed := false

@export var SPIN_SPEED := 6.0
@export var SPLASH_DAMAGE := 20
@export var SPLASH_RADIUS := 3.0


func _ready() -> void:
	area_3d.body_entered.connect(_on_body_entered)

	if is_multiplayer_authority():
		angular_velocity = Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0))


func _on_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return

	if body.has_method('take_damage'):
		body.take_damage(SPLASH_DAMAGE, owner_peer_id, element)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if has_landed or not is_multiplayer_authority():
		return

	if state.get_contact_count() == 0:
		return

	var contact_point = state.get_contact_collider_position(0)
	_land(contact_point)


func _land(pos: Vector3) -> void:
	if has_landed:
		return

	has_landed = true

	_notify_owner_shake(0.3)
	Global.spawn_rain_zone.rpc_id(1, pos)

	queue_free()


func _notify_owner_shake(amount: float) -> void:
	if owner_peer_id <= 0:
		return

	for current_player in get_tree().get_nodes_in_group('Players'):
		if current_player.name == str(owner_peer_id):
			current_player.trigger_camera_shake.rpc_id(owner_peer_id, amount)
			break
