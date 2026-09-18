extends RigidBody3D

class_name JetStream

@export var SPEED := 28.0
@export var LIFETIME := 1.2
@export var DAMAGE := 18
@export var HEAL := 18  # em player, agua cura em vez de machucar
@export var PUSH_STRENGTH := 16.0  # empurrão único somado ao vetor de movimento de habilidades "moveable"

var element: int = ElementsEnum.Element.WATER
var tag: String = "projectile"
var owner_peer_id: int = -1

var forward_dir := Vector3.FORWARD
var _already_hit: Array = []  # cada corpo só recebe dano/empurrão 1 vez por jato

@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var area_3d: Area3D = $Area3D


func setup(spawn_pos: Vector3, direction: Vector3) -> void:
	forward_dir = direction.normalized() if direction.length() > 0.01 else Vector3.FORWARD
	global_position = spawn_pos
	look_at(global_position + forward_dir, Vector3.UP)
	linear_velocity = forward_dir * SPEED


func _ready() -> void:
	area_3d.body_entered.connect(_on_body_entered)
	area_3d.area_entered.connect(_on_area_entered)
	particles.restart()

	if is_multiplayer_authority():
		get_tree().create_timer(LIFETIME).timeout.connect(func():
			if is_instance_valid(self):
				queue_free()
		)


func _on_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority() or _already_hit.has(body):
		return

	_already_hit.append(body)

	# Agua cura player e machuca inimigo (ver Player.heal)
	if body.is_in_group('Players') and body.has_method('heal'):
		body.heal(HEAL)
	elif body.has_method('take_damage'):
		body.take_damage(DAMAGE, owner_peer_id, element)


func _on_area_entered(other: Area3D) -> void:
	if not is_multiplayer_authority():
		return

	var body = other.owner
	if body and body is RigidBody3D and "is_moveable" in body and body.is_moveable and not _already_hit.has(body):
		_already_hit.append(body)
		body.linear_velocity += forward_dir * PUSH_STRENGTH
