extends Node

## Autoload "DevFX": monta e aplica os efeitos visuais da aba DEV das opções.
##
## Os valores vêm do Settings (chaves com prefixo "dev_"), então pra mexer em
## qualquer coisa aqui basta abrir Options > DEV. Nada fica salvo na cena: tudo
## é criado em runtime.
##
## São quatro camadas:
##   * ColorRect num CanvasLayer abaixo da UI -> cel shading, speed lines,
##     distortion, film grain, color grading, chromatic aberration, pixelation.
##   * Quad de tela cheia preso na câmera     -> outline e rim light (precisam
##     do depth buffer).
##   * Surface override de material toon      -> toon shader por objeto.
##   * Environment.glow do WorldEnvironment   -> bloom.

const SCREEN_SHADER := preload("res://Shaders/PostFX/screen_fx.gdshader")
const DEPTH_SHADER := preload("res://Shaders/PostFX/depth_fx.gdshader")
const TOON_SHADER := preload("res://Shaders/PostFX/toon.gdshader")

## CanvasLayer padrão da UI é 1, então 0 deixa os efeitos embaixo da HUD: o
## screen texture pega só o 3D e a interface continua legível.
const FX_LAYER := 0

const TOON_META := &"devfx_toon_originals"

## Toggles que só afetam o ColorRect 2D (pra pular o blit quando todos off).
const SCREEN_TOGGLES := [
	"dev_cel_enabled",
	"dev_distortion_enabled",
	"dev_grain_enabled",
	"dev_grading_enabled",
	"dev_chroma_enabled",
	"dev_pixelate_enabled",
]

## Speed lines não são opção de menu: quem liga é o gameplay (Player.gd), com um
## preset por situação. Valores em % / unidades do shader.
const SPEEDLINES_WALK := "walk"
const SPEEDLINES_DASH := "dash"

const SPEEDLINES_PRESETS := {
	# Anexo 1: boost de andar fora de combate — bem sutil.
	SPEEDLINES_WALK: {"strength": 5.0, "density": 10.0, "speed": 1.0, "falloff": 60.0},
	# Anexo 2: dashes (Boulder / Fire / Air).
	SPEEDLINES_DASH: {"strength": 60.0, "density": 60.0, "speed": 2.0, "falloff": 40.0},
}

const _SL_OFF := 0
const _SL_HOLD := 1
const _SL_FADE := 2

var _layer: CanvasLayer
var _rect: ColorRect
var _screen_material: ShaderMaterial

var _quad: MeshInstance3D
var _depth_material: ShaderMaterial

var _environment_cache: Environment
var _toon_materials: Array[ShaderMaterial] = []
var _toon_active := false

var _sl_preset := ""
var _sl_phase := _SL_OFF
var _sl_alpha := 0.0
var _sl_hold_left := -1.0  # negativo = fica ligado até mandarem parar
var _sl_fade_left := 0.0
var _sl_fade_time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_screen_layer()
	_build_depth_quad()
	Settings.setting_changed.connect(_on_setting_changed)
	apply_all()


func _process(delta: float) -> void:
	# O mundo (e o WorldEnvironment junto) é criado/destruído em runtime, então
	# o bloom precisa ser reaplicado quando o Environment troca.
	var environment := _environment()
	if environment != _environment_cache:
		_environment_cache = environment
		_apply_bloom()

	if _sl_phase != _SL_OFF:
		_update_speedlines(delta)


func _on_setting_changed(key: String, _value: Variant) -> void:
	if key.begins_with("dev_"):
		apply_all()


# ------------------------------------------------------------------ construção

func _build_screen_layer() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "DevFXLayer"
	_layer.layer = FX_LAYER
	add_child(_layer)

	_screen_material = ShaderMaterial.new()
	_screen_material.shader = SCREEN_SHADER

	_rect = ColorRect.new()
	_rect.name = "DevFXScreen"
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _screen_material
	_layer.add_child(_rect)


