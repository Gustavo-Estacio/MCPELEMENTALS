extends Node

## Autoload: estado global da partida e a "fábrica" de habilidades.
##
## Mapa do arquivo:
##   1. ESTADO E CENAS ....... referências do mundo e PackedScenes usadas aqui
##   2. HELPERS .............. direções, spawn de partículas temporárias
##   3. TABELA DE CASTS ...... nome da habilidade -> função que a cria
##   4. CASTS POR ELEMENTO ... uma função por habilidade (terra, fogo, ar)
##   5. DANO EM ÁREA ......... AoE de fogo e o "aparar" do ar
##   6. DECALS ............... marcas de impacto no chão


# =============================================================================
# === 1. ESTADO E CENAS
# =============================================================================

var username := ''

var world: Node3D
var spawn_container: Node3D

const ROCK_MAX_CHARGE_POWER := 2.5

const BALL := preload("uid://be342wrf0687")
const ROCK_SLING_SCENE := preload("res://Scenes/Effects/rock_sling.tscn")
const FIREBALL_SCENE := preload("res://Scenes/Effects/fireball.tscn")
const EARTH_SPIKE_SCENE := preload("res://Scenes/Effects/earth_spike.tscn")
const AIR_SLASH_SCENE := preload("res://Scenes/Effects/air_slash.tscn")
const TORNADO_SCENE := preload("res://Scenes/Effects/tornado.tscn")
const WIND_TORRENT_SCENE := preload("res://Scenes/Effects/wind_torrent.tscn")
const WIND_PARTICLES_SCENE := preload("res://Scenes/Effects/wind_particles.tscn")
const FIRE_PARTICLES_SCENE := preload("res://Scenes/Effects/fire_particles.tscn")
const EXPLOSION_SCENE := preload("res://Scenes/Effects/explosion.tscn")
const ROCK_DECAL_SCENE := preload("res://Scenes/Effects/rock_decal.tscn")

# Nome da habilidade -> função que a cria. Preenchida em _ready (ver seção 3).
var _ability_casts := {}


func _ready() -> void:
	# ReactionDatabase é um autoload (configurado no project.godot), não precisa criar aqui.
	_build_ability_table()


# =============================================================================
# === 2. HELPERS
# =============================================================================

# Direção da mira achatada no plano do chão — usada em quase todo spawn pra não
# mirar o ponto de nascimento pro chão/céu.
func _flat_dir(dir: Vector3) -> Vector3:
	var horizontal_dir := Vector3(dir.x, 0, dir.z)
	return horizontal_dir.normalized() if horizontal_dir.length() > 0.001 else Vector3.FORWARD


# Direção da mira completa (inclui cima/baixo), pros efeitos guiados pela câmera.
func _aim_dir(dir: Vector3) -> Vector3:
	return dir.normalized() if dir.length() > 0.001 else Vector3.FORWARD


# Efeito de partículas solto no mundo, que se apaga sozinho quando termina.
func _spawn_temp_particles(scene: PackedScene, pos: Vector3, particles_scale := 1.0) -> void:
	var particles_instance = scene.instantiate()
	particles_instance.position = pos
	if particles_scale != 1.0:
		particles_instance.scale = Vector3.ONE * particles_scale
	spawn_container.add_child(particles_instance, true)
	particles_instance.restart()

	var timer = spawn_container.get_tree().create_timer(particles_instance.lifetime * 1.2)
	timer.timeout.connect(func():
		if is_instance_valid(particles_instance):
			particles_instance.queue_free()
	)


func rock_scale_factor(charge_power: float) -> float:
	return 1.0 + (charge_power - 1.0) * 9.0


@rpc("any_peer", "call_local")
func shoot_ball(pos, dir, force):
	var new_ball: RigidBody3D = BALL.instantiate()
	new_ball.source = multiplayer.get_remote_sender_id()
	new_ball.position = pos + Vector3(0.0, 1.0, 0.0) + (dir * 2.0)
	spawn_container.add_child(new_ball, true)
	new_ball.apply_central_impulse(dir * force)


# =============================================================================
# === 3. TABELA DE CASTS
# =============================================================================
#
# O Player só manda o NOME da habilidade; quem sabe construir cada uma é a tabela
# abaixo. Adicionar uma habilidade = escrever a função e registrar aqui — nada de
# aumentar um match gigante.
#
# Toda função de cast recebe (pos, dir, charge_power); quem não usa o charge ignora.

func _build_ability_table() -> void:
	_ability_casts = {
		# Terra
		"rock_sling": _cast_rock_sling,
		"rock_barrage_small": _cast_rock_barrage_small,
		"rock_barrage_big": _cast_rock_barrage_big,
		"earth_spike": _cast_earth_spike,
		# Fogo
		"fireball": _cast_fireball,
		"flame_tick": _cast_flame_tick,
		"fire_cone": _cast_fire_cone,
		"fire_blast": _cast_fire_blast,
		# Ar
		"air_slash": _cast_air_slash,
		"slash_of_air": _cast_slash_of_air,
		"tornado": _cast_tornado,
		"wind_torrent": _cast_wind_torrent,
		"air_dash_burst": _cast_air_dash_burst,
	}


