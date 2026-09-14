extends Node

class_name EarthLeapAbility

var ability_name := "Earth Leap"
var element := 2  # ElementsEnum.Element.EARTH
var slot := 5  # ElementsEnum.Slot.JUMP
var cooldown := 1.0
var max_charge_time := 1.5

const TAP_THRESHOLD := 0.15  # segurar menos que isso ainda conta como um pulo normal

var is_charging := false
var charge_start_time := 0.0


func start_charge() -> void:
	is_charging = true
	charge_start_time = Time.get_ticks_msec()


func get_hold_duration() -> float:
	if not is_charging:
		return 0.0
	return (Time.get_ticks_msec() - charge_start_time) / 1000.0


func get_charge_progress() -> float:
	return min(get_hold_duration() / max_charge_time, 1.0)


func get_charge_power() -> float:
	return clamp(1.0 + (get_charge_progress() * 1.5), 1.0, 2.5)


func is_tap() -> bool:
	return get_hold_duration() < TAP_THRESHOLD


func end_charge() -> void:
	is_charging = false
