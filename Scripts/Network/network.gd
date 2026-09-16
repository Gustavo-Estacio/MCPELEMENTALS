extends Node

const PLAYER = preload("uid://dyabas8evvb1d")
const TUBE_CONTEXT = preload("uid://4clx7rw338o2")

var enet_peer := ENetMultiplayerPeer.new()
var tube_client := TubeClient.new()
var tube_enabled = true

## true enquanto o jogador estiver numa partida sem rede (menu "Start"),
## usado pra saber se há algo pra "Disconnect" e evitar mexer no tube_client
## quando nunca houve sessão.
var is_singleplayer := false
## true assim que alguma sessão de rede (enet ou tube) foi de fato aberta.
var is_networked := false


var PORT = 9999
var IP_ADDRESS = '127.0.0.1'

func _ready() -> void:
	if tube_enabled:
		tube_client.context = TUBE_CONTEXT
		get_tree().root.add_child.call_deferred(tube_client)

func tube_create():
	is_networked = true
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	tube_client.create_session()
	add_player(1)

func tube_join(session_id: String):
	is_networked = true
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	multiplayer.connected_to_server.connect(on_connected_to_server)
	tube_client.join_session(session_id)


func start_server():
	is_networked = true
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)



func join_server():
	is_networked = true
	enet_peer.create_client(IP_ADDRESS, PORT)
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	multiplayer.connected_to_server.connect(on_connected_to_server)
	multiplayer.multiplayer_peer = enet_peer


## Coloca um player local sem nenhuma rede envolvida (botão "Start" do menu).
func start_singleplayer() -> void:
	is_singleplayer = true
	add_player(1)


func on_connected_to_server():
	add_player(multiplayer.get_unique_id())


func add_player(peer_id: int):
	if peer_id == 1 and multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		return
	
	var new_player = PLAYER.instantiate()
	new_player.name = str(peer_id)
	
	var rand_x = randf_range(-5.0, 5.0)
	var rand_z = randf_range(-5.0, 5.0)
	
	new_player.position = Vector3(rand_x, 1, rand_z)
	get_tree().current_scene.add_child(new_player, true)

func remove_player(peer_id):
	if peer_id == 1:
		leave_server()
	
	var players: Array[Node] = get_tree().get_nodes_in_group('Players')
	var player_to_remove = players.find_custom(func(item): return item.name == str(peer_id))
	if player_to_remove != -1:
		players[player_to_remove].queue_free()

## Encerra a partida atual (rede ou singleplayer) e volta pro menu principal.
func leave_server():
	if tube_enabled and is_networked:
		tube_client.leave_session()

	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	clean_up_signals()
	is_singleplayer = false
	is_networked = false
	get_tree().reload_current_scene()

func clean_up_signals():
	if multiplayer.peer_connected.is_connected(add_player):
		multiplayer.peer_connected.disconnect(add_player)
	if multiplayer.peer_disconnected.is_connected(remove_player):
		multiplayer.peer_disconnected.disconnect(remove_player)
	if multiplayer.connected_to_server.is_connected(on_connected_to_server):
		multiplayer.connected_to_server.disconnect(on_connected_to_server)

func _exit_tree() -> void:
	if tube_enabled and is_networked:
		tube_client.leave_session()
