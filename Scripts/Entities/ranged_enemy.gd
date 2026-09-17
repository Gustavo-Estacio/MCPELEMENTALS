extends StaticBody3D

@export var health := 30
@export var fire_range := 15.0

@onready var fire_timer: Timer = $FireTimer

const ENEMY_PROJECTILE = preload("res://Scenes/Entities/enemy_projectile.tscn")

func _ready() -> void:
	add_to_group('Enemies')
	fire_timer.timeout.connect(_try_fire)


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
