extends CharacterBody3D

class_name Player

@export_group("Movement")
@export var SPEED := 5.0
@export var JUMP_VELOCITY := 4.5 * 3.4 * (2.0 / 3.0)  # aumentado em 240%, depois reduzido em 1/3
@export var mouse_sensitivity := 0.002

@export_group("Speed Boost (andar sem tomar dano)")
@export var BOOST_DELAY := 2.0  # segundos andando sem tomar dano
@export var BOOST_MULTIPLIER := 2.0
@export var BOOST_FOV_INCREASE := 6.0
@export var FOV_LERP_SPEED := 6.0

@export_group("Crouch")
@export var STAND_HEIGHT := 2.0
@export var CROUCH_HEIGHT := 1.2
@export var CROUCH_SPEED_MULTIPLIER := 0.5
@export var CROUCH_FALL_MULTIPLIER := 2.2  # agachar no ar acelera a queda (fast fall)
@export var CTRL_AIR_DASH_DOWN_SPEED := 14.0  # mini dash instantâneo pra baixo ao apertar crouch no ar (boulder ou planando)

@export_group("Earth Leap")
@export var EARTH_LEAP_VERTICAL := 12.0  # dobro da velocidade de ascensão original
@export var EARTH_LEAP_TILT_DEGREES := 20.0  # inclinação a partir da vertical, na direção da câmera
@export var EARTH_LEAP_FALL_ACCEL_MULTIPLIER := 2.5  # gravidade extra na queda, pra bater forte no chão
@export var TRAJECTORY_POINTS := 20
@export var TRAJECTORY_TIME_STEP := 0.08

@export_group("Boulder Dash (Earth Shift)")
@export var BOULDER_DURATION := 6.0
@export var BOULDER_MIN_SPEED_MULTIPLIER := 2.0  # velocidade logo ao ativar, antes de crescer/acelerar
@export var BOULDER_SPEED_MULTIPLIER := 2.5
@export var BOULDER_FOV_INCREASE := 10.0
@export var BOULDER_DECAL_INTERVAL := 0.2
@export var BOULDER_RADIUS := 2.0  # tem que bater com o raio do SphereMesh_boulder na cena (tamanho máximo)
@export var BOULDER_GROW_DISTANCE := 35.0  # distância percorrida até alcançar o tamanho máximo (não cresce parado)
@export var BOULDER_START_SCALE := 0.5  # começa do tamanho aproximado do jogador (diâmetro 2.0 = metade do máximo 4.0)
@export var BOULDER_TURN_RATE := 1.6  # rad/s, bem mais devagar — difícil de ajustar a direção, feito uma pedra pesada
@export var DECAL_BASE_RADIUS := 0.3  # raio base do CylinderMesh do RockDecal

@export_group("Fire Dash (Fire Shift)")
@export var FIRE_DASH_DURATION := 5.0
@export var FIRE_DASH_MULTIPLIER := 2.0

@export_group("Flamethrower (Fire Q)")
@export var FLAMETHROWER_DURATION := 4.0
@export var FLAMETHROWER_TICK_INTERVAL := 0.15

@export_group("Earth Spikes (Earth E)")
@export var SPIKE_COUNT := 12
@export var SPIKE_INTERVAL := 0.06

@export_group("Rock Barrage (LMB/RMB Earth)")
@export var LMB_SHOT_INTERVAL := 0.12
@export var LMB_WAVES_BEFORE_BIG := 3
@export var LMB_RELOAD_TIME := 1.5
@export var RMB_SHOT_INTERVAL := 0.15
@export var RMB_RELOAD_TIME := 2.0

@export_group("Air Dash (Air Shift)")
@export var AIR_DASH_MAX_STACKS := 3
@export var AIR_DASH_RECHARGE_TIME := 5.0
@export var AIR_DASH_SPEED := 18.0
@export var AIR_DASH_DURATION := 0.5  # janela em que o impulso do dash não é sobrescrito pelo movimento normal (dobro = dobro da distância percorrida)
@export var AIR_DASH_FOV_INCREASE := 15.0
@export var AIR_DASH_FOV_LERP_SPEED := 18.0  # subida rápida; a volta usa o FOV_LERP_SPEED normal

@export_group("Cast FOV Kick (Wind Torrent / Tornado)")
@export var CAST_FOV_KICK_AMOUNT := 10.0
@export var CAST_FOV_KICK_DECAY := 5.0  # unidades de FOV por segundo, decaindo de volta ao normal

@export_group("Air Slashes (Air LMB)")
@export var AIR_SLASH_COUNT := 3
@export var AIR_SLASH_INTERVAL := 0.1

@export_group("Double Jump (Air)")
@export var AIR_JUMP_VELOCITY := 4.5 * 3.4 * (2.0 / 3.0)  # mesma força do pulo normal

@export_group("Glide (segurar espaço no ar, Air)")
@export var GLIDE_FALL_MULTIPLIER := 0.25

@export_group("Camera Shake")
@export var SHAKE_DECAY := 1.5
@export var SHAKE_MAX_OFFSET := 0.05  # ~3 degrees no trauma máximo (cai bem mais suave em traumas pequenos, por causa do trauma²)
@export var SHAKE_MAX_ROLL := 0.035  # ~2 degrees no trauma máximo
@export var SHAKE_CAST_TRAUMA := 0.12
@export var LANDING_SHAKE_TRAUMA := 1.0
@export var LEAP_LAUNCH_SHAKE_TRAUMA := 0.6

