extends Node

var username := ''

var world: Node3D
var spawn_container: Node3D

const BALL = preload("uid://be342wrf0687")
const ROCK_MAX_CHARGE_POWER := 2.5


func rock_scale_factor(charge_power: float) -> float:
	return 1.0 + (charge_power - 1.0) * 9.0


func _ready() -> void:
	# ReactionDatabase é um autoload (configurado no project.godot)
	# Não precisa criar aqui, já será criado automaticamente
	pass


@rpc("any_peer", "call_local")
func shoot_ball(pos, dir, force):
	var new_ball: RigidBody3D = BALL.instantiate()
	new_ball.source = multiplayer.get_remote_sender_id()
	new_ball.position = pos + Vector3(0.0, 1.0, 0.0) + (dir * 2.0)
	spawn_container.add_child(new_ball, true)
	new_ball.apply_central_impulse(dir * force)


func _apply_fire_shader(fireball: Node3D) -> void:
	# Fireball usa material padrão da cena (sem shader de lava)
	pass


@rpc("any_peer", "call_local")
func cast_ability(ability_type: String, pos: Vector3, dir: Vector3, charge_power: float = 1.0) -> void:
	if not is_multiplayer_authority():
		return

	match ability_type:
		"rock_sling":
			var rock_scene = preload("res://Scenes/Effects/rock_sling.tscn")
			var rock = rock_scene.instantiate()

			spawn_container.add_child(rock, true)

			rock.owner_peer_id = multiplayer.get_remote_sender_id()
			rock.element = 2  # EARTH
			rock.tag = "projectile"
			rock.charge_power = charge_power

			# Escala do rock proporcional ao charge (1x a 10x)
			var scale_factor = rock_scale_factor(charge_power)
			rock.scale = Vector3.ONE * scale_factor

			# Offset horizontal (sem componente vertical, pra não mirar o spawn pro chão)
			var horizontal_dir = Vector3(dir.x, 0, dir.z)
			horizontal_dir = horizontal_dir.normalized() if horizontal_dir.length() > 0.001 else Vector3.FORWARD

			# Quanto maior a pedra, mais alto ela precisa spawnar pra não nascer dentro do chão
			# (a área de detecção também escala com o rock, então o offset acompanha o raio dela: 0.5 * scale_factor)
			var spawn_height = 0.5 * scale_factor + 0.5
			var spawn_pos = pos + Vector3(0, spawn_height, 0) + horizontal_dir * (1.5 * charge_power)
			rock.global_position = spawn_pos

			var velocity = dir * (10.0 * charge_power / 3.0)
			velocity.y += (10.0 * charge_power) / 3.0
			rock.linear_velocity = velocity

		"fireball":
			var fireball_scene = preload("res://Scenes/Effects/fireball.tscn")
			var fireball = fireball_scene.instantiate()

			spawn_container.add_child(fireball, true)

			fireball.owner_peer_id = multiplayer.get_remote_sender_id()
			fireball.element = 0  # FIRE
			fireball.tag = "projectile"
			fireball.charge_power = charge_power

			# Aplicar shader de fogo animado
			_apply_fire_shader(fireball)

			# Offset horizontal (sem componente vertical, pra não mirar o spawn pro chão)
			var horizontal_dir = Vector3(dir.x, 0, dir.z)
			horizontal_dir = horizontal_dir.normalized() if horizontal_dir.length() > 0.001 else Vector3.FORWARD

			var spawn_pos = pos + Vector3(0, 1.8, 0) + horizontal_dir * 2.0
			fireball.global_position = spawn_pos

			var velocity = dir * 25.0 * charge_power
			velocity.y += 5.0
			fireball.linear_velocity = velocity

		"rock_barrage_small":
			_spawn_earth_rock(pos, dir, 0.6, 1.0, 20.0, 2.0, 1.0)

		"rock_barrage_big":
			_spawn_earth_rock(pos, dir, 4.0, 2.0, 14.0, 3.0, 2.0)

		"earth_spike":
			var spike_scene = preload("res://Scenes/Effects/earth_spike.tscn")
			var spike = spike_scene.instantiate()

			spawn_container.add_child(spike, true)
			spike.owner_peer_id = multiplayer.get_remote_sender_id()

			var horizontal_dir = Vector3(dir.x, 0, dir.z)
			horizontal_dir = horizontal_dir.normalized() if horizontal_dir.length() > 0.001 else Vector3.FORWARD

			# charge_power é reaproveitado aqui como o índice do espinho na fila (0 a 5)
			const SPIKE_SPACING := 1.1
			var target_pos = pos + horizontal_dir * (SPIKE_SPACING * (charge_power + 1.0))

			# Raycast pra encontrar o chão nesse ponto da fila
			var space_state = spawn_container.get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(
				target_pos + Vector3.UP * 10.0,
				target_pos - Vector3.UP * 10.0
			)
			var result = space_state.intersect_ray(query)
			spike.global_position = result.position if result else target_pos

		"flame_tick":
			_fire_aoe(pos, dir, 2.5, 1.2, 8, false)

		"fire_cone":
			_fire_aoe(pos, dir, 3.0, 2.0, 25, true)

		"fire_blast":
			_fire_aoe(pos, dir, 0.0, 3.5, 35, true)

		"air_slash":
			var slash_scene = preload("res://Scenes/Effects/air_slash.tscn")
			var slash = slash_scene.instantiate()

			spawn_container.add_child(slash, true)
			slash.owner_peer_id = multiplayer.get_remote_sender_id()

			var aim_dir = dir.normalized() if dir.length() > 0.001 else Vector3.FORWARD
			var horizontal_dir = Vector3(aim_dir.x, 0, aim_dir.z)
			horizontal_dir = horizontal_dir.normalized() if horizontal_dir.length() > 0.001 else Vector3.FORWARD

			# Sai de trás do jogador, cortando pra frente, guiado pela câmera (pra cima/baixo também)
			slash.global_position = pos + Vector3(0, 1.2, 0) - horizontal_dir * 1.0
			slash.look_at(slash.global_position + aim_dir, Vector3.UP)
			slash.linear_velocity = aim_dir * 22.0

		"slash_of_air":
			_deflect_projectiles(pos, dir)

		"tornado":
			var tornado_scene = preload("res://Scenes/Effects/tornado.tscn")
			var tornado = tornado_scene.instantiate()

			spawn_container.add_child(tornado, true)
			tornado.owner_peer_id = multiplayer.get_remote_sender_id()

			var horizontal_dir = Vector3(dir.x, 0, dir.z)
			horizontal_dir = horizontal_dir.normalized() if horizontal_dir.length() > 0.001 else Vector3.FORWARD

			tornado.setup(pos + horizontal_dir * 0.6, horizontal_dir)

		"wind_torrent":
			var torrent_scene = preload("res://Scenes/Effects/wind_torrent.tscn")
			var torrent = torrent_scene.instantiate()

			spawn_container.add_child(torrent, true)
			torrent.owner_peer_id = multiplayer.get_remote_sender_id()

			var aim_dir = dir.normalized() if dir.length() > 0.001 else Vector3.FORWARD
			torrent.setup(pos + Vector3(0, 1.2, 0) + aim_dir * 0.8, aim_dir)

		"air_dash_burst":
			var wind_particles = preload("res://Scenes/Effects/wind_particles.tscn")
			var particles_instance = wind_particles.instantiate()
			particles_instance.position = pos
			spawn_container.add_child(particles_instance, true)
			particles_instance.restart()
			var timer = spawn_container.get_tree().create_timer(particles_instance.lifetime * 1.2)
			timer.timeout.connect(func():
				if is_instance_valid(particles_instance):
					particles_instance.queue_free()
			)


