extends RefCounted

class_name PlayerAnimationFSM

enum State { IDLE, WALK, RUN, JUMP_START, JUMP_LOOP, JUMP_LAND, CROUCH_IDLE, CROUCH_WALK }

const ANIM_NAMES := {
	State.IDLE: "Idle",
	State.WALK: "Walk",
	State.RUN: "Sprint",
	State.JUMP_START: "Jump_Start",
	State.JUMP_LOOP: "Jump_Loop",
	State.JUMP_LAND: "Jump_Land",
	State.CROUCH_IDLE: "Crouch_Idle",
	State.CROUCH_WALK: "Crouch_Fwd",
}

const WALK_SPEED_THRESHOLD := 0.5
const RUN_SPEED_THRESHOLD := 6.0
const LAND_ANIM_DURATION := 0.12  # bem curto — andar sobrepõe o pouso na hora

var current_state: int = State.IDLE
var _was_on_floor := true
var _landing_timer := 0.0


# Retorna o nome da animação a tocar, ou "" se o estado não mudou
func update(delta: float, on_floor: bool, horizontal_speed: float, is_crouching: bool) -> String:
	var next_state = current_state

	if _landing_timer > 0.0:
		_landing_timer -= delta
		# Andar já sobrepõe a animação de pouso, mesmo antes do tempo normal acabar
		if _landing_timer <= 0.0 or horizontal_speed > WALK_SPEED_THRESHOLD:
			_landing_timer = 0.0
			next_state = _ground_state(horizontal_speed, is_crouching)
	elif not on_floor:
		if _was_on_floor:
			next_state = State.JUMP_START
		else:
			next_state = State.JUMP_LOOP
	else:
		if not _was_on_floor:
			next_state = State.JUMP_LAND
			_landing_timer = LAND_ANIM_DURATION
		else:
			next_state = _ground_state(horizontal_speed, is_crouching)

	_was_on_floor = on_floor

	if next_state == current_state:
		return ""

	current_state = next_state
	return ANIM_NAMES[next_state]


func _ground_state(horizontal_speed: float, is_crouching: bool) -> int:
	if is_crouching:
		return State.CROUCH_WALK if horizontal_speed > WALK_SPEED_THRESHOLD else State.CROUCH_IDLE
	if horizontal_speed > RUN_SPEED_THRESHOLD:
		return State.RUN
	if horizontal_speed > WALK_SPEED_THRESHOLD:
		return State.WALK
	return State.IDLE
