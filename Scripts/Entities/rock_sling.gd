extends RigidBody3D

class_name RockSling

@onready var area_3d: Area3D = $Area3D

var element: int = 2  # ElementsEnum.Element.EARTH
var tag: String = "projectile"
var owner_peer_id: int = -1
var infused_with: int = -1  # -1 = não infundido
var charge_power: float = 1.0
var ignitable := true
var is_moveable := true  # habilidades físicas que o Wind Torrent do Air consegue empurrar/redirecionar

var has_landed := false

@export var EXPLOSION_SCALE := 3.0  # ao menos o dobro do tamanho do player

func _ready() -> void:
	area_3d.area_entered.connect(_on_area_entered)
	area_3d.body_entered.connect(_on_body_entered)

	if is_multiplayer_authority():
		angular_velocity = Vector3(
			randf_range(-3.0, 3.0),
			randf_range(-3.0, 3.0),
			randf_range(-3.0, 3.0)
		)


func _on_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return

	if body.has_method('take_damage'):
		var damage = int(50.0 * charge_power)
		var damage_element = infused_with if infused_with != -1 else element
		body.take_damage(damage, owner_peer_id, damage_element)

	# O decal/explosão não decide mais aqui — vem do contato físico real
	# em _integrate_forces, que tem a posição e a normal corretas da superfície.


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if has_landed or not is_multiplayer_authority():
		return

	if state.get_contact_count() == 0:
		return

	var collider = state.get_contact_collider_object(0)
	var contact_point = state.get_contact_collider_position(0)
	var contact_normal = state.get_contact_local_normal(0)

	if collider and collider.is_in_group("Targets"):
		# Alvos (props atingíveis) não recebem o decal na lateral: projeta no chão
		# embaixo do centro do alvo, igual pediram.
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(
			collider.global_position,
			collider.global_position - Vector3.UP * 100.0
		)
		query.exclude = [collider.get_rid()]
		var result = space_state.intersect_ray(query)
		if result:
			_spawn_decal_and_cleanup(result.position, result.normal)
		else:
			_spawn_decal_and_cleanup()  # sem chão embaixo: não cria decal no ar
	else:
		_spawn_decal_and_cleanup(contact_point, contact_normal)


func _on_area_entered(other: Area3D) -> void:
	if not is_multiplayer_authority():
		return

	if not (other is RockDecal):
		return

	if get_instance_id() == other.get_instance_id():
		return

	# Só processa ElementalCarrier (decals)
	if other is RockDecal:
		var rule = ReactionDatabase.find_rule(element, tag, other.element, other.tag)
		if rule:
			ReactionResolver.resolve(self, other)


@rpc("any_peer", "call_local")
func set_infused_with(elem: int) -> void:
	infused_with = elem
	_update_visual_infusion()

	if elem == ElementsEnum.Element.FIRE:
		var fire_particles = preload("res://Scenes/Effects/fire_particles.tscn")
		var particles_instance = fire_particles.instantiate()
		add_child(particles_instance)


func _update_visual_infusion() -> void:
	if has_node("Model") and infused_with == ElementsEnum.Element.FIRE:
		var shader = load("res://Shaders/lava_ignite.gdshader")
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("dark_lava_color", Color(0.15, 0.02, 0.0))
		material.set_shader_parameter("light_lava_color", Color(1.0, 0.45, 0.05))
		material.set_shader_parameter("speed", 1.2)
		material.set_shader_parameter("scale", 8.0)
		material.set_shader_parameter("sharpness", 20.0)
		material.set_shader_parameter("emission_intensity", 3.0)

		# A pedra vem de um .glb, então o override vai em cada MeshInstance3D de dentro do modelo.
		for mesh_instance in $Model.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh_instance.mesh.get_surface_count():
				mesh_instance.set_surface_override_material(surface, material)


func _spawn_decal_and_cleanup(impact_pos = null, impact_normal = null) -> void:
	if has_landed:
		return

	has_landed = true

	if is_multiplayer_authority() and impact_pos != null:
		if infused_with == ElementsEnum.Element.FIRE:
			_notify_owner_shake(0.25 * charge_power)
			await _explode(impact_pos)
		else:
			_notify_owner_shake(0.08 * charge_power)
			var decal_scene = preload("res://Scenes/Effects/rock_decal.tscn")
			var decal = decal_scene.instantiate()
			# O decal sempre projeta na superfície seguindo a normal do impacto
			# (chão = pra cima, parede = na horizontal e vertical, etc)
			var decal_basis = Basis(Quaternion(Vector3.UP, impact_normal)).scaled(scale)
			decal.transform = Transform3D(decal_basis, impact_pos)
			decal.element = element
			decal.infused_with = infused_with
			get_parent().add_child(decal, true)

	queue_free()


func _notify_owner_shake(amount: float) -> void:
	if owner_peer_id <= 0:
		return

	for current_player in get_tree().get_nodes_in_group('Players'):
		if current_player.name == str(owner_peer_id):
			current_player.trigger_camera_shake.rpc_id(owner_peer_id, amount)
			break


@rpc("any_peer", "call_local")
func _sync_hide_and_freeze() -> void:
	hide()
	freeze = true


func _explode(pos: Vector3) -> void:
	_sync_hide_and_freeze.rpc()

	var explosion_scene = preload("res://Scenes/Effects/explosion.tscn")
	var explosion = explosion_scene.instantiate()
	explosion.position = pos
	explosion.scale = Vector3.ONE * (EXPLOSION_SCALE * charge_power)
	get_parent().add_child(explosion, true)