func _build_depth_quad() -> void:
	_depth_material = ShaderMaterial.new()
	_depth_material.shader = DEPTH_SHADER
	# Desenha depois dos outros transparentes, senão partículas cobrem o efeito.
	_depth_material.render_priority = 127

	var mesh := QuadMesh.new()
	mesh.size = Vector2(2.0, 2.0)

	# O vértice vira clip space direto no shader, então a posição do quad no
	# mundo não importa: ele pode morar aqui no autoload em vez de virar filho
	# da câmera (que seria liberado junto com o player). Só o culling usa a AABB,
	# e a margem gigante garante que ele nunca é descartado.
	_quad = MeshInstance3D.new()
	_quad.name = "DevFXDepthQuad"
	_quad.mesh = mesh
	_quad.material_override = _depth_material
	_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_quad.extra_cull_margin = 16384.0
	_quad.visible = false
	add_child(_quad)


# ------------------------------------------------------------------- aplicação

func apply_all() -> void:
	var master := _flag("dev_fx_enabled")

	_apply_screen(master)
	_apply_depth(master)
	_apply_bloom()
	_apply_toon(master and _flag("dev_toon_enabled"))


func _apply_screen(master: bool) -> void:
	var any_on := false
	for key in SCREEN_TOGGLES:
		if master and _flag(key):
			any_on = true
			break

	# As speed lines são gameplay, não dependem do toggle mestre da aba DEV: o
	# rect pode ficar visível só por causa delas.
	_rect.visible = any_on or _sl_phase != _SL_OFF

	# Empurra tudo sempre (e desligado quando o mestre está off), senão sobra
	# efeito ligado do estado anterior quando o rect volta pelas speed lines.
	_screen_material.set_shader_parameter("cel_enabled", master and _flag("dev_cel_enabled"))
	_screen_material.set_shader_parameter("cel_bands", _num("dev_cel_bands"))
	_screen_material.set_shader_parameter("cel_mix", _num("dev_cel_mix") / 100.0)

	_apply_speedlines()

	_screen_material.set_shader_parameter("distortion_enabled", master and _flag("dev_distortion_enabled"))
	# slider 0..50 -> 0..0.05 de UV
	_screen_material.set_shader_parameter("distortion_strength", _num("dev_distortion_strength") / 1000.0)
	_screen_material.set_shader_parameter("distortion_speed", _num("dev_distortion_speed"))
	_screen_material.set_shader_parameter("distortion_scale", _num("dev_distortion_scale"))

	_screen_material.set_shader_parameter("grain_enabled", master and _flag("dev_grain_enabled"))
	# slider 0..100 -> 0..0.5 de ruído somado
	_screen_material.set_shader_parameter("grain_amount", _num("dev_grain_amount") / 200.0)
	_screen_material.set_shader_parameter("grain_size", _num("dev_grain_size"))
	_screen_material.set_shader_parameter("grain_animated", _flag("dev_grain_animated"))

	_screen_material.set_shader_parameter("grading_enabled", master and _flag("dev_grading_enabled"))
	_screen_material.set_shader_parameter("grading_exposure", _num("dev_grading_exposure"))
	_screen_material.set_shader_parameter("grading_contrast", _num("dev_grading_contrast"))
	_screen_material.set_shader_parameter("grading_saturation", _num("dev_grading_saturation"))
	_screen_material.set_shader_parameter("grading_temperature", _num("dev_grading_temperature") / 100.0)
	_screen_material.set_shader_parameter("grading_tint", _num("dev_grading_tint") / 100.0)

	_screen_material.set_shader_parameter("chroma_enabled", master and _flag("dev_chroma_enabled"))
	# slider 0..100 -> 0..0.02 de UV
	_screen_material.set_shader_parameter("chroma_strength", _num("dev_chroma_strength") / 5000.0)
	_screen_material.set_shader_parameter("chroma_falloff", _num("dev_chroma_falloff"))

	_screen_material.set_shader_parameter("pixelate_enabled", master and _flag("dev_pixelate_enabled"))
	_screen_material.set_shader_parameter("pixelate_size", _num("dev_pixelate_size"))
	_screen_material.set_shader_parameter("pixelate_quantize", _flag("dev_pixelate_quantize"))
	_screen_material.set_shader_parameter("pixelate_levels", _num("dev_pixelate_levels"))


# ------------------------------------------------------------------ speed lines

