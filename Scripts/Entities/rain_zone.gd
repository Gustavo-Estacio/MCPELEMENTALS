extends Node3D

class_name RainZone

@export var DURATION := 3.0
# Chuva de água: cura quem está embaixo dela de tempos em tempos (ver Player.heal).
@export var HEAL_PER_TICK := 30  # 3x
@export var HEAL_INTERVAL := 0.5
@export var HEAL_RADIUS := 3.0  # bate com emission_box_extents das partículas na cena

@onready var rain_particles: GPUParticles3D = $RainParticles
@onready var splash_particles: GPUParticles3D = $SplashParticles

var _heal_timer := 0.0


func _ready() -> void:
	rain_particles.emitting = true
	splash_particles.restart()

	await get_tree().create_timer(DURATION).timeout
	if is_instance_valid(self):
		queue_free()


func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	_heal_timer += delta
	if _heal_timer < HEAL_INTERVAL:
		return
	_heal_timer = 0.0

	for player in get_tree().get_nodes_in_group('Players'):
		if not is_instance_valid(player) or not player.has_method('heal'):
			continue
		var to_player = player.global_position - global_position
		if Vector2(to_player.x, to_player.z).length() <= HEAL_RADIUS:
			player.heal(HEAL_PER_TICK)
