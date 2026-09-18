extends RigidBody3D

var is_moveable := true  # habilidades físicas que o Wind Torrent do Air consegue empurrar/redirecionar

# -1 enquanto é do inimigo que atirou. Um player que empurra (Wind Torrent) ou deflete
# (Slash of Air) esse projétil "rouba a autoria": vira o peer_id de quem mexeu nele, e
# a partir daí o projétil passa a ferir inimigos em vez de players (ver wind_torrent.gd
# e Global._deflect_projectiles, que setam isso via duck typing).
var redirected_by_peer_id := -1

@onready var area_3d: Area3D = $Area3D
@onready var lifetime: Timer = $Lifetime

func _ready() -> void:
	area_3d.body_entered.connect(_on_hit)
	lifetime.timeout.connect(queue_free)


func _on_hit(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return

	if redirected_by_peer_id != -1:
		# Foi "roubado": agora é team-based dos players, só fere inimigos.
		if body.is_in_group('Enemies') and body.has_method('take_damage'):
			body.take_damage(200, redirected_by_peer_id)
			queue_free()
		return

	if body.is_in_group('Enemies'):
		return  # não colide com quem atirou nem com outros inimigos

	if body.is_in_group('Players') and body.has_method('take_damage'):
		body.take_damage(200, -1)

	queue_free()
