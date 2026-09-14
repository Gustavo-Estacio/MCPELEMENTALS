extends Node3D

class_name Explosion

@export var SHAKE_RADIUS := 15.0
@export var MAX_SHAKE_TRAUMA := 0.5

@onready var fire_burst: GPUParticles3D = $FireBurst
@onready var smoke: GPUParticles3D = $Smoke


func _ready() -> void:
	fire_burst.restart()
	smoke.restart()

	if is_multiplayer_authority():
		_shake_nearby_players()

	var longest_lifetime = max(fire_burst.lifetime, smoke.lifetime)
	await get_tree().create_timer(longest_lifetime * 1.2).timeout
	queue_free()


func _shake_nearby_players() -> void:
	for player in get_tree().get_nodes_in_group('Players'):
		var distance = global_position.distance_to(player.global_position)
		if distance > SHAKE_RADIUS:
			continue

		var trauma = MAX_SHAKE_TRAUMA * (1.0 - distance / SHAKE_RADIUS)
		player.trigger_camera_shake.rpc_id(int(player.name), trauma)
