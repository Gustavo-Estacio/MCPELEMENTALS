extends Node3D

class_name RainZone

@export var DURATION := 3.0

@onready var rain_particles: GPUParticles3D = $RainParticles
@onready var splash_particles: GPUParticles3D = $SplashParticles


func _ready() -> void:
	rain_particles.emitting = true
	splash_particles.restart()

	await get_tree().create_timer(DURATION).timeout
	if is_instance_valid(self):
		queue_free()
