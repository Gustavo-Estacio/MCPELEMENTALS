extends RefCounted

class_name EnemyDeath

## Sequência de morte compartilhada por MeleeEnemy e RangedEnemy: tomba (sem esqueleto,
## então o "ragdoll" é o corpo inteiro caindo e girando pro chão), fica largado por
## RAGDOLL_HOLD_TIME, dissolve com o shader e some.
##
## A queda em si (gravidade + tombo) só é simulada pela AUTORIDADE do inimigo — os outros
## peers só recebem a posição/rotação pelo MultiplayerSynchronizer de sempre, igual já
## acontecia com o movimento normal de IA. O dissolve é puramente cosmético e roda local
## em CADA peer (mesmo padrão do Explosion/DamageNumber), senão só quem matou veria.

const RAGDOLL_HOLD_TIME := 2.0
const TOPPLE_TIME := 0.35
const TOPPLE_ANGLE := 1.4  # ~80°, radianos
const DISSOLVE_TIME := 1.0
const DISSOLVE_NOISE_SCALE := 3.0
const DEATH_DRAG := 6.0  # freia o deslizamento horizontal enquanto tomba

static var _shader: Shader = preload("res://Shaders/dissolve.gdshader")
static var _noise_tex: NoiseTexture2D


static func _noise_texture() -> NoiseTexture2D:
	if _noise_tex == null:
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.frequency = 0.05
		_noise_tex = NoiseTexture2D.new()
		_noise_tex.width = 128
		_noise_tex.height = 128
		_noise_tex.seamless = true
		_noise_tex.noise = noise
	return _noise_tex


static func start(enemy: CharacterBody3D, mesh: MeshInstance3D) -> void:
	if not is_instance_valid(enemy):
		return

	var drive_physics := enemy.is_multiplayer_authority()
	var topple_axis := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
	var start_rotation := enemy.rotation

	var elapsed := 0.0
	while elapsed < RAGDOLL_HOLD_TIME:
		if not is_instance_valid(enemy):
			return
		await enemy.get_tree().physics_frame
		if not is_instance_valid(enemy):
			return

		var delta := enemy.get_physics_process_delta_time()
		elapsed += delta

		if drive_physics:
			if not enemy.is_on_floor():
				enemy.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
			enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, DEATH_DRAG * delta)
			enemy.velocity.z = move_toward(enemy.velocity.z, 0.0, DEATH_DRAG * delta)
			enemy.move_and_slide()

			if elapsed < TOPPLE_TIME:
				var topple_t := elapsed / TOPPLE_TIME
				enemy.rotation = start_rotation + topple_axis * (TOPPLE_ANGLE * topple_t)

	if not is_instance_valid(enemy):
		return

	await _dissolve(enemy, mesh)

	# Só a autoridade remove de verdade — o MultiplayerSpawner despawna nos outros peers
	# quando ela sai da árvore, igual já acontecia com o queue_free() direto de antes.
	if drive_physics and is_instance_valid(enemy):
		enemy.queue_free()


static func _dissolve(enemy: CharacterBody3D, mesh: MeshInstance3D) -> void:
	if not is_instance_valid(mesh):
		return

	var base_color := Color.WHITE
	var base_material := mesh.get_active_material(0)
	if base_material is StandardMaterial3D:
		base_color = base_material.albedo_color

	var material := ShaderMaterial.new()
	material.shader = _shader
	material.set_shader_parameter("albedo_and_emissive_color", base_color)
	material.set_shader_parameter("noise_tex", _noise_texture())
	material.set_shader_parameter("noise_scale", DISSOLVE_NOISE_SCALE)
	material.set_shader_parameter("t", 0.0)
	mesh.material_override = material

	var tween := enemy.create_tween()
	tween.tween_method(
		func(v: float): material.set_shader_parameter("t", v),
		0.0, 1.0, DISSOLVE_TIME
	)
	await tween.finished