@export_group("Animation")
@export var ANIM_BLEND_TIME := 0.15
@export var MODEL_TURN_RATE := 10.0  # rad/s, giro do modelo pra encarar a direção que anda

@onready var nameplate: Label3D = %Nameplate
@onready var menu: Control = %Menu
@onready var button_resume: Button = %ButtonResume
@onready var button_pause_options: Button = %ButtonPauseOptions
@onready var button_disconnect: Button = %ButtonDisconnect
@onready var button_back_to_main_menu: Button = %ButtonBackToMainMenu
@onready var button_quit_desktop: Button = %ButtonQuitDesktop
@onready var button_fire: Button = %ButtonFire
@onready var button_earth: Button = %ButtonEarth
@onready var button_air: Button = %ButtonAir
@onready var controls_label: Label = %ControlsLabel
@onready var label_session: Label = %LabelSession
@onready var button_copy_session: Button = %ButtonCopySession
@onready var reticle: Panel = %Reticle
@onready var hit_marker: Label = %HitMarker
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var sound_hit: AudioStreamPlayer = %SoundHit
@onready var sound_ping: AudioStreamPlayer = %SoundPing
@onready var head: Node3D = $Head
@onready var camera_3d: Camera3D = %Camera3D
@onready var speed_trail: SpeedTrail = $SpeedTrail
@onready var trajectory_indicator: MultiMeshInstance3D = $TrajectoryIndicator
@onready var leap_indicator: Node3D = $LeapIndicator
@onready var player_mesh: Node3D = $Model
@onready var boulder_mesh: MeshInstance3D = $BoulderMesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer

var animation_fsm := PlayerAnimationFSM.new()
var _pause_options_menu: OptionsMenu

var player_element: int = ElementsEnum.Element.EARTH

var immobile := false
var yaw: float = 0.0
var pitch: float = 0.0

var time_moving := 0.0
var is_boosted := false
var base_fov := 90.0
var is_moving := false
var is_crouching := false

var is_boulder := false
var boulder_timer := 0.0
var boulder_distance_traveled := 0.0
var boulder_infused_with := -1
var _boulder_decal_timer := 0.0
var _boulder_roll_dir := Vector3.ZERO
var _boulder_time_expired := false
var _boulder_was_airborne := false

# Camera shake (trauma-based, like the common Godot "screen shake" recipe)
var shake_trauma := 0.0
var _shake_noise := FastNoiseLite.new()
var _shake_time := 0.0

# Abilities
var rock_sling_ability: RockSlingAbility
var fireball_ability: FireBallAbility
var earth_leap_ability: EarthLeapAbility

# Charging state
var is_charging_q := false
var is_charging_e := false
var is_charging_leap := false
var is_leaping := false

# LMB/RMB rock attacks
var lmb_wave_count := 0
var lmb_busy := false
var rmb_busy := false
var is_spiking := false

# Fire abilities
var is_flamethrowing := false
var fire_blast_busy := false
var is_fire_dashing := false
var fire_dash_timer := 0.0

# Air abilities
var air_dash_stacks := AIR_DASH_MAX_STACKS
var _air_dash_recharge_timer := 0.0
var air_dash_timer := 0.0
var is_slashing := false
var is_gliding := false
var cast_fov_kick := 0.0  # pulso de FOV ao soltar Wind Torrent/Tornado, decai sozinho de volta ao normal
var has_air_jump := true  # duplo pulo: 1 pulo extra no ar, recarrega ao pousar ou usar o air dash

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))

func _ready():
	menu.hide()
	add_to_group('Players')
	nameplate.text = name
	hit_marker.hide()

	# Aplica a tinta do elemento padrão localmente, pra QUALQUER peer que veja esse player
	# (incluindo os que não são a autoridade dele) já começar com a cor certa, não amarelo/padrão
	_apply_player_element(player_element)

	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		canvas_layer.hide()
		return

	if Global.username: nameplate.text = Global.username

	label_session.text = Network.tube_client.session_id
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	button_resume.pressed.connect(_close_pause_menu)
	button_pause_options.pressed.connect(_open_pause_options)
	button_disconnect.pressed.connect(func(): Network.leave_server())
	button_disconnect.disabled = not Network.is_networked
	button_back_to_main_menu.pressed.connect(func(): Network.leave_server())
	button_quit_desktop.pressed.connect(func(): get_tree().quit())

	_pause_options_menu = OptionsMenu.new()
	canvas_layer.add_child(_pause_options_menu)
	_pause_options_menu.closed.connect(func(): menu.show())

	button_copy_session.pressed.connect(func(): DisplayServer.clipboard_set(Network.tube_client.session_id))
	DisplayServer.clipboard_set(Network.tube_client.session_id)
	button_fire.pressed.connect(func(): _set_player_element(ElementsEnum.Element.FIRE))
	button_earth.pressed.connect(func(): _set_player_element(ElementsEnum.Element.EARTH))
	button_air.pressed.connect(func(): _set_player_element(ElementsEnum.Element.AIR))

	rock_sling_ability = RockSlingAbility.new()
	fireball_ability = FireBallAbility.new()
	earth_leap_ability = EarthLeapAbility.new()

	# Duplica o shape compartilhado da cena, senão agachar mudaria a altura de todo mundo
	collision_shape.shape = collision_shape.shape.duplicate()

	camera_3d.current = true
	base_fov = Settings.get_value("fov")
	controls_label.visible = Settings.get_value("show_controls")
	# Duplica o stylebox compartilhado do reticle, senão o modo alto contraste
	# de um player mudaria o reticle de todo mundo
	reticle.add_theme_stylebox_override("panel", reticle.get_theme_stylebox("panel").duplicate())
	_apply_reticle_contrast(Settings.get_value("high_contrast_reticle"))
	Settings.setting_changed.connect(_on_setting_changed)
	trajectory_indicator.hide()
	leap_indicator.hide()

	_shake_noise.seed = randi()
	_shake_noise.frequency = 3.0


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event is InputEventMouseMotion:
		var sensitivity: float = mouse_sensitivity * Settings.mouse_sensitivity_scale()
		yaw -= event.relative.x * sensitivity
		pitch -= event.relative.y * sensitivity * Settings.pitch_direction()
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
		rotation.y = yaw
		head.rotation.x = pitch

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			pass  # For future aiming


