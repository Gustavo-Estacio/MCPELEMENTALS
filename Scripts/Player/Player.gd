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
@export var ROLL_ANIM_SPEED_MULTIPLIER := 2.0  # o mini pulinho antes do Boulder Dash é curto, o Roll precisa tocar mais rápido pra caber
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

@export_group("Punch Combo (LMB Earth)")
@export var LMB_SHOT_INTERVAL := 0.12

@export_group("Rock Barrage (RMB Earth)")
@export var RMB_SHOT_INTERVAL := 0.15
@export var RMB_RELOAD_TIME := 2.0

const LMB_COMBO_ANIMATIONS := ["Jab", "Hook", "Uppercut"]

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

@export_group("Torso Aim (torso sempre de costas pra câmera, pés livres)")
@export var TORSO_YAW_MAX_DEGREES := 75.0
@export var TORSO_TWIST_LERP_SPEED := 12.0
@export var TORSO_DEBUG := false  # imprime no console o osso escolhido + os ângulos, pra diagnosticar

@export_group("Model Facing (cada rig tem sua própria convenção de eixo 'frente')")
@export var MANNEQUIN_FACING_FLIP_DEGREES := 180.0  # rig encara +Z, precisa desse flip pra bater com a direção do movimento
@export var GOLEM_FACING_FLIP_DEGREES := 180.0  # rig encara -Y no Blender, mas de frente (ver memory golem-rig-source) — precisa do flip pra ficar de costas pra câmera igual o Mannequin

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
@onready var button_golem: Button = %ButtonGolem
@onready var button_element_earth: Button = %ButtonElementEarth
@onready var button_element_fire: Button = %ButtonElementFire
@onready var button_element_air: Button = %ButtonElementAir

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
@onready var mannequin_mesh: Node3D = $Model
@onready var golem_mesh: Node3D = $GolemModel
@onready var boulder_mesh: MeshInstance3D = $BoulderMesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mannequin_animation_player: AnimationPlayer = $Model/AnimationPlayer

# Modelo/animation player/skeleton "ativos" — trocam de alvo quando o elemento GOLEM
# é selecionado (botão 4), reaproveitando o mesmo código de facing/tint/animação
# que já existe pro Mannequin, só apontando pro rig do golem enquanto ele estiver ativo.
var player_mesh: Node3D
var animation_player: AnimationPlayer
var golem_animation_player: AnimationPlayer
var _golem_foliage_meshes: Array[MeshInstance3D] = []  # Leaves_*/Moss_*: escondidas só durante o Roll, ver _reset_golem_foliage

var _mannequin_skeleton: Skeleton3D
var _mannequin_torso_bone_idx := -1
var _golem_skeleton: Skeleton3D
var _golem_torso_bone_idx := -1

var animation_fsm := PlayerAnimationFSM.new()
var _pause_options_menu: OptionsMenu

# Stats (vida, dano, área, etc.) — ver Scripts/Core/player_stats.gd. Por enquanto
# só são exibidos no painel ao segurar TAB, ainda não afetam dano/movimento/etc.
var stats := PlayerStats.new()
var _stats_panel: StatsPanel
var _spell_slot_bar: SpellSlotBar
var _tab_held := false

# TAB: troca a ordem das spells Q/E ao arrastar um slot em cima do outro na
# SpellSlotBar. Isso NÃO muda o keybind físico, só qual spell cada tecla conjura.
var spell_slots_swapped := false

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
var _is_boulder_dash_launching := false  # mini pulinho antes do Boulder Dash de fato começar
var _boulder_launch_initial_vy := 0.0
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
var _base_camera_rotation := Vector3.ZERO

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

# Jump animation tracking
var _jump_start_height := 0.0
var _last_jump_animation := ""  # qual animação de pulo estava tocando
var _is_in_jump_ascent := false

# Torso aim: torce os ossos da espinha pra encarar a mira (root/câmera), independente
# de pra onde o Model (pernas) gira pra seguir o movimento
var _skeleton: Skeleton3D
var _torso_bone_idx := -1
var _torso_twist_yaw := 0.0
var _torso_debug_timer := 0.0

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))

