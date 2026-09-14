extends Area3D

class_name Tornado

@export var SPEED := 6.0
@export var ZIGZAG_AMPLITUDE := 1.2
@export var ZIGZAG_FREQUENCY := 1.2
@export var LIFETIME := 5.0
@export var TICK_INTERVAL := 0.4
@export var DAMAGE_PER_TICK := 6
@export var CONE_GROW_TIME := 1.5
@export var CONE_START_SCALE := 0.3
@export var TIME_GROWTH_BONUS := 5.0  # +500% de tamanho ao longo de toda a duração, só pelo tempo
@export var FALL_GRAVITY := 14.0  # gravidade aplicada enquanto o tornado não alcança o chão
@export var GROUND_SNAP_DISTANCE := 0.2  # distância pra considerar que "pousou" no chão

var element: int = 3  # ElementsEnum.Element.AIR
var tag: String = "projectile"
var owner_peer_id: int = -1

var forward_dir := Vector3.FORWARD
var right_dir := Vector3.RIGHT
var start_pos := Vector3.ZERO
var traveled := 0.0
var vertical_velocity := 0.0
var is_grounded := false
var _age := 0.0
var _tick_timer := 0.0
var _bodies_inside: Array = []

@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var cone: MeshInstance3D = $Cone


func setup(spawn_pos: Vector3, direction: Vector3) -> void:
	start_pos = spawn_pos
	forward_dir = Vector3(direction.x, 0, direction.z).normalized()
	right_dir = forward_dir.cross(Vector3.UP).normalized()
	global_position = start_pos


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	particles.restart()

	if is_multiplayer_authority():
		cone.scale = Vector3.ONE * CONE_START_SCALE
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(cone, "scale", Vector3.ONE, CONE_GROW_TIME)

		get_tree().create_timer(LIFETIME).timeout.connect(func():
			if is_instance_valid(self):
				queue_free()
		)


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	traveled += SPEED * delta
	var lateral_offset = sin(traveled * ZIGZAG_FREQUENCY) * ZIGZAG_AMPLITUDE
	var target_pos = start_pos + forward_dir * traveled + right_dir * lateral_offset
	global_position.x = target_pos.x
	global_position.z = target_pos.z

	_apply_gravity(delta)

	_age += delta
	_update_scale()

	_tick_timer += delta
	if _tick_timer >= TICK_INTERVAL:
		_tick_timer = 0.0
		for body in _bodies_inside:
			if is_instance_valid(body) and body.has_method('take_damage'):
				body.take_damage(DAMAGE_PER_TICK, owner_peer_id, element)


func _apply_gravity(delta: float) -> void:
	if is_grounded:
		return

	vertical_velocity -= FALL_GRAVITY * delta
	var motion = vertical_velocity * delta

	var space_state = get_world_3d().direct_space_state
	var from = global_position
	var to = global_position + Vector3(0, motion - GROUND_SNAP_DISTANCE, 0)
	var query = PhysicsRayQueryParameters3D.create(from, to, 1)  # layer 1 = chão/estático
	query.exclude = [self]
	var result = space_state.intersect_ray(query)

	if result:
		global_position.y = result.position.y
		vertical_velocity = 0.0
		is_grounded = true
	else:
		global_position.y += motion


func _on_body_entered(body: Node3D) -> void:
	if not _bodies_inside.has(body):
		_bodies_inside.append(body)


func _on_body_exited(body: Node3D) -> void:
	_bodies_inside.erase(body)


func _update_scale() -> void:
	# Cresce gradualmente com o tempo de vida, até TIME_GROWTH_BONUS a mais no fim da duração
	var time_frac = clampf(_age / LIFETIME, 0.0, 1.0)
	var growth = 1.0 + TIME_GROWTH_BONUS * time_frac
	scale = Vector3.ONE * growth