## Liga as speed lines e deixa ligadas até alguém chamar speedlines_stop().
## Usado por quem tem duração variável (Boulder Dash, Fire Dash, boost de andar).
func speedlines_start(preset: String) -> void:
	if not SPEEDLINES_PRESETS.has(preset):
		return
	# Quem chama isso chama todo frame (o estado do player manda), então repetir
	# o mesmo preset já ligado não pode reempurrar uniform à toa.
	if _sl_phase == _SL_HOLD and _sl_preset == preset and _sl_hold_left < 0.0:
		return
	_sl_preset = preset
	_sl_phase = _SL_HOLD
	_sl_alpha = 1.0
	_sl_hold_left = -1.0
	_sl_fade_time = 0.0
	_sl_fade_left = 0.0
	_apply_screen(_flag("dev_fx_enabled"))


## Liga em opacidade cheia por `hold` segundos e some em mais `fade` segundos.
## Usado pelo Air Dash (100% até 1s, 100% -> 0% entre 1s e 1.4s).
func speedlines_burst(preset: String, hold: float, fade: float) -> void:
	if not SPEEDLINES_PRESETS.has(preset):
		return
	_sl_preset = preset
	_sl_phase = _SL_HOLD
	_sl_alpha = 1.0
	_sl_hold_left = maxf(hold, 0.0)
	_sl_fade_time = maxf(fade, 0.0)
	_sl_fade_left = _sl_fade_time
	_apply_screen(_flag("dev_fx_enabled"))


## `preset` preenchido = só desliga se as linhas atuais forem desse preset, pra
## o fim de um efeito não apagar o de outro que entrou por cima.
func speedlines_stop(fade := 0.0, preset := "") -> void:
	if _sl_phase == _SL_OFF:
		return
	if preset != "" and _sl_preset != preset:
		return
	if fade <= 0.0:
		_speedlines_off()
		return
	_sl_phase = _SL_FADE
	_sl_fade_time = fade
	_sl_fade_left = fade * _sl_alpha  # já sumindo: continua de onde estava


func speedlines_active() -> bool:
	return _sl_phase != _SL_OFF


func _speedlines_off() -> void:
	_sl_phase = _SL_OFF
	_sl_preset = ""
	_sl_alpha = 0.0
	_apply_screen(_flag("dev_fx_enabled"))


func _update_speedlines(delta: float) -> void:
	match _sl_phase:
		_SL_HOLD:
			if _sl_hold_left < 0.0:
				return  # fica ligado até mandarem parar
			_sl_hold_left -= delta
			if _sl_hold_left > 0.0:
				return
			if _sl_fade_time <= 0.0:
				_speedlines_off()
				return
			_sl_phase = _SL_FADE
			_sl_fade_left = _sl_fade_time
		_SL_FADE:
			_sl_fade_left -= delta
			if _sl_fade_left <= 0.0:
				_speedlines_off()
				return
			_sl_alpha = clampf(_sl_fade_left / _sl_fade_time, 0.0, 1.0)
			_apply_speedlines()


func _apply_speedlines() -> void:
	var active := _sl_phase != _SL_OFF and SPEEDLINES_PRESETS.has(_sl_preset)
	_screen_material.set_shader_parameter("speedlines_enabled", active)
	if not active:
		return

	var preset: Dictionary = SPEEDLINES_PRESETS[_sl_preset]
	_screen_material.set_shader_parameter("speedlines_strength", float(preset["strength"]) / 100.0 * _sl_alpha)
	_screen_material.set_shader_parameter("speedlines_density", float(preset["density"]))
	_screen_material.set_shader_parameter("speedlines_speed", float(preset["speed"]))
	_screen_material.set_shader_parameter("speedlines_falloff", float(preset["falloff"]) / 100.0)


func _apply_depth(master: bool) -> void:
	var outline := _flag("dev_outline_enabled")
	var rim := _flag("dev_rim_enabled")
	_quad.visible = master and (outline or rim)
	if not _quad.visible:
		return

	var outline_color := Color.BLACK
	outline_color.a = _num("dev_outline_opacity") / 100.0

	_depth_material.set_shader_parameter("outline_enabled", outline)
	_depth_material.set_shader_parameter("outline_color", outline_color)
	_depth_material.set_shader_parameter("outline_thickness", _num("dev_outline_thickness"))
	_depth_material.set_shader_parameter("outline_threshold", _num("dev_outline_threshold"))

	_depth_material.set_shader_parameter("rim_enabled", rim)
	_depth_material.set_shader_parameter("rim_color", Color.WHITE)
	_depth_material.set_shader_parameter("rim_power", _num("dev_rim_power"))
	_depth_material.set_shader_parameter("rim_strength", _num("dev_rim_strength") / 100.0)


