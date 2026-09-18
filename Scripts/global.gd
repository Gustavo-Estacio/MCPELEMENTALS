extends Node

var username := ''

var world: Node3D
var spawn_container: Node3D

const BALL = preload("uid://be342wrf0687")
const ROCK_MAX_CHARGE_POWER := 2.5
# Força de lançamento do Rock Sling, multiplicada pelo charge. Vale pros dois eixos
# (frente e o empurrão vertical), então mirando na horizontal o arremesso sai a 45° e o
# ângulo não muda com esse número — só a velocidade.
#
# Calibrado pro DOBRO DO ALCANCE, não pro dobro da força: alcance balístico cresce com o
# quadrado da velocidade, então dobrar a força daria ~4x de distância. 4.9 (era 10.0/3.0,
# ou seja 1.47x) dobra o alcance dentro de ~3% em toda a faixa de charge.
const ROCK_SLING_LAUNCH_SPEED := 4.9


# Decal/poça/zona no chão NUNCA pode ficar grudado num inimigo/player/alvo flutuando —
# projeta pra baixo até achar chão/parede de verdade e usa esse ponto. Sem chão embaixo
# (buraco, borda de plataforma), cai de volta pro ponto original em vez de sumir no ar.
func _project_to_ground(pos: Vector3, exclude_rids: Array[RID] = []) -> Vector3:
	var space_state = spawn_container.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 3.0, pos - Vector3.UP * 50.0)

	# Ignora TODA entidade no caminho do raio, senão ele para no próprio corpo de quem
	# chamou (o player tem a origem no meio da cápsula, então a poça saía na altura da
	# cabeça em vez de no chão) ou em cima de um inimigo que estivesse embaixo.
	var excludes: Array[RID] = exclude_rids.duplicate()
	for group in ["Players", "Enemies", "Targets"]:
		for body in get_tree().get_nodes_in_group(group):
			if body is CollisionObject3D:
				excludes.append(body.get_rid())
	query.exclude = excludes

	var result = space_state.intersect_ray(query)
	return result.position if result else pos


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


const DAMAGE_NUMBER = preload("res://Scenes/Effects/damage_number.tscn")

# Cor do número de dano por "quem levou": vermelho quando é o próprio player, amarelo
# pálido quando é inimigo/alvo — ajuda a distinguir dano recebido de dano causado.
const DAMAGE_NUMBER_PLAYER_TINT := Color(1.0, 0.25, 0.2)
const DAMAGE_NUMBER_ENEMY_TINT := Color(1.0, 0.92, 0.55)
const HEAL_NUMBER_TINT := Color(0.3, 1.0, 0.45)  # cura das habilidades de água


