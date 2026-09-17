extends AnimatableBody3D

@export var move_offset: Vector3 = Vector3(0, 0, 8)
@export var duration: float = 3.0

var _start: Vector3
var _time: float = 0.0

func _ready() -> void:
	_start = position

func _physics_process(delta: float) -> void:
	_time += delta
	var t := (sin((_time / duration) * TAU - PI / 2.0) + 1.0) / 2.0
	position = _start.lerp(_start + move_offset, t)