func _ready():
	menu.hide()
	add_to_group('Players')
	nameplate.text = name
	hit_marker.hide()

	# Descobre skeleton/osso de torso/AnimationPlayer de CADA modelo (Mannequin e Golem)
	# uma vez só, no boot. O golem não tem osso "spine" (rig próprio: Head/Chest/Hip/...),
	# então seu torso-aim simplesmente fica desativado (_golem_torso_bone_idx == -1) — não
	# tiver osso compatível, não tenta torcer nada.
	_mannequin_skeleton = _find_skeleton(mannequin_mesh)
	if _mannequin_skeleton:
		_mannequin_torso_bone_idx = _find_torso_bone(_mannequin_skeleton)

	golem_animation_player = _find_animation_player(golem_mesh)
	_golem_skeleton = _find_skeleton(golem_mesh)
	if _golem_skeleton:
		_golem_torso_bone_idx = _find_torso_bone(_golem_skeleton)
	_find_golem_foliage_meshes(golem_mesh, _golem_foliage_meshes)

	# Aplica a tinta/modelo/animação do elemento padrão localmente, pra QUALQUER peer que
	# veja esse player (incluindo os que não são a autoridade dele) já começar certo
	_apply_player_element(player_element)

	# Torso aim precisa rodar pra QUALQUER peer (todo mundo vê o torso dos outros players
	# torcendo), então conecta antes do "return" de autoridade abaixo.
	# Só UM osso (o mais alto da espinha, perto do peito/ombros): torcer os 3 em cadeia
	# faz cada um girar no espaço já rotacionado do pai anterior, virando um "saca-rolha"
	# que distorce braços/pernas — um osso só dá a torção limpa do peito, sem esse efeito.
	# O advance manual é sempre no AnimationPlayer do Mannequin: é o único rig com torso aim,
	# o golem toca suas próprias animações no modo automático normal do Godot.
	if _mannequin_torso_bone_idx != -1:
		# Controle manual: o AnimationPlayer só escreve os ossos quando A GENTE manda (advance()),
		# nunca mais sozinho num momento indeterminado do frame. Assim o twist do torso, chamado
		# logo em seguida na MESMA função, é sempre a última coisa a escrever o osso — sem essa
		# garantia, a animação vencia a corrida na maioria dos frames e só "revelava" o twist
		# quando a pose ficava parada (por isso só virava no fim da animação).
		mannequin_animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		get_tree().process_frame.connect(_advance_animation_and_torso)
	else:
		push_warning("Torso aim desativado: skeleton=%s, nenhum osso 'spine' encontrado." % _mannequin_skeleton)

	if TORSO_DEBUG and _skeleton:
		var bone_names := []
		for i in range(_skeleton.get_bone_count()):
			bone_names.append("%d:%s" % [i, _skeleton.get_bone_name(i)])
		var chosen = _skeleton.get_bone_name(_torso_bone_idx) if _torso_bone_idx != -1 else "NENHUM"
		print("[TorsoAim] skeleton=%s | osso escolhido=%s" % [_skeleton.name, chosen])
		print("[TorsoAim] ossos: %s" % ", ".join(bone_names))

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
	button_golem.pressed.connect(func(): _set_player_element(ElementsEnum.Element.GOLEM))

	button_element_fire.pressed.connect(func(): _set_player_element(ElementsEnum.Element.FIRE))
	button_element_earth.pressed.connect(func(): _set_player_element(ElementsEnum.Element.EARTH))
	button_element_air.pressed.connect(func(): _set_player_element(ElementsEnum.Element.AIR))

	rock_sling_ability = RockSlingAbility.new()
	fireball_ability = FireBallAbility.new()
	earth_leap_ability = EarthLeapAbility.new()

	# Duplica o shape compartilhado da cena, senão agachar mudaria a altura de todo mundo
	collision_shape.shape = collision_shape.shape.duplicate()

	camera_3d.current = true
	base_fov = camera_3d.fov
	_base_camera_rotation = camera_3d.rotation
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

	_stats_panel = StatsPanel.new()
	canvas_layer.add_child(_stats_panel)
	_stats_panel.setup(stats)

	_spell_slot_bar = SpellSlotBar.new()
	_spell_slot_bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_spell_slot_bar.offset_left = -170.0
	_spell_slot_bar.offset_top = -100.0
	_spell_slot_bar.offset_right = -20.0
	_spell_slot_bar.offset_bottom = -20.0
	canvas_layer.add_child(_spell_slot_bar)
	_spell_slot_bar.setup(self)


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event is InputEventMouseMotion and not _tab_held:
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

	# TAB: libera o mouse pra arrastar as spells Q/E entre os slots e mostra o
	# painel de stats à direita, enquanto segurado. Some/recaptura o mouse ao soltar.
	if not menu.visible and not _pause_options_menu.visible:
		if Input.is_action_just_pressed('hud_overlay'):
			_tab_held = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			_stats_panel.show()
			_spell_slot_bar.show()
		elif Input.is_action_just_released('hud_overlay'):
			_tab_held = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			_stats_panel.hide()
			_spell_slot_bar.hide()

	if immobile:
		return

	# Troca de elemento rápida: 1 = Terra, 2 = Fogo, 3 = Ar
	if Input.is_action_just_pressed('select_earth'):
		_set_player_element(ElementsEnum.Element.EARTH)

	if Input.is_action_just_pressed('select_fire'):
		_set_player_element(ElementsEnum.Element.FIRE)

	if Input.is_action_just_pressed('select_air'):
		_set_player_element(ElementsEnum.Element.AIR)

	# Abilities — cada uma se comporta diferente dependendo do elemento escolhido.
	# GOLEM joga IGUAL a EARTH (mesmas habilidades); só muda o modelo/animação.
	var is_earth = player_element == ElementsEnum.Element.EARTH or player_element == ElementsEnum.Element.GOLEM
	var is_fire = player_element == ElementsEnum.Element.FIRE
	var is_air = player_element == ElementsEnum.Element.AIR

	# Q: Earth = rock sling (carrega e solta) / Fire = flamethrower (canaliza enquanto segura)
	if is_earth and Input.is_action_just_pressed(_q_action()) and not is_charging_leap and not is_boulder:
		rock_sling_ability.start_charge()
		is_charging_q = true

	if is_earth and Input.is_action_just_released(_q_action()) and is_charging_q:
		var charge = rock_sling_ability.get_charge_power()
		Global.cast_ability.rpc_id(1, "rock_sling", global_position, get_forward_direction(), charge)
		is_charging_q = false
		add_camera_shake(SHAKE_CAST_TRAUMA)

	if is_fire and Input.is_action_just_pressed(_q_action()) and not is_flamethrowing:
		_channel_flamethrower()

	if is_air and Input.is_action_just_pressed(_q_action()):
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
	if is_earth and Input.is_action_just_pressed(_e_action()) and not is_boulder and not is_spiking:
		_shoot_earth_spikes()

	if is_fire and Input.is_action_just_pressed(_e_action()) and not fire_blast_busy:
		_shoot_blast()

	if is_air and Input.is_action_just_pressed(_e_action()):
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
		elif not _is_boulder_dash_launching:
			_start_boulder_dash_launch()

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

	# Boulder Dash: durante o mini pulinho a bola cresce de dentro do player (0 -> tamanho
	# mínimo), terminando de crescer exatamente no pico, onde ela de fato assume o controle.
	if _is_boulder_dash_launching:
		var launch_progress = clamp(1.0 - (velocity.y / _boulder_launch_initial_vy), 0.0, 1.0)
		boulder_mesh.scale = Vector3.ONE * (BOULDER_START_SCALE * launch_progress)

		if velocity.y <= 0.0:
			_is_boulder_dash_launching = false
			_start_boulder_dash()

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

	# Animações de pulo (Jump_Charge, Jump_Ascend, Jump_Descend)
	_update_jump_animation()


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
	# Cada rig foi modelado encarando um eixo diferente (o Mannequin encara +Z, por isso o
	# flip de 180°; o Golem encara -Y no Blender — convenção diferente, ver memory
	# golem-rig-source). Por isso o flip é por export em vez de fixo, pra dar pra ajustar
	# sem mexer em código se ele ficar andando de costas/de lado.
	var flip_degrees = GOLEM_FACING_FLIP_DEGREES if player_mesh == golem_mesh else MANNEQUIN_FACING_FLIP_DEGREES
	target_basis = target_basis.rotated(Vector3.UP, deg_to_rad(flip_degrees))
	var current_quat = player_mesh.global_transform.basis.get_rotation_quaternion()
	var target_quat = target_basis.get_rotation_quaternion()
	var new_quat = current_quat.slerp(target_quat, clamp(MODEL_TURN_RATE * delta, 0.0, 1.0))

	var gt = player_mesh.global_transform
	gt.basis = Basis(new_quat)
	player_mesh.global_transform = gt


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found = _find_skeleton(child)
		if found:
			return found
	return null


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found = _find_animation_player(child)
		if found:
			return found
	return null


