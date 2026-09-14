extends Area3D

class_name RockDecal

var element: int = 2  # ElementsEnum.Element.EARTH
var tag: String = "decal"
var infused_with: int = -1
var owner_peer_id: int = -1
var is_reacting := false

@export var EXPLOSION_SCALE := 3.0  # ao menos o dobro do tamanho do player


func _ready() -> void:
	add_to_group("ElementalCarriers")
	area_entered.connect(_on_area_entered)
	collision_layer = 8
	collision_mask = 4
	_apply_random_texture()
	_update_visual_infusion()
	_start_lifetime()


func _start_lifetime() -> void:
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self) and not is_reacting:
		queue_free()


func _on_area_entered(other: Area3D) -> void:
	if not is_multiplayer_authority():
		return

	# Fireball reaction
	if other.get_parent() is FireBall:
		await _react_to_fireball(other.get_parent())
		return

	if not (other.get_parent() is RockSling):
		return

	var rock_sling: RockSling = other.get_parent()
	var rule = ReactionDatabase.find_rule(element, tag, rock_sling.element, rock_sling.tag)
	if not rule:
		return

	ReactionResolver.resolve(self, rock_sling)


func _react_to_fireball(fireball: FireBall) -> void:
	is_reacting = true

	if has_node("MeshInstance3D"):
		var mesh = get_node("MeshInstance3D")
		var material = mesh.get_active_material(0)
		if material:
			material = material.duplicate()
			mesh.set_surface_override_material(0, material)

			# Tween albedo from white to red over 3 seconds
			var tween = create_tween()
			tween.tween_property(material, "albedo_color", Color.RED, 3.0)
			await tween.finished

			# Create explosion (fumaça + fogo)
			_spawn_explosion()


func set_infused_with(elem: int) -> void:
	infused_with = elem
	_update_visual_infusion()


func _update_visual_infusion() -> void:
	if not has_node("MeshInstance3D"):
		return

	match infused_with:
		ElementsEnum.Element.FIRE:
			var mesh = $MeshInstance3D
			var material = mesh.get_active_material(0)
			if material:
				material = material.duplicate()
				material.albedo_color = Color(0.6, 0.1, 0.05)
				mesh.set_surface_override_material(0, material)
		ElementsEnum.Element.WATER:
			# Mudaria pra material de água
			pass
		ElementsEnum.Element.ELECTRIC:
			# Mudaria pra material elétrico
			pass


func _spawn_explosion() -> void:
	var explosion_scene = preload("res://Scenes/Effects/explosion.tscn")
	var explosion = explosion_scene.instantiate()
	explosion.position = global_position
	explosion.scale = Vector3.ONE * EXPLOSION_SCALE

	# Spawna como irmão (filho de get_parent(), não do decal) pra replicar certo via MultiplayerSpawner
	get_parent().add_child(explosion, true)

	queue_free()


func _apply_random_texture() -> void:
	var textures = [
		"res://addons/kenney_prototype_textures/dark/texture_01.png",
		"res://addons/kenney_prototype_textures/dark/texture_02.png",
		"res://addons/kenney_prototype_textures/dark/texture_03.png",
		"res://addons/kenney_prototype_textures/dark/texture_04.png",
		"res://addons/kenney_prototype_textures/dark/texture_05.png",
		"res://addons/kenney_prototype_textures/dark/texture_06.png",
		"res://addons/kenney_prototype_textures/dark/texture_07.png",
		"res://addons/kenney_prototype_textures/dark/texture_08.png",
		"res://addons/kenney_prototype_textures/dark/texture_09.png",
		"res://addons/kenney_prototype_textures/dark/texture_10.png",
		"res://addons/kenney_prototype_textures/dark/texture_11.png",
		"res://addons/kenney_prototype_textures/dark/texture_12.png",
		"res://addons/kenney_prototype_textures/dark/texture_13.png",
	]

	if has_node("MeshInstance3D"):
		var mesh = get_node("MeshInstance3D")
		var material = StandardMaterial3D.new()
		var random_texture = textures[randi() % textures.size()]
		material.albedo_texture = load(random_texture)
		mesh.set_surface_override_material(0, material)
