extends Node3D

class_name PuddlePunch

@export var TELEGRAPH_DELAY := 0.4  # metade do anterior (0.8): tempo com a poça no chão antes do soco
@export var RADIUS := 10.0  # 4x o anterior (2.5)
@export var DISC_THICKNESS := 2.4  # 4x o anterior (0.6): alcance bem maior pra CIMA
@export var PUSH_FORCE := 14.0
@export var DAMAGE := 15
@export var HEAL := 45  # em player, agua cura em vez de machucar (3x)
@export var LIFETIME_AFTER_PUNCH := 1.0
@export var EDGE_UP_FACTOR := 0.35  # quanto do empurrão "pra fora da superfície" sobra na borda do raio

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
	# Disco achatado ao longo da normal (não uma esfera): expande no plano
	# perpendicular à normal da superfície, "colado" nela, do tamanho de um player.
	var shape = CylinderShape3D.new()
	shape.radius = RADIUS
	shape.height = DISC_THICKNESS

	var disc_basis = Basis(Quaternion(Vector3.UP, up))
	var disc_center = global_position + up * (DISC_THICKNESS * 0.5)

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(disc_basis, disc_center)
	query.collision_mask = 3  # layers 1 (chão/alvos) e 2 (players)

	var already_hit: Array = []

	for result in space_state.intersect_shape(query, 8):
		var body = result.collider
		if not body or already_hit.has(body):
			continue

		already_hit.append(body)
		var push_dir = _knockback_dir(body.global_position, up)

		if body.is_in_group('Players'):
			# Agua cura aliado (ver Player.heal); o empurrão vale pra todo mundo
			if body.has_method('heal'):
				body.heal(HEAL)
			if body.has_method('apply_knockback'):
				body.apply_knockback.rpc_id(int(body.name), push_dir, PUSH_FORCE)
		elif body is RigidBody3D and "is_moveable" in body and body.is_moveable:
			body.apply_central_impulse(push_dir * PUSH_FORCE * body.mass)
		else:
			# Inimigo (ou qualquer outro alvo): leva dano E empurrão
			if body.has_method('take_damage'):
				body.take_damage(DAMAGE, owner_peer_id, ElementsEnum.Element.WATER)
			if body.has_method('apply_knockback'):
				body.apply_knockback.rpc(push_dir, PUSH_FORCE)

	await get_tree().create_timer(LIFETIME_AFTER_PUNCH).timeout
	if is_instance_valid(self):
		queue_free()


# Empurrão radial em relação ao CENTRO do soco: quem está no meio vai reto pra fora da
# superfície (pra cima, no chão), quem está perto da borda sai mais pro lado, seguindo a
# direção centro -> alvo. Como a referência é a normal da superfície (`up`), isso já sai
# rotacionado 90° sozinho quando o soco acontece numa parede.
func _knockback_dir(target_pos: Vector3, up: Vector3) -> Vector3:
	var to_body = target_pos - global_position
	# Componente do vetor dentro do plano da superfície (tira o que está ao longo da normal)
	var radial = to_body - up * to_body.dot(up)
	var radial_dist = radial.length()

	if radial_dist < 0.01:
		return up  # bem no centro: só pra fora da superfície

	# 0 no centro, 1 na circunferência
	var edge_ratio = clampf(radial_dist / RADIUS, 0.0, 1.0)
	var outward = lerpf(1.0, EDGE_UP_FACTOR, edge_ratio)  # perde força "pra cima" na borda
	return (up * outward + radial.normalized() * edge_ratio).normalized()