# Junta os MeshInstance3D das folhas/musgo do golem (nomes "Leaves_*"/"Moss_*" no rig
# Blender). São as únicas malhas com o shape key "Wilt" (encolhe e some), animado só
# dentro do clipe "Roll" — ver _reset_golem_foliage.
func _find_golem_foliage_meshes(node: Node, out_list: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node.name.begins_with("Leaves_") or node.name.begins_with("Moss_")):
		out_list.append(node)
	for child in node.get_children():
		_find_golem_foliage_meshes(child, out_list)


# Garante "o musgo/folhas aparecer é o padrão, só some durante o Roll": o AnimationPlayer
# do Godot NÃO reseta shape keys que a próxima animação não anima, então se o Roll for
# interrompido (Boulder Dash cancelado, ou o próprio dash concluindo e trocando pra outra
# animação no meio do clipe) o Wilt fica travado em "encolhido". Chamado toda vez que uma
# animação que NÃO é Roll começa a tocar, então nenhuma sequência de interrupção consegue
# deixar a folhagem sumida.
@rpc("any_peer", "call_local")
func _reset_golem_foliage() -> void:
	for mesh in _golem_foliage_meshes:
		if not is_instance_valid(mesh):
			continue
		var idx = mesh.find_blend_shape_by_name("Wilt")
		if idx != -1:
			mesh.set_blend_shape_value(idx, 0.0)


