extends StaticBody3D

@export var health := 100

func _ready():
	add_to_group('Targets')

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
