extends Node

class_name FireBallAbility

var ability_name := "FireBall"
var element := 0  # ElementsEnum.Element.FIRE
var slot := 3  # ElementsEnum.Slot.SPECIAL_SKILL
var cooldown := 0.8
var charge_time := 0.0
var max_charge_time := 1.5
var base_force := 25.0

var is_charging := false
var charge_start_time := 0.0


func start_charge() -> void:
	is_charging = true
	charge_start_time = Time.get_ticks_msec()
	charge_time = 0.0


func get_charge_progress() -> float:
	if not is_charging:
		return 0.0
	var elapsed = (Time.get_ticks_msec() - charge_start_time) / 1000.0
	return min(elapsed / max_charge_time, 1.0)


func get_charge_power() -> float:
	var progress = get_charge_progress()
	return clamp(1.0 + (progress * 1.0), 1.0, 2.0)  # 1.0x a 2.0x de poder (máximo fixo)


func cast(player: Node3D, direction: Vector3) -> FireBall:
	var scene = preload("res://Scenes/Effects/fireball.tscn")
	var fireball = scene.instantiate()

	var spawn_pos = player.global_position + Vector3(0, 1.0, 0) + direction * 2.0
	fireball.global_position = spawn_pos
	fireball.owner_peer_id = player.get_multiplayer_authority()
	fireball.element = element
	fireball.tag = "projectile"
	fireball.charge_power = get_charge_power()

	# Movimento reto com possível curva
	var velocity = direction * base_force * get_charge_power()
	velocity.y += 5.0  # Leve arco
	fireball.linear_velocity = velocity

	is_charging = false
	charge_time = 0.0

	return fireball