# Tenta os nomes exatos do rig UE Mannequin primeiro; se não bater (case diferente, prefixo
# tipo "mixamorig:", etc.) cai pra uma busca por qualquer osso contendo "spine", pegando
# o de nome "maior" (spine_03 > spine_02 > spine_01 em ordem alfabética) como aproximação
# do osso mais alto da cadeia (mais perto do peito/ombros).
func _find_torso_bone(skel: Skeleton3D) -> int:
	for bone_name in ["spine_03", "spine_02", "spine_01"]:
		var idx = skel.find_bone(bone_name)
		if idx != -1:
			return idx

	var best_idx = -1
	var best_name = ""
	for i in range(skel.get_bone_count()):
		var bone_name = skel.get_bone_name(i)
		if bone_name.to_lower().contains("spine") and bone_name > best_name:
			best_name = bone_name
			best_idx = i

	return best_idx


# AnimationPlayer está em modo MANUAL: quem avança a animação é a gente, aqui, sempre seguido
# IMEDIATAMENTE (mesma função, síncrono) do twist do torso — garante ordem sem depender de
# timing implícito do engine, o que era a causa raiz de só virar no fim da animação.
func _advance_animation_and_torso() -> void:
	var delta = get_process_delta_time()

	if is_instance_valid(mannequin_animation_player):
		mannequin_animation_player.advance(delta)

	_update_torso_twist(delta)


