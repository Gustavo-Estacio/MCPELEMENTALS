extends Area3D

class_name WaterPuddle

## Poça deixada pelo Water Dash: sempre no chão (Global._project_to_ground). Qualquer
## aliado que pisa nela corre mais rápido e vai se curando aos poucos.
##
## Quem decide é a AUTORIDADE da poça (o servidor, que foi quem a spawnou): ela avisa o
## dono de cada player por RPC, porque movimento e vida são calculados na máquina do
## próprio jogador.

var element: int = ElementsEnum.Element.WATER
var tag: String = "decal"

@export var LIFETIME := 4.0
@export var SPEED_MULTIPLIER := 1.5  # movespeed de quem está em cima da poça
@export var HEAL_PER_TICK := 18  # 3x
@export var HEAL_INTERVAL := 0.5

var _players_inside: Array = []
var _heal_timer := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # só players (ver Player.tscn, collision_layer = 2)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var tween = create_tween()
	tween.tween_interval(LIFETIME * 0.6)
	tween.tween_property(self, "scale", Vector3.ZERO, LIFETIME * 0.4)
	tween.tween_callback(func():
		if is_instance_valid(self):
			queue_free()
	)


func _exit_tree() -> void:
	# A poça pode sumir com alguém em cima: tira o buff de todo mundo antes de morrer.
	if not is_multiplayer_authority():
		return
	for player in _players_inside:
		if is_instance_valid(player):
			player.set_puddle_bonus.rpc(false, SPEED_MULTIPLIER)
	_players_inside.clear()


func _on_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return
	if not body.is_in_group('Players') or _players_inside.has(body):
		return

	_players_inside.append(body)
	body.set_puddle_bonus.rpc(true, SPEED_MULTIPLIER)


func _on_body_exited(body: Node3D) -> void:
	if not is_multiplayer_authority() or not _players_inside.has(body):
		return

	_players_inside.erase(body)
	if is_instance_valid(body):
		body.set_puddle_bonus.rpc(false, SPEED_MULTIPLIER)


func _process(delta: float) -> void:
	if not is_multiplayer_authority() or _players_inside.is_empty():
		return

	_heal_timer += delta
	if _heal_timer < HEAL_INTERVAL:
		return
	_heal_timer = 0.0

	for player in _players_inside:
		if is_instance_valid(player) and player.has_method("heal"):
			player.heal(HEAL_PER_TICK)
