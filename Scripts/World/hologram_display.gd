extends Node3D

class_name HologramDisplay

## Vitrine de holograma: aplica o shader de holograma em todo MeshInstance3D abaixo dele
## e gira devagar. Só decoração — sem colisão, sem física, sem lógica de jogo.

@export var primary_color := Color(0.25, 0.75, 1.0)
@export var secondary_color := Color(0.6, 0.95, 1.0)
@export var spin_speed := 0.5  # rad/s
@export var bob_height := 0.12
@export var bob_speed := 1.2

const HOLOGRAM_SHADER = preload("res://Shaders/hologram.gdshader")

static var _noise_tex: NoiseTexture2D

var _base_y := 0.0
var _elapsed := 0.0


static func _noise_texture() -> NoiseTexture2D:
	if _noise_tex == null:
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		noise.frequency = 0.08
		_noise_tex = NoiseTexture2D.new()
		_noise_tex.width = 256
		_noise_tex.height = 256
		_noise_tex.seamless = true
		_noise_tex.noise = noise
	return _noise_tex


func _ready() -> void:
	_base_y = position.y

	var material := ShaderMaterial.new()
	material.shader = HOLOGRAM_SHADER
	material.set_shader_parameter("primary_color", primary_color)
	material.set_shader_parameter("secondary_color", secondary_color)
	material.set_shader_parameter("noise_texture", _noise_texture())

	_apply_material(self, material)


func _apply_material(node: Node, material: ShaderMaterial) -> void:
	if node is MeshInstance3D:
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	for child in node.get_children():
		_apply_material(child, material)


func _process(delta: float) -> void:
	_elapsed += delta
	rotate_y(spin_speed * delta)
	position.y = _base_y + sin(_elapsed * bob_speed) * bob_height