func _update_torso_twist(delta: float) -> void:
	if not is_instance_valid(_skeleton) or _torso_bone_idx == -1:
		return

	# O rig do Mannequin encara +Z (é por isso que _update_model_facing faz o
	# .rotated(Vector3.UP, PI)), então a frente VISUAL do modelo é +basis.z.
	var model_forward = player_mesh.global_transform.basis.z
	var camera_forward = -global_transform.basis.z
	model_forward = Vector3(model_forward.x, 0.0, model_forward.z)
	camera_forward = Vector3(camera_forward.x, 0.0, camera_forward.z)
	if model_forward.length_squared() < 0.001 or camera_forward.length_squared() < 0.001:
		return

	# Torso SEMPRE de costas pra câmera; pés livres (o Model segue o movimento por conta própria)
	var target_yaw = clamp(
		model_forward.normalized().signed_angle_to(camera_forward.normalized(), Vector3.UP),
		deg_to_rad(-TORSO_YAW_MAX_DEGREES), deg_to_rad(TORSO_YAW_MAX_DEGREES)
	)
	_torso_twist_yaw = lerp_angle(_torso_twist_yaw, target_yaw, clamp(TORSO_TWIST_LERP_SPEED * delta, 0.0, 1.0))

	# A pose de um osso vive no espaço do osso PAI, e nesse rig os eixos do osso não são os do
	# mundo (no UE o X corre ao longo do osso). Então converte a rotação de mundo pro espaço do
	# pai por conjugação — sem isso, girar em Vector3.UP torcia num eixo torto e deformava tudo.
	var parent_world_q = _skeleton.global_transform.basis.get_rotation_quaternion()
	var parent_idx = _skeleton.get_bone_parent(_torso_bone_idx)
	if parent_idx != -1:
		parent_world_q = parent_world_q * _skeleton.get_bone_global_pose(parent_idx).basis.get_rotation_quaternion()

	var world_twist = Quaternion(Vector3.UP, _torso_twist_yaw)
	var local_delta = parent_world_q.inverse() * world_twist * parent_world_q

	# Como a gente controla o advance() manualmente logo acima, essa leitura É SEMPRE a pose
	# fresca que a animação acabou de escrever nesse frame — nunca a nossa própria escrita de
	# antes (isso só existia como risco quando a ordem entre animação e twist era implícita).
	var animated_pose = _skeleton.get_bone_pose_rotation(_torso_bone_idx)
	_skeleton.set_bone_pose_rotation(_torso_bone_idx, local_delta * animated_pose)

	if TORSO_DEBUG:
		_torso_debug_timer += delta
		if _torso_debug_timer >= 0.5:
			_torso_debug_timer = 0.0
			print("[TorsoAim] alvo=%.1f° aplicado=%.1f° | osso=%s" % [
				rad_to_deg(target_yaw), rad_to_deg(_torso_twist_yaw), _skeleton.get_bone_name(_torso_bone_idx)
			])


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


# Ação real que dispara a spell "Q"/"E". Fora do drag-and-drop, Q sempre dispara
# 'skill_q' e E sempre dispara 'skill_e'; depois de trocar os slots, cada tecla
# passa a disparar a ação da outra.
func _q_action() -> StringName:
	return &"skill_e" if spell_slots_swapped else &"skill_q"


func _e_action() -> StringName:
	return &"skill_q" if spell_slots_swapped else &"skill_e"


func toggle_spell_slots() -> void:
	spell_slots_swapped = not spell_slots_swapped


# Nome curto da spell que está no slot "q" ou "e" no momento (considerando a troca),
# pra exibir na SpellSlotBar.
func get_ability_name_for_key(key: String) -> String:
	var action := _q_action() if key == "q" else _e_action()
	var is_earth = player_element == ElementsEnum.Element.EARTH or player_element == ElementsEnum.Element.GOLEM
	var is_fire = player_element == ElementsEnum.Element.FIRE
	if action == &"skill_q":
		if is_earth:
			return "Rock Sling"
		if is_fire:
			return "Flamethrower"
		return "Wind Torrent"
	if is_earth:
		return "Earth Spikes"
	if is_fire:
		return "Fire Blast"
	return "Tornado"


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

	# GOLEM troca o modelo/rig visível inteiro pro golem de pedra (com suas próprias
	# animações Walk/Sprint/Jump); os outros elementos usam o Mannequin de sempre.
	var use_golem = elem == ElementsEnum.Element.GOLEM
	mannequin_mesh.visible = not use_golem
	golem_mesh.visible = use_golem
	player_mesh = golem_mesh if use_golem else mannequin_mesh
	animation_player = golem_animation_player if use_golem else mannequin_animation_player
	_skeleton = _golem_skeleton if use_golem else _mannequin_skeleton
	_torso_bone_idx = _golem_torso_bone_idx if use_golem else _mannequin_torso_bone_idx

	# O golem já tem sua própria pedra/musgo pintados no material — não sobrescreve com a
	# tinta de elemento (que é feita pro Mannequin genérico).
	if not use_golem:
		var tint: Color
		match elem:
			ElementsEnum.Element.FIRE:
				tint = Color(0.9, 0.2, 0.15)
			ElementsEnum.Element.AIR:
				tint = Color(0.92, 0.95, 0.98)
			_:
				tint = Color(0.45, 0.3, 0.15)  # EARTH
		_tint_model_recursive(player_mesh, tint)

	# O texto de controles e a hotbar são só do próprio jogador (CanvasLayer já é
	# escondido de todo mundo que não é a autoridade), então atualizar em todo
	# mundo aqui não vaza nada.
	_update_controls_label(elem)
	_update_element_bar(elem)