func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	_apply_camera_shake(delta)
	_apply_fov(delta)

	if Input.is_action_just_pressed('menu'):
		if _pause_options_menu.visible:
			_pause_options_menu.close()
		elif menu.visible:
			_close_pause_menu()
		else:
			_open_pause_menu()

	if immobile:
		return

	# Troca de elemento rápida: 1 = Terra, 2 = Fogo, 3 = Ar
	if Input.is_action_just_pressed('select_earth'):
		_set_player_element(ElementsEnum.Element.EARTH)

	if Input.is_action_just_pressed('select_fire'):
		_set_player_element(ElementsEnum.Element.FIRE)

	if Input.is_action_just_pressed('select_air'):
		_set_player_element(ElementsEnum.Element.AIR)

	# Abilities — cada uma se comporta diferente dependendo do elemento escolhido
	var is_earth = player_element == ElementsEnum.Element.EARTH
	var is_fire = player_element == ElementsEnum.Element.FIRE
	var is_air = player_element == ElementsEnum.Element.AIR

	# Q: Earth = rock sling (carrega e solta) / Fire = flamethrower (canaliza enquanto segura)
	if is_earth and Input.is_action_just_pressed('skill_q') and not is_charging_leap and not is_boulder:
		rock_sling_ability.start_charge()
		is_charging_q = true

	if is_earth and Input.is_action_just_released('skill_q') and is_charging_q:
		var charge = rock_sling_ability.get_charge_power()
		Global.cast_ability.rpc_id(1, "rock_sling", global_position, get_forward_direction(), charge)
		is_charging_q = false
		add_camera_shake(SHAKE_CAST_TRAUMA)

	if is_fire and Input.is_action_just_pressed('skill_q') and not is_flamethrowing:
		_channel_flamethrower()

	if is_air and Input.is_action_just_pressed('skill_q'):
		Global.cast_ability.rpc_id(1, "wind_torrent", global_position, get_forward_direction())
		_add_cast_fov_kick()

	# LMB: Earth = rajada rápida de pedras / Fire = bola de fogo (carrega e solta, como o E antigo) / Air = 3 air slashes
	if is_earth and Input.is_action_just_pressed('skill_lmb') and not lmb_busy and not is_boulder:
		_shoot_lmb()

	if is_fire and Input.is_action_just_pressed('skill_lmb'):
		fireball_ability.start_charge()
		is_charging_e = true

	if is_fire and Input.is_action_just_released('skill_lmb') and is_charging_e:
		var charge = fireball_ability.get_charge_power()
		Global.cast_ability.rpc_id(1, "fireball", global_position, get_forward_direction(), charge)
		is_charging_e = false

	if is_air and Input.is_action_just_pressed('skill_lmb') and not is_slashing:
		_shoot_air_slashes()

	# RMB: Earth = 2 pedras grandes / Fire = cone de fogo instantâneo / Air = deflete projéteis
	if is_earth and Input.is_action_just_pressed('skill_rmb') and not rmb_busy and not is_boulder:
		_shoot_rmb()

	if is_fire and Input.is_action_just_pressed('skill_rmb') and not rmb_busy:
		_shoot_cone()

	if is_air and Input.is_action_just_pressed('skill_rmb'):
		Global.cast_ability.rpc_id(1, "slash_of_air", global_position, get_forward_direction())

	# E: Earth = fileira de espinhos / Fire = explosão em área (fire blast) / Air = tornado em zigue-zague
	if is_earth and Input.is_action_just_pressed('skill_e') and not is_boulder and not is_spiking:
		_shoot_earth_spikes()

	if is_fire and Input.is_action_just_pressed('skill_e') and not fire_blast_busy:
		_shoot_blast()

	if is_air and Input.is_action_just_pressed('skill_e'):
		Global.cast_ability.rpc_id(1, "tornado", global_position, get_forward_direction())
		_add_cast_fov_kick()

	# Earth Leap: só carrega se o jogador estiver parado (e fica preso no lugar enquanto carrega).
	# Andando, ou durante o Boulder Dash, espaço só faz o pulo normal.
	if Input.is_action_just_pressed('jump') and is_on_floor():
		if is_earth and not is_boulder and not is_charging_q and not is_moving:
			earth_leap_ability.start_charge()
			is_charging_leap = true
		else:
			velocity.y = JUMP_VELOCITY

	# Duplo pulo (Air): 1 pulo extra no ar, só recarrega ao pousar ou usar o Air Dash
	if is_air and Input.is_action_just_pressed('jump') and not is_on_floor() and has_air_jump:
		has_air_jump = false
		velocity.y = AIR_JUMP_VELOCITY

	if Input.is_action_just_released('jump') and is_charging_leap:
		_release_earth_leap()
		is_charging_leap = false

	# Shift: Earth = Boulder Dash / Fire = corrida com chamas / Air = dash omnidirecional (3 stacks)
	if is_earth and Input.is_action_just_pressed('skill_shift') and not is_charging_q and not is_charging_leap:
		if is_boulder:
			_end_boulder_dash()
		else:
			_start_boulder_dash()

	if is_fire and Input.is_action_just_pressed('skill_shift') and not is_fire_dashing:
		_start_fire_dash()

	if is_air and Input.is_action_just_pressed('skill_shift') and air_dash_stacks > 0:
		_air_dash()

	# Ctrl no ar: mini dash instantâneo pra baixo (funciona durante o Boulder Dash e o planar do Air)
	if Input.is_action_just_pressed('crouch') and not is_on_floor():
		velocity.y = min(velocity.y, -CTRL_AIR_DASH_DOWN_SPEED)

	if is_charging_q:
		_update_rock_sling_trajectory()
	else:
		trajectory_indicator.hide()

	if is_charging_leap:
		_update_leap_indicator()
	else:
		leap_indicator.hide()


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	# Gravity — na queda do Earth Leap, cai mais rápido pra bater com força no chão.
	# No Air, segurar espaço no ar plana (cai bem mais devagar).
	var is_air = player_element == ElementsEnum.Element.AIR
	var should_glide = is_air and not is_on_floor() and Input.is_action_pressed('jump') and velocity.y < 0.0

	if not is_on_floor():
		var gravity_multiplier = 1.0
		if is_leaping and velocity.y < 0.0:
			gravity_multiplier = EARTH_LEAP_FALL_ACCEL_MULTIPLIER
		elif should_glide:
			gravity_multiplier = GLIDE_FALL_MULTIPLIER
		elif Input.is_action_pressed('crouch') and velocity.y < 0.0:
			gravity_multiplier = CROUCH_FALL_MULTIPLIER
		velocity += get_gravity() * gravity_multiplier * delta

	if should_glide != is_gliding:
		is_gliding = should_glide
		_set_glide_visual.rpc(is_gliding)

	# Duplo pulo (Air): recarrega ao tocar o chão
	if is_air and is_on_floor():
		has_air_jump = true

	# Recarrega 1 stack do Air Dash por vez, até o máximo
	if is_air and air_dash_stacks < AIR_DASH_MAX_STACKS:
		_air_dash_recharge_timer += delta
		if _air_dash_recharge_timer >= AIR_DASH_RECHARGE_TIME:
			_air_dash_recharge_timer = 0.0
			air_dash_stacks += 1

	# Agachar: só faz sentido parado no chão, não durante o dash de pedra
	is_crouching = Input.is_action_pressed('crouch') and not is_boulder
	_update_crouch(delta)

	# Movement
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	is_moving = direction != Vector3.ZERO

	# Speed boost: só acumula enquanto anda, e cai na hora se parar
	if is_moving:
		time_moving += delta
		if not is_boosted and time_moving >= BOOST_DELAY:
			_set_boosted(true)
	else:
		time_moving = 0.0
		if is_boosted:
			_set_boosted(false)

	# Boulder Dash: dura um tempo limitado. Se o tempo acabar no ar, só destransforma ao pousar;
	# o pouso em si cria um decal de impacto maior.
	if is_boulder:
		boulder_timer += delta

		if boulder_timer >= BOULDER_DURATION:
			_boulder_time_expired = true

		if not is_on_floor():
			_boulder_was_airborne = true
		elif _boulder_was_airborne:
			_boulder_was_airborne = false
			add_camera_shake(LANDING_SHAKE_TRAUMA)
			var impact_scale = (BOULDER_RADIUS * _current_boulder_scale() * 2.0) / DECAL_BASE_RADIUS
			Global.spawn_boulder_decal.rpc_id(1, global_position, boulder_infused_with, impact_scale)

		if _boulder_time_expired and is_on_floor():
			_end_boulder_dash()

	# Fire Dash: velocidade dobrada por um tempo fixo
	if is_fire_dashing:
		fire_dash_timer += delta
		if fire_dash_timer >= FIRE_DASH_DURATION:
			_end_fire_dash()

	var current_speed = SPEED
	if is_boulder:
		# Acelera conforme a bola cresce/rola (mesmo progresso usado no crescimento visual)
		current_speed = SPEED * lerp(BOULDER_MIN_SPEED_MULTIPLIER, BOULDER_SPEED_MULTIPLIER, _boulder_progress())
	elif is_fire_dashing:
		current_speed = SPEED * FIRE_DASH_MULTIPLIER
	elif is_crouching:
		current_speed = SPEED * CROUCH_SPEED_MULTIPLIER
	elif is_boosted:
		current_speed = SPEED * BOOST_MULTIPLIER

	if air_dash_timer > 0.0:
		# Deixa o impulso do Air Dash valer, sem o movimento normal sobrescrever a velocidade
		air_dash_timer -= delta
	elif is_charging_leap:
		# Preso no lugar enquanto carrega o Earth Leap
		velocity.x = 0.0
		velocity.z = 0.0
	elif is_boulder:
		_apply_boulder_movement(direction, current_speed, delta)
	elif direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	# Finite state machine de animação (idle/andar/correr/pular/agachar)
	var horizontal_speed = Vector3(velocity.x, 0, velocity.z).length()
	var next_anim = animation_fsm.update(delta, is_on_floor(), horizontal_speed, is_crouching)
	if next_anim != "":
		_play_animation.rpc(next_anim)

	if is_boulder:
		_apply_boulder_roll(delta)

		# Cresce conforme a distância REALMENTE percorrida — parado, não cresce
		var boulder_speed = Vector3(velocity.x, 0, velocity.z).length()
		var boulder_actually_moving = boulder_speed > 0.1 and is_on_floor()
		if boulder_actually_moving:
			boulder_distance_traveled += boulder_speed * delta
		boulder_mesh.scale = Vector3.ONE * _current_boulder_scale()

		if boulder_actually_moving:
			_boulder_decal_timer += delta
			if _boulder_decal_timer >= BOULDER_DECAL_INTERVAL:
				_boulder_decal_timer = 0.0
				var decal_scale = (BOULDER_RADIUS * _current_boulder_scale()) / DECAL_BASE_RADIUS
				Global.spawn_boulder_decal.rpc_id(1, global_position, boulder_infused_with, decal_scale)
	elif not is_charging_leap:
		_update_model_facing(direction, delta)

	# Landing do Earth Leap: só conta quando já está descendo, pra não disparar no frame do salto
	if is_leaping and is_on_floor() and velocity.y <= 0.1:
		is_leaping = false
		add_camera_shake(LANDING_SHAKE_TRAUMA)
		Global.spawn_earth_leap_decal.rpc_id(1, global_position)