# RMB do Air: cone na frente do jogador que "apara" projéteis móveis, zerando o momentum deles
# (eles caem só com a gravidade a partir daí).
func _deflect_projectiles(pos: Vector3, dir: Vector3) -> void:
	const DEFLECT_RANGE := 4.0
	const DEFLECT_HALF_ANGLE_DEG := 45.0

	var horizontal_dir = Vector3(dir.x, 0, dir.z)
	horizontal_dir = horizontal_dir.normalized() if horizontal_dir.length() > 0.001 else Vector3.FORWARD

	var caster_pos = pos + Vector3(0, 1.0, 0)

	for node in spawn_container.get_children():
		if not (node is RigidBody3D):
			continue

		var to_node = node.global_position - caster_pos
		if to_node.length() > DEFLECT_RANGE:
			continue

		var flat_to_node = Vector3(to_node.x, 0, to_node.z)
		if flat_to_node.length() < 0.01:
			continue

		var angle = rad_to_deg(horizontal_dir.angle_to(flat_to_node.normalized()))
		if angle <= DEFLECT_HALF_ANGLE_DEG:
			node.linear_velocity = Vector3.ZERO
			node.angular_velocity = Vector3.ZERO

	var wind_particles = preload("res://Scenes/Effects/wind_particles.tscn")
	var particles_instance = wind_particles.instantiate()
	particles_instance.position = caster_pos + horizontal_dir * 2.0
	spawn_container.add_child(particles_instance, true)
	particles_instance.restart()
	var timer = spawn_container.get_tree().create_timer(particles_instance.lifetime * 1.2)
	timer.timeout.connect(func():
		if is_instance_valid(particles_instance):
			particles_instance.queue_free()
	)