@rpc("any_peer", "call_local")
func cast_ability(ability_type: String, pos: Vector3, dir: Vector3, charge_power: float = 1.0) -> void:
	if not is_multiplayer_authority():
		return

	var cast: Callable = _ability_casts.get(ability_type, Callable())
	if not cast.is_valid():
		push_warning("cast_ability: habilidade desconhecida '%s'" % ability_type)
		return

	cast.call(pos, dir, charge_power)


# =============================================================================
# === 4. CASTS POR ELEMENTO
# =============================================================================

# --- TERRA -------------------------------------------------------------------

func _cast_rock_sling(pos: Vector3, dir: Vector3, charge_power: float) -> void:
	var rock = ROCK_SLING_SCENE.instantiate()
	spawn_container.add_child(rock, true)

	rock.owner_peer_id = multiplayer.get_remote_sender_id()
	rock.element = ElementsEnum.Element.EARTH
	rock.tag = "projectile"
	rock.charge_power = charge_power

	# Escala do rock proporcional ao charge (1x a 10x)
	var scale_factor = rock_scale_factor(charge_power)
	rock.scale = Vector3.ONE * scale_factor

	# Quanto maior a pedra, mais alto ela precisa spawnar pra não nascer dentro do chão
	# (a área de detecção também escala com o rock, então o offset acompanha o raio dela: 0.5 * scale_factor)
	var spawn_height = 0.5 * scale_factor + 0.5
	rock.global_position = pos + Vector3(0, spawn_height, 0) + _flat_dir(dir) * (1.5 * charge_power)

	var velocity = dir * (10.0 * charge_power / 3.0)
	velocity.y += (10.0 * charge_power) / 3.0
	rock.linear_velocity = velocity


func _cast_rock_barrage_small(pos: Vector3, dir: Vector3, _charge_power: float) -> void:
	_spawn_earth_rock(pos, dir, 0.6, 1.0, 20.0, 2.0, 1.0)


func _cast_rock_barrage_big(pos: Vector3, dir: Vector3, _charge_power: float) -> void:
	_spawn_earth_rock(pos, dir, 4.0, 2.0, 14.0, 3.0, 2.0)


# Pedra de terra não-carregável (sem hold), usada pelo LMB/RMB. Nunca é ignitável.
func _spawn_earth_rock(pos: Vector3, dir: Vector3, scale_factor: float, damage_charge: float, speed: float, vertical_boost: float, forward_offset: float) -> void:
	var rock = ROCK_SLING_SCENE.instantiate()
	spawn_container.add_child(rock, true)

	rock.owner_peer_id = multiplayer.get_remote_sender_id()
	rock.element = ElementsEnum.Element.EARTH
	rock.tag = "projectile"
	rock.charge_power = damage_charge
	rock.ignitable = false
	rock.scale = Vector3.ONE * scale_factor

	var spawn_height = 0.5 * scale_factor + 0.5
	rock.global_position = pos + Vector3(0, spawn_height, 0) + _flat_dir(dir) * forward_offset

	var velocity = dir * speed
	velocity.y += vertical_boost
	rock.linear_velocity = velocity


# O charge_power é reaproveitado aqui como o ÍNDICE do espinho na fila (0, 1, 2...),
# que é o que espaça um do outro.
func _cast_earth_spike(pos: Vector3, dir: Vector3, queue_index: float) -> void:
	const SPIKE_SPACING := 1.1

	var spike = EARTH_SPIKE_SCENE.instantiate()
	spawn_container.add_child(spike, true)
	spike.owner_peer_id = multiplayer.get_remote_sender_id()

	var target_pos = pos + _flat_dir(dir) * (SPIKE_SPACING * (queue_index + 1.0))

	# Raycast pra encontrar o chão nesse ponto da fila
	var space_state = spawn_container.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		target_pos + Vector3.UP * 10.0,
		target_pos - Vector3.UP * 10.0
	)
	var result = space_state.intersect_ray(query)
	spike.global_position = result.position if result else target_pos


# --- FOGO --------------------------------------------------------------------

func _cast_fireball(pos: Vector3, dir: Vector3, charge_power: float) -> void:
	var fireball = FIREBALL_SCENE.instantiate()
	spawn_container.add_child(fireball, true)

	fireball.owner_peer_id = multiplayer.get_remote_sender_id()
	fireball.element = ElementsEnum.Element.FIRE
	fireball.tag = "projectile"
	fireball.charge_power = charge_power

	# Fireball usa o material próprio da cena (sem shader de lava)
	fireball.global_position = pos + Vector3(0, 1.8, 0) + _flat_dir(dir) * 2.0

	var velocity = dir * 25.0 * charge_power
	velocity.y += 5.0
	fireball.linear_velocity = velocity