# Chamado por qualquer peer via rpc_id(1, ...); só o servidor (autoridade do Global)
# de fato instancia — daí o spawn_container.add_child replica pra todo mundo, porque
# damage_number.tscn está em _spawnable_scenes do MultiplayerSpawner (mesmo esquema do
# rock_sling/rock_decal/explosion).
@rpc("any_peer", "call_local")
func spawn_damage_number(pos: Vector3, amount: int, tint: Color = DAMAGE_NUMBER_ENEMY_TINT) -> void:
	if not is_multiplayer_authority():
		return

	var number = DAMAGE_NUMBER.instantiate()
	number.amount = amount
	number.tint = tint
	# add_child ANTES de mexer em global_position: fora da árvore, get_global_transform()
	# falha com "!is_inside_tree()" (mesma ordem usada por todo outro spawn nesse arquivo).
	spawn_container.add_child(number, true)
	number.global_position = pos


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

			var velocity = dir * (ROCK_SLING_LAUNCH_SPEED * charge_power)
			velocity.y += ROCK_SLING_LAUNCH_SPEED * charge_power
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

		"water_pellet":
			var pellet_scene = preload("res://Scenes/Effects/water_pellet.tscn")
			var pellet = pellet_scene.instantiate()

			spawn_container.add_child(pellet, true)

			pellet.owner_peer_id = multiplayer.get_remote_sender_id()
			pellet.element = ElementsEnum.Element.WATER
			pellet.tag = "projectile"

			var horizontal_dir = Vector3(dir.x, 0, dir.z)
			horizontal_dir = horizontal_dir.normalized() if horizontal_dir.length() > 0.001 else Vector3.FORWARD

			var jitter = Vector3(randf_range(-0.25, 0.25), randf_range(-0.15, 0.2), randf_range(-0.25, 0.25))
			pellet.global_position = pos + Vector3(0, 1.6, 0) + horizontal_dir * 1.6 + jitter

			var pellet_velocity = dir * 30.0
			pellet_velocity.y += 1.5
			pellet.linear_velocity = pellet_velocity

		"jet_stream":
			var jet_scene = preload("res://Scenes/Effects/jet_stream.tscn")
			var jet = jet_scene.instantiate()

			spawn_container.add_child(jet, true)
			jet.owner_peer_id = multiplayer.get_remote_sender_id()

			var aim_dir = dir.normalized() if dir.length() > 0.001 else Vector3.FORWARD
			jet.setup(pos + Vector3(0, 1.4, 0) + aim_dir * 1.0, aim_dir)

		"puddle_punch":
			# "dir" aqui é reaproveitado como a normal da superfície mirada (ver Player._release_puddle_punch)
			_puddle_punch(pos, dir)

		"water_bomb":
			var bomb_scene = preload("res://Scenes/Effects/water_bomb.tscn")
			var bomb = bomb_scene.instantiate()

			spawn_container.add_child(bomb, true)
			bomb.owner_peer_id = multiplayer.get_remote_sender_id()

			var horizontal_dir = Vector3(dir.x, 0, dir.z)
			horizontal_dir = horizontal_dir.normalized() if horizontal_dir.length() > 0.001 else Vector3.FORWARD

			bomb.global_position = pos + Vector3(0, 1.6, 0) + horizontal_dir * 1.5

			var bomb_velocity = dir * 16.0
			bomb_velocity.y += 9.0
			bomb.linear_velocity = bomb_velocity

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

	var caster_peer_id := multiplayer.get_remote_sender_id()

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

			# Rouba a autoria de projétil inimigo: a partir daqui ele fere inimigos, não players.
			if "redirected_by_peer_id" in node:
				node.redirected_by_peer_id = caster_peer_id

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


# Water Q: spawna a poça no ponto mirado (já validado e limitado em alcance pelo
# Player, ver PUDDLE_PUNCH_RANGE), orientada pela normal da superfície — copia o
# mesmo truque do decal do rock_sling (Basis(Quaternion(UP, normal))).
func _puddle_punch(pos: Vector3, normal: Vector3) -> void:
	var puddle_scene = preload("res://Scenes/Effects/puddle_punch.tscn")
	var puddle = puddle_scene.instantiate()

	var up = normal.normalized() if normal.length() > 0.01 else Vector3.UP
	var puddle_basis = Basis(Quaternion(Vector3.UP, up))
	puddle.transform = Transform3D(puddle_basis, pos + up * 0.03)
	puddle.owner_peer_id = multiplayer.get_remote_sender_id()

	spawn_container.add_child(puddle, true)


# Water Shift: poça deixada no rastro do dash (ver Player._physics_process, is_water_dashing).
@rpc("any_peer", "call_local")
func spawn_water_puddle(pos: Vector3) -> void:
	if not is_multiplayer_authority():
		return

	var decal_scene = preload("res://Scenes/Effects/water_puddle.tscn")
	var decal = decal_scene.instantiate()
	spawn_container.add_child(decal, true)
	decal.global_position = _project_to_ground(pos)


# Water E: chamada pelo WaterBomb ao pousar — chove no local do impacto por alguns segundos.
@rpc("any_peer", "call_local")
func spawn_rain_zone(pos: Vector3) -> void:
	if not is_multiplayer_authority():
		return

	var rain_scene = preload("res://Scenes/Effects/rain_zone.tscn")
	var rain = rain_scene.instantiate()
	spawn_container.add_child(rain, true)
	rain.global_position = _project_to_ground(pos)


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
	decal.scale = Vector3.ONE * rock_scale_factor(ROCK_MAX_CHARGE_POWER)
	decal.element = 2  # EARTH
	spawn_container.add_child(decal, true)
	decal.global_position = _project_to_ground(pos)


@rpc("any_peer", "call_local")
func spawn_boulder_decal(pos: Vector3, infused_with: int = -1, decal_scale: float = 1.0) -> void:
	if not is_multiplayer_authority():
		return

	var decal_scene = preload("res://Scenes/Effects/rock_decal.tscn")
	var decal = decal_scene.instantiate()
	decal.scale = Vector3.ONE * decal_scale
	decal.element = 2  # EARTH
	decal.infused_with = infused_with
	spawn_container.add_child(decal, true)
	decal.global_position = _project_to_ground(pos)
