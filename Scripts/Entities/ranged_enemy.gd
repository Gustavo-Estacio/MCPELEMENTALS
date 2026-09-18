extends CharacterBody3D

@export var health := 30
@export var speed := 3.0
@export var fire_range := 15.0
@export var preferred_distance := 9.0  # mantém essa distância do alvo (persegue se longe, recua se perto)
@export var retreat_margin := 2.0

@onready var fire_timer: Timer = $FireTimer

const ENEMY_PROJECTILE = preload("res://Scenes/Entities/enemy_projectile.tscn")

func _ready() -> void:
	add_to_group('Enemies')
	fire_timer.timeout.connect(_try_fire)


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
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
	to_target.y = 0
	var dist = to_target.length()

	if dist > 0.01:
		look_at(global_position + to_target, Vector3.UP)

	if dist > preferred_distance:
		var dir = to_target.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	elif dist < preferred_distance - retreat_margin:
		var dir = -to_target.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()


func _try_fire() -> void:
	if not is_multiplayer_authority():
		return

	var target := _closest_player()
	if not target:
		return

	if global_position.distance_to(target.global_position) > fire_range:
		return

	var origin = global_position + Vector3(0, 1.0, 0)
	var dir = (target.global_position + Vector3(0, 1.0, 0) - origin).normalized()

	var projectile = ENEMY_PROJECTILE.instantiate()
	projectile.position = origin + dir * 0.6
	Global.spawn_container.add_child(projectile, true)
	projectile.linear_velocity = dir * 15.0


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
		queue_free()
		player_to_notify.register_hit.rpc_id(source, true)
	else:
		health = next_health
		player_to_notify.register_hit.rpc_id(source)