func _apply_bloom() -> void:
	var environment := _environment()
	if environment == null:
		return
	var enabled := _flag("dev_fx_enabled") and _flag("dev_bloom_enabled")
	environment.glow_enabled = enabled
	if not enabled:
		return
	environment.glow_intensity = _num("dev_bloom_intensity")
	environment.glow_strength = _num("dev_bloom_strength")
	environment.glow_bloom = _num("dev_bloom_spread") / 100.0
	environment.glow_hdr_threshold = _num("dev_bloom_threshold")


func _environment() -> Environment:
	var world := get_viewport().find_world_3d()
	if world == null:
		return null
	return world.environment


# --------------------------------------------------------------- toon override

func _apply_toon(enabled: bool) -> void:
	if enabled and not _toon_active:
		_enable_toon()
	elif not enabled and _toon_active:
		_disable_toon()
	if _toon_active:
		_update_toon_params()


func _enable_toon() -> void:
	_toon_active = true
	_toon_materials.clear()
	_toon_apply_recursive(get_tree().root)
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)


func _disable_toon() -> void:
	_toon_active = false
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
	_toon_restore_recursive(get_tree().root)
	_toon_materials.clear()


func _on_node_added(node: Node) -> void:
	if node is MeshInstance3D:
		# Espera a cena terminar de entrar: a mesh às vezes só chega depois.
		_toon_apply_to_mesh.call_deferred(node)


func _toon_apply_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		_toon_apply_to_mesh(node)
	for child in node.get_children():
		_toon_apply_recursive(child)


func _toon_restore_recursive(node: Node) -> void:
	if node is MeshInstance3D and node.has_meta(TOON_META):
		var originals: Array = node.get_meta(TOON_META)
		for index in originals.size():
			if index < node.get_surface_override_material_count():
				node.set_surface_override_material(index, originals[index])
		node.remove_meta(TOON_META)
	for child in node.get_children():
		_toon_restore_recursive(child)


func _toon_apply_to_mesh(mesh_instance: MeshInstance3D) -> void:
	if not _toon_active or not is_instance_valid(mesh_instance):
		return
	if mesh_instance == _quad or mesh_instance.mesh == null:
		return
	if mesh_instance.has_meta(TOON_META) or mesh_instance.is_in_group("no_toon"):
		return
	# material_override é de quem já escolheu o próprio visual (trail, decal...).
	if mesh_instance.material_override != null:
		return

	var originals: Array = []
	var applied := false

	for index in mesh_instance.get_surface_override_material_count():
		var source := mesh_instance.get_active_material(index)
		originals.append(mesh_instance.get_surface_override_material(index))

		var standard := source as StandardMaterial3D
		# ShaderMaterial (lava, céu) e materiais unshaded ficam como estão.
		if standard == null or standard.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
			continue
		if standard.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			continue

		var toon := ShaderMaterial.new()
		toon.shader = TOON_SHADER
		toon.set_shader_parameter("albedo", standard.albedo_color)
		toon.set_shader_parameter("albedo_texture", standard.albedo_texture)
		toon.set_shader_parameter("uv_scale", Vector2(standard.uv1_scale.x, standard.uv1_scale.y))
		mesh_instance.set_surface_override_material(index, toon)
		_toon_materials.append(toon)
		applied = true

	if applied:
		mesh_instance.set_meta(TOON_META, originals)


func _update_toon_params() -> void:
	var bands := _num("dev_toon_bands")
	var softness := _num("dev_toon_softness") / 100.0
	var shadow_tint := _num("dev_toon_shadow") / 100.0
	var specular := _num("dev_toon_specular") / 100.0
	var energy := _num("dev_toon_energy") / 100.0

	for material in _toon_materials:
		if not is_instance_valid(material):
			continue
		material.set_shader_parameter("bands", bands)
		material.set_shader_parameter("band_softness", softness)
		material.set_shader_parameter("shadow_tint", shadow_tint)
		material.set_shader_parameter("specular_strength", specular)
		material.set_shader_parameter("light_energy", energy)


# ------------------------------------------------------------------ utilidades

func _flag(key: String) -> bool:
	return bool(Settings.get_value(key))


func _num(key: String) -> float:
	return float(Settings.get_value(key))
