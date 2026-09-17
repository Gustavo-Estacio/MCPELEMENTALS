extends Area3D

class_name WaterPuddle

var element: int = ElementsEnum.Element.WATER
var tag: String = "decal"

@export var LIFETIME := 4.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0

	var tween = create_tween()
	tween.tween_interval(LIFETIME * 0.6)
	tween.tween_property(self, "scale", Vector3.ZERO, LIFETIME * 0.4)
	tween.tween_callback(func():
		if is_instance_valid(self):
			queue_free()
	)