func _apply_boulder_movement(direction: Vector3, current_speed: float, delta: float) -> void:
	# Sem input, o boulder continua rolando pra onde a câmera olha (nunca fica parado).
	# Com input, o input sempre manda.
	var target_dir = direction if direction.length() > 0.01 else _get_horizontal_forward()

	if _boulder_roll_dir.length() < 0.01:
		_boulder_roll_dir = target_dir
	else:
		var angle_to_target = _boulder_roll_dir.signed_angle_to(target_dir, Vector3.UP)
		var max_step = BOULDER_TURN_RATE * delta
		var step = clamp(angle_to_target, -max_step, max_step)
		_boulder_roll_dir = _boulder_roll_dir.rotated(Vector3.UP, step).normalized()

	velocity.x = _boulder_roll_dir.x * current_speed
	velocity.z = _boulder_roll_dir.z * current_speed


func _update_model_facing(direction: Vector3, delta: float) -> void:
	# Se não tá andando, trava olhando pra última direção (não volta a encarar a câmera)
	if direction.length() < 0.01:
		return

	var target_basis = Transform3D().looking_at(direction, Vector3.UP).basis
	# O rig do Mannequin encara o eixo oposto ao padrão do Godot (-Z), então compensa 180°
	target_basis = target_basis.rotated(Vector3.UP, PI)
	var current_quat = player_mesh.global_transform.basis.get_rotation_quaternion()
	var target_quat = target_basis.get_rotation_quaternion()
	var new_quat = current_quat.slerp(target_quat, clamp(MODEL_TURN_RATE * delta, 0.0, 1.0))

	var gt = player_mesh.global_transform
	gt.basis = Basis(new_quat)
	player_mesh.global_transform = gt