func _update_element_bar(elem: int) -> void:
	match elem:
		ElementsEnum.Element.FIRE:
			button_element_fire.button_pressed = true
		ElementsEnum.Element.AIR:
			button_element_air.button_pressed = true
		_:
			button_element_earth.button_pressed = true


func _update_controls_label(elem: int) -> void:
	if is_instance_valid(_spell_slot_bar):
		_spell_slot_bar.refresh()
	match elem:
		ElementsEnum.Element.FIRE:
			controls_label.text = "FIRE\nQ: Flamethrower (segure)\nE: Fire Blast (área)\nLMB: Fireball (carregue e solte)\nRMB: Fire Cone\nSHIFT: Fire Dash (2x veloc., 5s)\nSPACE: Pulo\nTAB: Stats / trocar Q-E\nESC: Menu"
		ElementsEnum.Element.AIR:
			controls_label.text = "AIR\nQ: Wind Torrent (empurra objetos)\nE: Tornado (zigue-zague)\nLMB: 3 Air Slashes\nRMB: Slash of Air (deflete)\nSHIFT: Air Dash (3 cargas, 5s cada)\nSPACE: Pulo / Duplo Pulo / Planar (segure no ar)\nTAB: Stats / trocar Q-E\nESC: Menu"
		ElementsEnum.Element.GOLEM:
			controls_label.text = "GOLEM\nQ: Rock Sling (carregue e solte)\nE: Earth Spikes (fileira)\nLMB: Soco (Jab/Hook/Uppercut)\nRMB: 2 Rochas Grandes\nSHIFT: Boulder Dash\nSPACE: Pulo / Earth Leap (segure parado)\nTAB: Stats / trocar Q-E\nESC: Menu"
		_:
			controls_label.text = "EARTH\nQ: Rock Sling (carregue e solte)\nE: Earth Spikes (fileira)\nLMB: Soco (Jab/Hook/Uppercut)\nRMB: 2 Rochas Grandes\nSHIFT: Boulder Dash\nSPACE: Pulo / Earth Leap (segure parado)\nTAB: Stats / trocar Q-E\nESC: Menu"