# Dano em área de fogo (usado por flamethrower, cone e fire blast) + visual.
func _fire_aoe(pos: Vector3, dir: Vector3, distance: float, radius: float, damage: int, big_visual: bool) -> void:
	var horizontal_dir = Vector3(dir.x, 0, dir.z)
	horizontal_dir = horizontal_dir.normalized() if horizontal_dir.length() > 0.001 else Vector3.FORWARD

	var center = pos + Vector3(0, 1.0, 0) + horizontal_dir * distance
	var caster_peer_id = multiplayer.get_remote_sender_id()

	var space_state = spawn_container.get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = radius

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), center)
	query.collision_mask = 3  # layers 1 (chão/alvos) e 2 (players)

	for result in space_state.intersect_shape(query, 8):
		var body = result.collider
		if body and body.has_method('take_damage') and body.name != str(caster_peer_id):
			body.take_damage(damage, caster_peer_id, 0)  # ElementsEnum.Element.FIRE

	if big_visual:
		var explosion_scene = preload("res://Scenes/Effects/explosion.tscn")
		var explosion = explosion_scene.instantiate()
		explosion.position = center
		explosion.scale = Vector3.ONE * (radius / 1.5)
		spawn_container.add_child(explosion, true)
	else:
		var fire_particles = preload("res://Scenes/Effects/fire_particles.tscn")
		var particles_instance = fire_particles.instantiate()
		particles_instance.position = center
		particles_instance.scale = Vector3.ONE * radius
		spawn_container.add_child(particles_instance, true)
		particles_instance.restart()
		var timer = spawn_container.get_tree().create_timer(particles_instance.lifetime * 1.2)
		timer.timeout.connect(func():
			if is_instance_valid(particles_instance):
				particles_instance.queue_free()
		)


# Pedra de terra não-carregável (sem hold), usada pelo LMB/RMB. Nunca é ignitável.
func _spawn_earth_rock(pos: Vector3, dir: Vector3, scale_factor: float, damage_charge: float, speed: float, vertical_boost: float, forward_offset: float) -> void:
	var rock_scene = preload("res://Scenes/Effects/rock_sling.tscn")
	var rock = rock_scene.instantiate()

	spawn_container.add_child(rock, true)

	rock.owner_peer_id = multiplayer.get_remote_sender_id()
	rock.element = 2  # EARTH
	rock.tag = "projectile"
	rock.charge_power = damage_charge
	rock.ignitable = false
	rock.scale = Vector3.ONE * scale_factor

	var horizontal_dir = Vector3(dir.x, 0, dir.z)
	horizontal_dir = horizontal_dir.normalized() if horizontal_dir.length() > 0.001 else Vector3.FORWARD

	var spawn_height = 0.5 * scale_factor + 0.5
	rock.global_position = pos + Vector3(0, spawn_height, 0) + horizontal_dir * forward_offset

	var velocity = dir * speed
	velocity.y += vertical_boost
	rock.linear_velocity = velocity


@rpc("any_peer", "call_local")
func spawn_earth_leap_decal(pos: Vector3) -> void:
	if not is_multiplayer_authority():
		return

	var decal_scene = preload("res://Scenes/Effects/rock_decal.tscn")
	var decal = decal_scene.instantiate()
	decal.position = pos
	decal.scale = Vector3.ONE * rock_scale_factor(ROCK_MAX_CHARGE_POWER)
	decal.element = 2  # EARTH
	spawn_container.add_child(decal, true)


@rpc("any_peer", "call_local")
func spawn_boulder_decal(pos: Vector3, infused_with: int = -1, decal_scale: float = 1.0) -> void:
	if not is_multiplayer_authority():
		return

	var decal_scene = preload("res://Scenes/Effects/rock_decal.tscn")
	var decal = decal_scene.instantiate()
	decal.position = pos
	decal.scale = Vector3.ONE * decal_scale
	decal.element = 2  # EARTH
	decal.infused_with = infused_with
	spawn_container.add_child(decal, true)