func _apply_boulder_roll(delta: float) -> void:
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	var speed = horizontal_velocity.length()
	if speed < 0.01:
		return

	var roll_axis = horizontal_velocity.normalized().cross(Vector3.UP)
	var angular_speed = speed / (BOULDER_RADIUS * _current_boulder_scale())
	boulder_mesh.global_rotate(roll_axis, angular_speed * delta)


func _boulder_progress() -> float:
	return clamp(boulder_distance_traveled / BOULDER_GROW_DISTANCE, 0.0, 1.0)


func _current_boulder_scale() -> float:
	return lerp(BOULDER_START_SCALE, 1.0, _boulder_progress())


func _set_player_element(elem: int) -> void:
	_apply_player_element.rpc(elem)


func _open_pause_menu() -> void:
	menu.show()
	immobile = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _close_pause_menu() -> void:
	menu.hide()
	_pause_options_menu.hide()
	immobile = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _open_pause_options() -> void:
	menu.hide()
	_pause_options_menu.open()


@rpc("any_peer", "call_local")
func _apply_player_element(elem: int) -> void:
	player_element = elem

	var tint: Color
	match elem:
		ElementsEnum.Element.FIRE:
			tint = Color(0.9, 0.2, 0.15)
		ElementsEnum.Element.AIR:
			tint = Color(0.92, 0.95, 0.98)
		_:
			tint = Color(0.45, 0.3, 0.15)  # EARTH

	_tint_model_recursive(player_mesh, tint)

	# O texto de controles é só do próprio jogador (CanvasLayer já é escondido de todo mundo
	# que não é a autoridade), então atualizar em todo mundo aqui não vaza nada.
	_update_controls_label(elem)


