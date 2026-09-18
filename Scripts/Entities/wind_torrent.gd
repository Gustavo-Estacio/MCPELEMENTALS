extends RigidBody3D

class_name WindTorrent

@export var SPEED := 17.5  # +75% de velocidade
@export var LIFETIME := 2.5
@export var WIND_PUSH_STRENGTH := 13.33  # empurrão único somado ao vetor de movimento da habilidade "moveable" (1/3 da força anterior)
@export var DAMAGE := 10  # o empurrão também machuca quem ele atravessa

var element: int = 3  # ElementsEnum.Element.AIR
var tag: String = "projectile"
var owner_peer_id: int = -1

var forward_dir := Vector3.FORWARD  # direção fixada no momento do cast, não muda durante o voo
var _already_pushed: Array = []  # cada corpo só recebe o empurrão 1 vez por wind torrent

@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var area_3d: Area3D = $Area3D


func setup(spawn_pos: Vector3, direction: Vector3) -> void:
	forward_dir = direction.normalized() if direction.length() > 0.01 else Vector3.FORWARD
	global_position = spawn_pos
	linear_velocity = forward_dir * SPEED


func _ready() -> void:
	area_3d.area_entered.connect(_on_area_entered)
	area_3d.body_entered.connect(_on_body_entered)
	particles.restart()

	if is_multiplayer_authority():
		get_tree().create_timer(LIFETIME).timeout.connect(func():
			if is_instance_valid(self):
				queue_free()
		)


# O vento não só empurra: quem ele atravessa também leva dano (uma vez por corpo).
func _on_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority() or _already_pushed.has(body):
		return

	if body.has_method('take_damage'):
		_already_pushed.append(body)
		body.take_damage(DAMAGE, owner_peer_id, element)


func _on_area_entered(other: Area3D) -> void:
	if not is_multiplayer_authority():
		return

	# Habilidades físicas "moveable" (ex: rock sling) têm layer 0 na raiz, mas
	# o Area3D filho delas tem layer real — é assim que outros sistemas as detectam.
	# Só empurra corpos que se declaram "is_moveable" (não qualquer RigidBody3D, tipo fireball).
	var body = other.owner
	if body and body is RigidBody3D and "is_moveable" in body and body.is_moveable and not _already_pushed.has(body):
		_already_pushed.append(body)
		# Empurrão único: soma a força do vento (na direção fixa do cast) ao vetor de movimento atual da pedra
		body.linear_velocity += forward_dir * WIND_PUSH_STRENGTH

		# Rouba a autoria de projétil inimigo: a partir daqui ele fere inimigos, não players.
		if "redirected_by_peer_id" in body:
			body.redirected_by_peer_id = owner_peer_id
