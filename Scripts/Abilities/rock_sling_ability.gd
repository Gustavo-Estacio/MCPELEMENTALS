extends Node

class_name RockSlingAbility

var ability_name := "Rock Sling"
var element := 2  # ElementsEnum.Element.EARTH
var slot := 2  # ElementsEnum.Slot.PROJECTILE
var cooldown := 0.5
var charge_time := 0.0
var max_charge_time := 2.0
var base_force := 20.0

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
	return clamp(1.0 + (progress * 1.5), 1.0, 2.5)  # 1.0x a 2.5x de poder (máximo fixo)


func cast(player: Node3D, direction: Vector3) -> RockSling:
	var scene = preload("res://Scenes/Effects/rock_sling.tscn")
	var rock = scene.instantiate()

	var spawn_pos = player.global_position + Vector3(0, 0.5, 0) + direction * 1.5
	rock.global_position = spawn_pos
	rock.owner_peer_id = player.get_multiplayer_authority()
	rock.element = element
	rock.tag = "projectile"
	rock.charge_power = get_charge_power()

	# Movimento em arco (lançamento oblíquo)
	var velocity = direction * base_force * get_charge_power()
	velocity.y += 10.0  # Arco inicial
	rock.linear_velocity = velocity

	is_charging = false
	charge_time = 0.0

	return rock