func _update_controls_label(elem: int) -> void:
	match elem:
		ElementsEnum.Element.FIRE:
			controls_label.text = "FIRE\nQ: Flamethrower (segure)\nE: Fire Blast (área)\nLMB: Fireball (carregue e solte)\nRMB: Fire Cone\nSHIFT: Fire Dash (2x veloc., 5s)\nSPACE: Pulo"
		ElementsEnum.Element.AIR:
			controls_label.text = "AIR\nQ: Wind Torrent (empurra objetos)\nE: Tornado (zigue-zague)\nLMB: 3 Air Slashes\nRMB: Slash of Air (deflete)\nSHIFT: Air Dash (3 cargas, 5s cada)\nSPACE: Pulo / Duplo Pulo / Planar (segure no ar)"
		_:
			controls_label.text = "EARTH\nQ: Rock Sling (carregue e solte)\nE: Earth Spikes (fileira)\nLMB: Rock Barrage\nRMB: 2 Rochas Grandes\nSHIFT: Boulder Dash\nSPACE: Pulo / Earth Leap (segure parado)"


func _tint_model_recursive(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		var existing_material = node.get_active_material(0)
		var material = existing_material.duplicate() if existing_material else StandardMaterial3D.new()
		if material is StandardMaterial3D:
			material.albedo_color = tint
			node.set_surface_override_material(0, material)

	for child in node.get_children():
		_tint_model_recursive(child, tint)


# LMB: 2 tiros rápidos por clique. Depois de 3 "waves" (6 tiros), o próximo clique
# solta 1 pedra maior e recarrega.
func _shoot_lmb() -> void:
	lmb_busy = true

	if lmb_wave_count < LMB_WAVES_BEFORE_BIG:
		lmb_wave_count += 1

		_play_animation.rpc("Punch_Jab")
		Global.cast_ability.rpc_id(1, "rock_barrage_small", global_position, get_forward_direction())
		await get_tree().create_timer(LMB_SHOT_INTERVAL).timeout

		_play_animation.rpc("Punch_Cross")
		Global.cast_ability.rpc_id(1, "rock_barrage_small", global_position, get_forward_direction())

		lmb_busy = false
	else:
		lmb_wave_count = 0

		_play_animation.rpc("Sword_Attack")
		Global.cast_ability.rpc_id(1, "rock_barrage_big", global_position, get_forward_direction())
		await get_tree().create_timer(0.3).timeout

		_play_animation.rpc("Pistol_Reload")
		await get_tree().create_timer(LMB_RELOAD_TIME).timeout

		lmb_busy = false


# RMB: 2 projéteis grandes por clique, depois recarrega.
func _shoot_rmb() -> void:
	rmb_busy = true

	_play_animation.rpc("Pistol_Shoot")
	Global.cast_ability.rpc_id(1, "rock_barrage_big", global_position, get_forward_direction())
	await get_tree().create_timer(RMB_SHOT_INTERVAL).timeout

	_play_animation.rpc("Pistol_Shoot")
	Global.cast_ability.rpc_id(1, "rock_barrage_big", global_position, get_forward_direction())
	await get_tree().create_timer(0.2).timeout

	_play_animation.rpc("Pistol_Reload")
	await get_tree().create_timer(RMB_RELOAD_TIME).timeout

	rmb_busy = false


# Earth E: fileira de até 6 espinhos, um surgindo depois do outro, se afastando do jogador.
func _shoot_earth_spikes() -> void:
	is_spiking = true

	for i in range(SPIKE_COUNT):
		Global.cast_ability.rpc_id(1, "earth_spike", global_position, get_forward_direction(), float(i))
		await get_tree().create_timer(SPIKE_INTERVAL).timeout

	is_spiking = false


func _update_crouch(_delta: float) -> void:
	# Agachar só encolhe a colisão (pra passar em vãos baixos); a câmera não abaixa
	var target_height = CROUCH_HEIGHT if is_crouching else STAND_HEIGHT
	var capsule = collision_shape.shape as CapsuleShape3D
	capsule.height = target_height
	collision_shape.position.y = target_height / 2.0


@rpc("any_peer", "call_local")
func _play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name, ANIM_BLEND_TIME)


func get_forward_direction() -> Vector3:
	return -camera_3d.global_transform.basis.z


func take_damage(_amount = 0, _source_peer_id: int = -1, element: int = -1) -> void:
	# Chamado diretamente pelo servidor (autoridade do projétil), então não dá
	# pra confiar em is_multiplayer_authority() aqui — precisa de RPC pro dono real ver o efeito
	_apply_damage_effects.rpc_id(int(name), element)


@rpc("any_peer", "call_local")
func _apply_damage_effects(element: int) -> void:
	time_moving = 0.0
	if is_boosted:
		_set_boosted(false)

	if is_boulder and boulder_infused_with == -1 and element == ElementsEnum.Element.FIRE:
		ignite_boulder.rpc()


func _set_boosted(value: bool) -> void:
	is_boosted = value
	speed_trail.emitting = value


func _apply_fov(delta: float) -> void:
	var target_fov = base_fov
	var lerp_speed = FOV_LERP_SPEED

	if air_dash_timer > 0.0:
		# Sobe rápido durante o dash; ao acabar, volta no ritmo normal
		target_fov = base_fov + AIR_DASH_FOV_INCREASE
		lerp_speed = AIR_DASH_FOV_LERP_SPEED
	elif is_boulder and is_moving:
		target_fov = base_fov + BOULDER_FOV_INCREASE
	elif is_boosted:
		target_fov = base_fov + BOOST_FOV_INCREASE

	cast_fov_kick = max(0.0, cast_fov_kick - CAST_FOV_KICK_DECAY * delta)
	target_fov += cast_fov_kick

	camera_3d.fov = lerp(camera_3d.fov, target_fov, lerp_speed * delta)


