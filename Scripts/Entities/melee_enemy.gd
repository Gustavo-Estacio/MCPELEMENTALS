extends CharacterBody3D

@export var health := 40
@export var speed := 3.5
@export var attack_range := 2.2  # alcance horizontal (circular, à frente do inimigo)
@export var attack_vertical_range := 2.0  # dano melee não é global: precisa estar perto na altura também
@export var attack_damage := 200
@export var attack_cooldown := 1.5

@onready var attack_timer: Timer = $AttackTimer
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var can_attack := true
var is_dead := false
var _knockback_timer := 0.0

const KNOCKBACK_DURATION := 0.35

func _ready() -> void:
	add_to_group('Enemies')
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(func(): can_attack = true)


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority() or is_dead:
		return

	if _knockback_timer > 0.0:
		_knockback_timer -= delta
		if not is_on_floor():
			velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	var target := _closest_player()
	if not target:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	var to_target = target.global_position - global_position
	var vertical_dist = absf(to_target.y)
	to_target.y = 0
	var dist = to_target.length()

	if dist > 0.01:
		look_at(global_position + to_target, Vector3.UP)

	# Alcance circular na horizontal, à frente do inimigo (ele já vira pra encarar o alvo
	# acima) — mas NUNCA atinge alguém muito acima/abaixo só por estar embaixo/em cima,
	# senão o soco vira um alcance global na vertical (ex: acertar quem tá numa plataforma
	# alta só por estar logo abaixo dela).
	var in_melee_range = dist <= attack_range and vertical_dist <= attack_vertical_range

	if not in_melee_range:
		var dir = to_target.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = 0
		velocity.z = 0
		if can_attack:
			_attack(target)

	move_and_slide()


func _attack(target: Player) -> void:
	can_attack = false
	attack_timer.start()
	target.take_damage(attack_damage, -1)


func _closest_player() -> Player:
	var closest: Player
	var closest_dist := INF
	for p in get_tree().get_nodes_in_group('Players'):
		var d = global_position.distance_to(p.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = p
	return closest


func take_damage(damage: int, source: int, _element: int = -1):
	var next_health = health - damage
	Global.spawn_damage_number.rpc_id(1, global_position + Vector3(0, 1.4, 0), damage,
		Global.DAMAGE_NUMBER_ENEMY_TINT)

	var player_to_notify: Player
	for current_player in get_tree().get_nodes_in_group('Players'):
		if current_player.name == str(source):
			player_to_notify = current_player
			break

	if not player_to_notify:
		return

	if next_health <= 0:
		_die.rpc()
		player_to_notify.register_hit.rpc_id(source, true)
	else:
		health = next_health
		player_to_notify.register_hit.rpc_id(source)


# Ragdoll simples (tomba e cai) + dissolve, ver enemy_death.gd. Chamado via RPC (em vez
# de queue_free() direto) pra todo peer rodar o dissolve local — só quem matou executaria
# senão, já que take_damage só roda em quem tem autoridade sobre o ataque.
@rpc("any_peer", "call_local")
func _die() -> void:
	if is_dead:
		return
	is_dead = true
	remove_from_group('Enemies')
	EnemyDeath.start(self, mesh_instance)


# Empurrão vindo de habilidades (ex: Puddle Punch). Enquanto o timer corre, a IA não
# sobrescreve a velocidade — senão o inimigo "gruda" no chão e o knockback não aparece.
@rpc("any_peer", "call_local")
func apply_knockback(dir: Vector3, force: float) -> void:
	velocity = dir.normalized() * force
	_knockback_timer = KNOCKBACK_DURATION
