extends CanvasLayer

## Menu principal: Start / Multiplayer / Options / Quit.
## "Multiplayer" abre o painel de sessão (username, session id, join/create).
## "Options" abre o OptionsMenu (General/Graphics/Controls/Audio/Accessibility).

@onready var root_panel: PanelContainer = %RootPanel
@onready var button_start: Button = %ButtonStart
@onready var button_multiplayer: Button = %ButtonMultiplayer
@onready var button_options: Button = %ButtonOptions
@onready var button_quit: Button = %ButtonQuit

@onready var multiplayer_panel: PanelContainer = %MultiplayerPanel
@onready var button_join: Button = %ButtonJoin
@onready var button_back_enet: Button = %ButtonBackEnet

@onready var line_edit_session: LineEdit = %LineEditSession
@onready var line_edit_username: LineEdit = %LineEditUsername
@onready var button_join_tube: Button = %ButtonJoinTube
@onready var button_create_tube: Button = %ButtonCreateTube
@onready var button_back_tube: Button = %ButtonBackTube

@onready var enet_menu: VBoxContainer = %EnetMenu
@onready var tube_menu: VBoxContainer = %TubeMenu

const WORLD = preload("uid://cqn60bapogc82")
const PLAYER = preload("uid://dyabas8evvb1d")

var _options_menu: OptionsMenu


func _ready() -> void:

	if Network.tube_enabled:
		enet_menu.hide()
	else:
		tube_menu.hide()

	line_edit_username.text = Global.username

	button_start.pressed.connect(on_start)
	button_multiplayer.pressed.connect(show_multiplayer_panel)
	button_options.pressed.connect(show_options_panel)
	button_quit.pressed.connect(func(): get_tree().quit())

	button_join.pressed.connect(on_join)
	button_back_enet.pressed.connect(show_root_panel)
	button_back_tube.pressed.connect(show_root_panel)

	line_edit_session.text_changed.connect(update_session)
	line_edit_username.text_changed.connect(update_username)
	button_join_tube.disabled = true
	button_join_tube.pressed.connect(on_join_tube)
	button_create_tube.pressed.connect(on_create_tube)

	Network.tube_client.error_raised.connect(on_error_raised)

	_options_menu = OptionsMenu.new()
	add_child(_options_menu)
	_options_menu.closed.connect(show_root_panel)

	if OS.has_feature('server'):
		Network.start_server()
		await get_tree().create_timer(0.1).timeout
		add_world()


func show_root_panel() -> void:
	_options_menu.hide()
	multiplayer_panel.hide()
	root_panel.show()


func show_multiplayer_panel() -> void:
	root_panel.hide()
	multiplayer_panel.show()


func show_options_panel() -> void:
	root_panel.hide()
	multiplayer_panel.hide()
	_options_menu.open()


func on_start() -> void:
	add_world()
	Network.start_singleplayer()


func on_join() -> void:
	Network.join_server()


func add_world() -> void:
	var new_world = WORLD.instantiate()
	get_tree().current_scene.add_child(new_world)
	hide()


func on_join_tube() -> void:
	Network.tube_join(line_edit_session.text)
	multiplayer.connected_to_server.connect(add_world)


func on_create_tube() -> void:
	Network.tube_create()
	add_world()


func update_session(new_text: String) -> void:
	if new_text != '':
		button_join_tube.disabled = false


func update_username(new_text: String) -> void:
	Global.username = new_text
	Settings.set_value("username", new_text)


func on_error_raised(_code, _message) -> void:
	line_edit_session.text = ''
	button_join_tube.add_theme_color_override('font_disabled_color', Color.DARK_RED)
	button_join_tube.disabled = true
	Network.clean_up_signals()