func _add_cast_fov_kick() -> void:
	cast_fov_kick = CAST_FOV_KICK_AMOUNT


func _start_boulder_dash() -> void:
	is_boulder = true
	boulder_timer = 0.0
	boulder_distance_traveled = 0.0
	boulder_infused_with = -1
	_boulder_decal_timer = 0.0
	_boulder_time_expired = false
	_boulder_was_airborne = false
	_boulder_roll_dir = _get_horizontal_forward()
	boulder_mesh.scale = Vector3.ONE * BOULDER_START_SCALE
	_set_boulder_visual.rpc(true)


func _end_boulder_dash() -> void:
	is_boulder = false
	_set_boulder_visual.rpc(false)


@rpc("any_peer", "call_local")
func _set_boulder_visual(active: bool) -> void:
	player_mesh.visible = not active
	boulder_mesh.visible = active
	if not active:
		boulder_mesh.scale = Vector3.ONE
		boulder_mesh.set_surface_override_material(0, null)
		for child in boulder_mesh.get_children():
			child.queue_free()


func _start_fire_dash() -> void:
	is_fire_dashing = true
	fire_dash_timer = 0.0
	_set_fire_dash_visual.rpc(true)


func _end_fire_dash() -> void:
	is_fire_dashing = false
	_set_fire_dash_visual.rpc(false)


@rpc("any_peer", "call_local")
func _set_fire_dash_visual(active: bool) -> void:
	if active:
		if not player_mesh.has_node("FireDashParticles"):
			var fire_particles = preload("res://Scenes/Effects/fire_particles.tscn")
			var particles_instance = fire_particles.instantiate()
			particles_instance.name = "FireDashParticles"
			player_mesh.add_child(particles_instance)
	elif player_mesh.has_node("FireDashParticles"):
		player_mesh.get_node("FireDashParticles").queue_free()


# Q (Fire): canaliza um jato de fogo contínuo por até 4s, ou até soltar a tecla antes.
func _channel_flamethrower() -> void:
	is_flamethrowing = true
	var elapsed := 0.0

	while elapsed < FLAMETHROWER_DURATION and Input.is_action_pressed('skill_q') and player_element == ElementsEnum.Element.FIRE:
		Global.cast_ability.rpc_id(1, "flame_tick", global_position, get_forward_direction())
		await get_tree().create_timer(FLAMETHROWER_TICK_INTERVAL).timeout
		elapsed += FLAMETHROWER_TICK_INTERVAL

	is_flamethrowing = false


# RMB (Fire): cone de fogo instantâneo na frente do jogador, depois recarrega.
func _shoot_cone() -> void:
	rmb_busy = true

	_play_animation.rpc("Pistol_Shoot")
	Global.cast_ability.rpc_id(1, "fire_cone", global_position, get_forward_direction())
	await get_tree().create_timer(RMB_RELOAD_TIME).timeout

	rmb_busy = false


# E (Fire): explosão em área centrada no jogador (fire blast).
func _shoot_blast() -> void:
	fire_blast_busy = true

	Global.cast_ability.rpc_id(1, "fire_blast", global_position, get_forward_direction())
	await get_tree().create_timer(2.0).timeout

	fire_blast_busy = false


# Shift (Air): dash omnidirecional instantâneo, consome 1 dos 3 stacks (cada um recarrega em 5s).
func _air_dash() -> void:
	air_dash_stacks -= 1
	has_air_jump = true  # air dash devolve o pulo extra do duplo pulo

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var dash_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if dash_dir.length() < 0.01:
		dash_dir = get_forward_direction()  # nenhuma direção segurada: dash pra frente (duplo pulo já cobre o "pra cima")

	velocity.x = dash_dir.x * AIR_DASH_SPEED
	velocity.z = dash_dir.z * AIR_DASH_SPEED
	velocity.y = max(velocity.y, dash_dir.y * AIR_DASH_SPEED * 0.5)
	air_dash_timer = AIR_DASH_DURATION

	Global.cast_ability.rpc_id(1, "air_dash_burst", global_position, dash_dir)


# LMB (Air): 3 cortes de ar saindo de trás do jogador, cortando pra frente.
func _shoot_air_slashes() -> void:
	is_slashing = true

	for i in range(AIR_SLASH_COUNT):
		Global.cast_ability.rpc_id(1, "air_slash", global_position, get_forward_direction())
		await get_tree().create_timer(AIR_SLASH_INTERVAL).timeout

	is_slashing = false


@rpc("any_peer", "call_local")
func _set_glide_visual(active: bool) -> void:
	if active:
		if not player_mesh.has_node("GlideParticles"):
			var glide_particles = preload("res://Scenes/Effects/glide_particles.tscn")
			var particles_instance = glide_particles.instantiate()
			particles_instance.name = "GlideParticles"
			player_mesh.add_child(particles_instance)
	elif player_mesh.has_node("GlideParticles"):
		player_mesh.get_node("GlideParticles").queue_free()


