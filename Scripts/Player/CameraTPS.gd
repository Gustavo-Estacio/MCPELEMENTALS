extends Node3D

class_name CameraTPS

@export var shoulder_distance: float = 2.8
@export var shoulder_height: float = 0.6
@export var shoulder_side: float = 0.8
@export var fov_default: float = 75.0
@export var fov_aimed: float = 50.0
@export var pitch_min: float = -80.0
@export var pitch_max: float = 80.0
@export var mouse_sensitivity: float = 0.002

@onready var camera: Camera3D = $Camera3D
@onready var raycast: RayCast3D = $RayCast3D

var player: CharacterBody3D
var pitch: float = 0.0
var yaw: float = 0.0
var is_aiming: bool = false
var current_fov: float

func _ready() -> void:
	player = get_parent()
	current_fov = fov_default
	camera.fov = current_fov

	# Raycast setup
	if not raycast:
		raycast = RayCast3D.new()
		add_child(raycast)
	raycast.add_exception(player)

func _unhandled_input(event: InputEvent) -> void:
	if not player.is_multiplayer_authority():
		return

	if event is InputEventMouseMotion:
		# Yaw: rotaciona o corpo inteiro (horizontal)
		yaw -= event.relative.x * mouse_sensitivity
		player.rotation.y = yaw

		# Pitch: rotaciona só a câmera (vertical)
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))

	# Aim toggle (Right Mouse Button)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_aiming = event.pressed

func _process(_delta: float) -> void:
	if not player.is_multiplayer_authority():
		return

	# Update camera position (over the shoulder)
	var local_offset = Vector3(shoulder_side, shoulder_height, -shoulder_distance)
	var world_offset = player.global_transform.basis * local_offset
	global_position = player.global_position + world_offset

	# Apply pitch to camera
	camera.rotation.x = pitch

	# FOV smooth transition
	var target_fov = fov_aimed if is_aiming else fov_default
	current_fov = lerp(current_fov, target_fov, 0.15)
	camera.fov = current_fov

	# Raycast for aim
	raycast.target_position = Vector3(0, 0, -1000)
	raycast.force_raycast_update()

func get_raycast_point() -> Vector3:
	if raycast.is_colliding():
		return raycast.get_collision_point()
	return camera.global_position + camera.global_transform.basis.z * 1000.0

func get_aim_direction() -> Vector3:
	return (get_raycast_point() - camera.global_position).normalized()