func _tint_model_recursive(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		var existing_material = node.get_active_material(0)
		var material = existing_material.duplicate() if existing_material else StandardMaterial3D.new()
		if material is StandardMaterial3D:
			material.albedo_color = tint
			node.set_surface_override_material(0, material)

	for child in node.get_children():
		_tint_model_recursive(child, tint)


# LMB: soco corpo a corpo, sem projétil nenhum. Cada clique avança 1 hit do combo
# (Jab -> Hook -> Uppercut -> Jab...).
func _shoot_lmb() -> void:
	lmb_busy = true

	var combo_anim = LMB_COMBO_ANIMATIONS[lmb_wave_count % LMB_COMBO_ANIMATIONS.size()]
	lmb_wave_count += 1

	_play_animation.rpc(combo_anim)
	await get_tree().create_timer(LMB_SHOT_INTERVAL).timeout

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

	_play_animation.rpc("SmashGround")
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


func _update_jump_animation() -> void:
	# Rastreia as fases do pulo e toca as animações corretas.
	#
	# IMPORTANTE: is_charging_leap tem que ser checado ANTES de is_on_floor() — o jogador fica
	# TRAVADO NO CHÃO enquanto carrega o Earth Leap (is_on_floor() == true o tempo todo), então
	# se o check de chão viesse primeiro ele sempre vencia e Jump_Charge nunca era alcançado.
	#
	# Um pulo comum (sem carregar Earth Leap) usa a MESMA Jump_Ascend/Jump_Descend daqui — não
	# existe um recurso de animação "Jump_Up" separado no golem, só Jump_Ascend/Charge/Descend.
	var anim_to_play = ""

	if _is_boulder_dash_launching:
		# Mini pulinho antes do Boulder Dash: toca o Roll em vez do Jump_Ascend normal
		anim_to_play = "Roll"
	elif is_charging_leap:
		# Carregando pulo de Terra (chão ou não, não importa): toca animação de carga
		anim_to_play = "Jump_Charge"
	elif is_on_floor():
		# No chão e não carregando: reseta o rastreamento
		_is_in_jump_ascent = false
		_last_jump_animation = ""
	elif velocity.y > 0.01:
		# No ar, subindo (pulo comum OU leap liberado — mesma animação pros dois): ascensão
		anim_to_play = "Jump_Ascend"
		_is_in_jump_ascent = true
	elif _is_in_jump_ascent:
		# No ar, descendo (só depois de ter subido antes): descida
		anim_to_play = "Jump_Descend"

	# Toca a animação apenas se mudou
	if anim_to_play != "" and anim_to_play != _last_jump_animation:
		_play_animation.rpc(anim_to_play)
		_last_jump_animation = anim_to_play


@rpc("any_peer", "call_local")
func _play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		if anim_name != "Roll":
			_reset_golem_foliage()
		var speed_scale = ROLL_ANIM_SPEED_MULTIPLIER if anim_name == "Roll" else 1.0
		animation_player.play(anim_name, ANIM_BLEND_TIME, speed_scale)


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


func _start_boulder_dash_launch() -> void:
	_is_boulder_dash_launching = true
	velocity.y += JUMP_VELOCITY / 3.0
	_boulder_launch_initial_vy = velocity.y
	boulder_mesh.scale = Vector3.ZERO
	_set_boulder_growing.rpc(true)
	_play_animation.rpc("Roll")


@rpc("any_peer", "call_local")
func _set_boulder_growing(active: bool) -> void:
	# Deixa a boulder visível crescendo por dentro do player durante o Roll, antes do
	# _set_boulder_visual esconder o player de vez no pico do pulinho.
	boulder_mesh.visible = active
	if active:
		boulder_mesh.scale = Vector3.ZERO


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
	# O Roll do mini-pulinho quase sempre é cortado antes do fim (fica mais rápido, o clipe
	# nem chega no frame em que as folhas voltam sozinhas) — reseta aqui, com o golem já
	# escondido, pra não ter pop visual e a folhagem já estar normal quando ele reaparecer.
	_reset_golem_foliage.rpc()


func _end_boulder_dash() -> void:
	is_boulder = false
	_set_boulder_visual.rpc(false)
	_reset_golem_foliage.rpc()  # segunda rede de segurança: cobre cancelar o dash ainda no mini-pulinho


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

	while elapsed < FLAMETHROWER_DURATION and Input.is_action_pressed(_q_action()) and player_element == ElementsEnum.Element.FIRE:
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
		camera_3d.rotation = _base_camera_rotation
		return

	var pitch_offset = SHAKE_MAX_OFFSET * amount * _shake_noise.get_noise_2d(_shake_time, 0.0)
	var yaw_offset = SHAKE_MAX_OFFSET * amount * _shake_noise.get_noise_2d(_shake_time, 100.0)
	var roll_offset = SHAKE_MAX_ROLL * amount * _shake_noise.get_noise_2d(_shake_time, 200.0)
	camera_3d.rotation = _base_camera_rotation + Vector3(pitch_offset, yaw_offset, roll_offset)


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