@rpc("any_peer", "call_local")
func ignite_boulder() -> void:
	boulder_infused_with = ElementsEnum.Element.FIRE

	var shader = load("res://Shaders/lava_ignite.gdshader")
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("dark_lava_color", Color(0.15, 0.02, 0.0))
	material.set_shader_parameter("light_lava_color", Color(1.0, 0.45, 0.05))
	material.set_shader_parameter("speed", 1.2)
	material.set_shader_parameter("scale", 8.0)
	material.set_shader_parameter("sharpness", 20.0)
	material.set_shader_parameter("emission_intensity", 3.0)
	boulder_mesh.set_surface_override_material(0, material)

	var fire_particles = preload("res://Scenes/Effects/fire_particles.tscn")
	var particles_instance = fire_particles.instantiate()
	boulder_mesh.add_child(particles_instance)


func _update_rock_sling_trajectory() -> void:
	var spawn_pos = global_position + Vector3(0, 0.5, 0)
	var dir = get_forward_direction()
	var charge_power = rock_sling_ability.get_charge_power()
	spawn_pos += dir * (1.5 * charge_power)

	var launch_velocity = dir * (10.0 * charge_power / 3.0)
	launch_velocity.y += (10.0 * charge_power) / 3.0

	_show_trajectory_preview(spawn_pos, launch_velocity)


func _get_leap_launch_velocity() -> Vector3:
	var charge_power = earth_leap_ability.get_charge_power()
	var horizontal_dir = _get_horizontal_forward()

	# Salto majoritariamente vertical, só levemente inclinado na direção da câmera
	var vertical_speed = EARTH_LEAP_VERTICAL * charge_power
	var horizontal_speed = vertical_speed * tan(deg_to_rad(EARTH_LEAP_TILT_DEGREES))

	var launch_velocity = horizontal_dir * horizontal_speed
	launch_velocity.y = vertical_speed
	return launch_velocity


func _get_horizontal_forward() -> Vector3:
	var dir = get_forward_direction()
	var horizontal_dir = Vector3(dir.x, 0, dir.z)
	return horizontal_dir.normalized() if horizontal_dir.length() > 0.001 else -transform.basis.z


func _update_leap_indicator() -> void:
	# Só mostra o indicador depois que passar do threshold de "toque rápido",
	# senão ele piscaria a cada pulo normal
	if earth_leap_ability.get_hold_duration() < EarthLeapAbility.TAP_THRESHOLD:
		leap_indicator.hide()
		return

	leap_indicator.scale.y = earth_leap_ability.get_charge_power()
	leap_indicator.show()


func _release_earth_leap() -> void:
	if earth_leap_ability.is_tap():
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		earth_leap_ability.end_charge()
		return

	velocity = _get_leap_launch_velocity()
	is_leaping = true
	add_camera_shake(LEAP_LAUNCH_SHAKE_TRAUMA)
	earth_leap_ability.end_charge()


func _show_trajectory_preview(spawn_pos: Vector3, launch_velocity: Vector3) -> void:
	var gravity = get_gravity()

	var multimesh = trajectory_indicator.multimesh
	for i in range(TRAJECTORY_POINTS):
		var t = i * TRAJECTORY_TIME_STEP
		var point = spawn_pos + launch_velocity * t + 0.5 * gravity * t * t
		var local_point = trajectory_indicator.to_local(point)
		multimesh.set_instance_transform(i, Transform3D(Basis(), local_point))

	trajectory_indicator.show()


func add_camera_shake(amount: float) -> void:
	shake_trauma = min(shake_trauma + amount * Settings.camera_shake_scale(), 1.0)


func _apply_reticle_contrast(enabled: bool) -> void:
	var style: StyleBoxFlat = reticle.get_theme_stylebox("panel")
	if enabled:
		style.bg_color = Color.BLACK
		style.border_color = Color.WHITE
		style.set_border_width_all(2)
	else:
		style.bg_color = Color.WHITE
		style.set_border_width_all(0)


func _on_setting_changed(key: String, value: Variant) -> void:
	if key == "fov":
		base_fov = value
	elif key == "show_controls":
		controls_label.visible = value
	elif key == "high_contrast_reticle":
		_apply_reticle_contrast(value)


func _apply_camera_shake(delta: float) -> void:
	if shake_trauma > 0.0:
		shake_trauma = max(shake_trauma - SHAKE_DECAY * delta, 0.0)

	var amount = shake_trauma * shake_trauma  # trauma² feels more natural than a linear falloff
	_shake_time += delta * 20.0

	if amount <= 0.0:
		camera_3d.rotation = Vector3.ZERO
		return

	var pitch_offset = SHAKE_MAX_OFFSET * amount * _shake_noise.get_noise_2d(_shake_time, 0.0)
	var yaw_offset = SHAKE_MAX_OFFSET * amount * _shake_noise.get_noise_2d(_shake_time, 100.0)
	var roll_offset = SHAKE_MAX_ROLL * amount * _shake_noise.get_noise_2d(_shake_time, 200.0)
	camera_3d.rotation = Vector3(pitch_offset, yaw_offset, roll_offset)


@rpc("any_peer", "call_local")
func trigger_camera_shake(amount: float) -> void:
	add_camera_shake(amount)


@rpc("any_peer", "call_local")
func register_hit(is_dead = false):
	if is_dead:
		sound_ping.play()
	else:
		sound_hit.play()

	hit_marker.show()
	await get_tree().create_timer(0.2).timeout
	hit_marker.hide()