func _cast_flame_tick(pos: Vector3, dir: Vector3, _charge_power: float) -> void:
	_fire_aoe(pos, dir, 2.5, 1.2, 8, false)


func _cast_fire_cone(pos: Vector3, dir: Vector3, _charge_power: float) -> void:
	_fire_aoe(pos, dir, 3.0, 2.0, 25, true)


func _cast_fire_blast(pos: Vector3, dir: Vector3, _charge_power: float) -> void:
	_fire_aoe(pos, dir, 0.0, 3.5, 35, true)


# --- AR ----------------------------------------------------------------------

func _cast_air_slash(pos: Vector3, dir: Vector3, _charge_power: float) -> void:
	var slash = AIR_SLASH_SCENE.instantiate()
	spawn_container.add_child(slash, true)
	slash.owner_peer_id = multiplayer.get_remote_sender_id()

	var aim_dir = _aim_dir(dir)

	# Sai de trás do jogador, cortando pra frente, guiado pela câmera (pra cima/baixo também)
	slash.global_position = pos + Vector3(0, 1.2, 0) - _flat_dir(dir) * 1.0
	slash.look_at(slash.global_position + aim_dir, Vector3.UP)
	slash.linear_velocity = aim_dir * 22.0


func _cast_slash_of_air(pos: Vector3, dir: Vector3, _charge_power: float) -> void:
	_deflect_projectiles(pos, dir)


func _cast_tornado(pos: Vector3, dir: Vector3, _charge_power: float) -> void:
	var tornado = TORNADO_SCENE.instantiate()
	spawn_container.add_child(tornado, true)
	tornado.owner_peer_id = multiplayer.get_remote_sender_id()

	var horizontal_dir = _flat_dir(dir)
	tornado.setup(pos + horizontal_dir * 0.6, horizontal_dir)


func _cast_wind_torrent(pos: Vector3, dir: Vector3, _charge_power: float) -> void:
	var torrent = WIND_TORRENT_SCENE.instantiate()
	spawn_container.add_child(torrent, true)
	torrent.owner_peer_id = multiplayer.get_remote_sender_id()

	var aim_dir = _aim_dir(dir)
	torrent.setup(pos + Vector3(0, 1.2, 0) + aim_dir * 0.8, aim_dir)


func _cast_air_dash_burst(pos: Vector3, _dir: Vector3, _charge_power: float) -> void:
	_spawn_temp_particles(WIND_PARTICLES_SCENE, pos)


# =============================================================================
# === 5. DANO EM ÁREA
# =============================================================================

# Dano em área de fogo (usado por flamethrower, cone e fire blast) + visual.
func _fire_aoe(pos: Vector3, dir: Vector3, distance: float, radius: float, damage: int, big_visual: bool) -> void:
	var center = pos + Vector3(0, 1.0, 0) + _flat_dir(dir) * distance
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
			body.take_damage(damage, caster_peer_id, ElementsEnum.Element.FIRE)

	if big_visual:
		var explosion = EXPLOSION_SCENE.instantiate()
		explosion.position = center
		explosion.scale = Vector3.ONE * (radius / 1.5)
		spawn_container.add_child(explosion, true)
	else:
		_spawn_temp_particles(FIRE_PARTICLES_SCENE, center, radius)


# RMB do Air: cone na frente do jogador que "apara" projéteis móveis, zerando o momentum deles
# (eles caem só com a gravidade a partir daí).
func _deflect_projectiles(pos: Vector3, dir: Vector3) -> void:
	const DEFLECT_RANGE := 4.0
	const DEFLECT_HALF_ANGLE_DEG := 45.0

	var horizontal_dir = _flat_dir(dir)
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

	_spawn_temp_particles(WIND_PARTICLES_SCENE, caster_pos + horizontal_dir * 2.0)


# =============================================================================
# === 6. DECALS
# =============================================================================

@rpc("any_peer", "call_local")
func spawn_earth_leap_decal(pos: Vector3) -> void:
	if not is_multiplayer_authority():
		return

	_spawn_rock_decal(pos, rock_scale_factor(ROCK_MAX_CHARGE_POWER))


@rpc("any_peer", "call_local")
func spawn_boulder_decal(pos: Vector3, infused_with: int = -1, decal_scale: float = 1.0) -> void:
	if not is_multiplayer_authority():
		return

	_spawn_rock_decal(pos, decal_scale, infused_with)


func _spawn_rock_decal(pos: Vector3, decal_scale: float, infused_with: int = -1) -> void:
	var decal = ROCK_DECAL_SCENE.instantiate()
	decal.position = pos
	decal.scale = Vector3.ONE * decal_scale
	decal.element = ElementsEnum.Element.EARTH
	decal.infused_with = infused_with
	spawn_container.add_child(decal, true)
