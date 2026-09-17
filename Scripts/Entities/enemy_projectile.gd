extends RigidBody3D

var is_moveable := true  # habilidades físicas que o Wind Torrent do Air consegue empurrar/redirecionar

@onready var area_3d: Area3D = $Area3D
@onready var lifetime: Timer = $Lifetime

func _ready() -> void:
	area_3d.body_entered.connect(_on_hit)
	lifetime.timeout.connect(queue_free)


func _on_hit(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return

	if body.is_in_group('Players') and body.has_method('take_damage'):
		body.take_damage(1, -1)

	queue_free()
