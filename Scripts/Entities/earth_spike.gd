extends Area3D

class_name EarthSpike

@export var ERUPT_DURATION := 0.15
@export var LIFETIME := 3.0
@export var DAMAGE := 15

var element: int = 2  # ElementsEnum.Element.EARTH
var tag: String = "projectile"
var owner_peer_id: int = -1

@onready var mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	scale.y = 0.05

	if is_multiplayer_authority():
		_erupt()


func _erupt() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale:y", 1.0, ERUPT_DURATION)

	await get_tree().create_timer(LIFETIME).timeout
	if is_instance_valid(self):
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return

	if body.has_method('take_damage'):
		body.take_damage(DAMAGE, owner_peer_id, element)
