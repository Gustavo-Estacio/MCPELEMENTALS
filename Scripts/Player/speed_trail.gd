extends MeshInstance3D

class_name SpeedTrail

@export var MAX_AGE := 0.4
@export var SAMPLE_INTERVAL := 0.03
@export var TRAIL_COLOR := Color(0.6, 0.85, 1.0, 0.5)  # azulzinho claro, 50% opacidade

var emitting := false:
	set(value):
		emitting = value
		if not value:
			_points.clear()

var _points: Array = []  # {pos: Vector3, age: float}
var _sample_timer := 0.0


func _ready() -> void:
	mesh = ImmediateMesh.new()

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = material


func _process(delta: float) -> void:
	if emitting:
		_sample_timer += delta
		if _sample_timer >= SAMPLE_INTERVAL:
			_sample_timer = 0.0
			_points.append({"pos": global_position, "age": 0.0})

	for point in _points:
		point.age += delta
	_points = _points.filter(func(p): return p.age < MAX_AGE)

	_rebuild_mesh()


func _rebuild_mesh() -> void:
	var immediate := mesh as ImmediateMesh
	immediate.clear_surfaces()

	if _points.size() < 2:
		return

	immediate.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in _points:
		var alpha = TRAIL_COLOR.a * (1.0 - point.age / MAX_AGE)
		immediate.surface_set_color(Color(TRAIL_COLOR.r, TRAIL_COLOR.g, TRAIL_COLOR.b, alpha))
		immediate.surface_add_vertex(to_local(point.pos))
	immediate.surface_end()
