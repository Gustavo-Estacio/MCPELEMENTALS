extends Node3D

class_name PuddlePunch

@export var TELEGRAPH_DELAY := 0.3  # tempo com a poça no chão antes do soco sair
@export var RADIUS := 3.5
@export var PUSH_FORCE := 14.0
@export var DAMAGE := 15
@export var LIFETIME_AFTER_PUNCH := 1.0

@onready var puddle_mesh: MeshInstance3D = $PuddleMesh
@onready var punch_particles: GPUParticles3D = $PunchParticles

var owner_peer_id: int = -1


func _ready() -> void:
	if is_multiplayer_authority():
		await get_tree().create_timer(TELEGRAPH_DELAY).timeout
		if is_instance_valid(self):
			_punch()


@rpc("any_peer", "call_local")
func _play_punch_visual() -> void:
	if is_instance_valid(puddle_mesh):
		puddle_mesh.hide()
	if is_instance_valid(punch_particles):
		punch_particles.restart()


func _punch() -> void:
	_play_punch_visual.rpc()

	var up = global_transform.basis.y.normalized()

	var space_state = get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = RADIUS

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 3  # layers 1 (chão/alvos) e 2 (players)

	var already_hit: Array = []

	for result in space_state.intersect_shape(query, 8):
		var body = result.collider
		if not body or already_hit.has(body):
			continue

		var to_body = body.global_position - global_position
		var horizontal_dir = Vector3(to_body.x, 0, to_body.z)
		horizontal_dir = horizontal_dir.normalized() if horizontal_dir.length() > 0.01 else Vector3.FORWARD
		var push_dir = (horizontal_dir + up).normalized()

		if body.has_method('apply_knockback'):
			already_hit.append(body)
			body.apply_knockback.rpc_id(int(body.name), push_dir, PUSH_FORCE)
			if body.has_method('take_damage') and body.name != str(owner_peer_id):
				body.take_damage(DAMAGE, owner_peer_id, ElementsEnum.Element.WATER)
		elif body is RigidBody3D and "is_moveable" in body and body.is_moveable:
			already_hit.append(body)
			body.apply_central_impulse(push_dir * PUSH_FORCE * body.mass)

	await get_tree().create_timer(LIFETIME_AFTER_PUNCH).timeout
	if is_instance_valid(self):
		queue_free()
