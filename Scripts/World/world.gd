extends Node3D

@onready var spawn_container: Node3D = $SpawnContainer
@onready var timer_target: Timer = $TimerTarget
@onready var timer_enemy: Timer = $TimerEnemy
const TARGET = preload("uid://wj1j5cg0flnj")
const RANGED_ENEMY = preload("res://Scenes/Entities/ranged_enemy.tscn")
const MELEE_ENEMY = preload("res://Scenes/Entities/melee_enemy.tscn")

# Spawn de inimigos: 1 por segundo, até o limite de vivos na cena
const ENEMY_SPAWN_INTERVAL := 1.0
const MAX_ENEMIES := 80

var enemy_spawn_active := false

func _ready() -> void:
	Global.world = self
	Global.spawn_container = spawn_container
	timer_target.timeout.connect(spawn_target)
	timer_enemy.timeout.connect(spawn_enemy)
	timer_enemy.wait_time = ENEMY_SPAWN_INTERVAL


func spawn_target():
	if is_multiplayer_authority() and get_tree().get_node_count_in_group('Targets') < 16:
		var new_target = TARGET.instantiate()
		var rand_x = randf_range(-40.0, 40.0)
		var rand_z = randf_range(-40.0, 40.0)

		new_target.position = Vector3(rand_x, 1, rand_z)
		spawn_container.add_child(new_target, true)


@rpc("any_peer", "call_local")
func toggle_enemy_spawn() -> void:
	if not is_multiplayer_authority():
		return

	enemy_spawn_active = not enemy_spawn_active
	if enemy_spawn_active:
		timer_enemy.start()
	else:
		timer_enemy.stop()


func spawn_enemy():
	if not is_multiplayer_authority() or get_tree().get_node_count_in_group('Enemies') >= MAX_ENEMIES:
		return

	var enemy_scene = RANGED_ENEMY if randf() < 0.5 else MELEE_ENEMY
	var new_enemy = enemy_scene.instantiate()
	var rand_x = randf_range(-40.0, 40.0)
	var rand_z = randf_range(-40.0, 40.0)

	new_enemy.position = Vector3(rand_x, 1, rand_z)
	spawn_container.add_child(new_enemy, true)
