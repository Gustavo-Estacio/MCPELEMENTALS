extends Node

## Autoload "Settings": guarda, persiste e aplica todas as opções do jogo.
##
## O menu de opções (Scripts/UI/options_menu.gd) é gerado a partir do SCHEMA
## daqui, então pra adicionar uma opção nova basta descrever ela no SCHEMA e
## tratar a chave em _apply_value().

const CONFIG_PATH := "user://settings.cfg"
const SECTION := "settings"
const KEYBIND_SECTION := "keybinds"

const SFX_BUS := &"SFX"
const MUSIC_BUS := &"Music"
const AMBIENCE_BUS := &"Ambience"

signal setting_changed(key: String, value: Variant)
signal keybinds_changed

# Categorias na ordem em que aparecem no menu de opções.
const CATEGORIES := ["general", "graphics", "controls", "audio", "accessibility"]

const CATEGORY_LABELS := {
	"general": "General",
	"graphics": "Graphics",
	"controls": "Controls",
	"audio": "Audio",
	"accessibility": "Accessibility",
}

# Ações remapeáveis no submenu de Controls (ordem = ordem na tela).
const REBINDABLE_ACTIONS := [
	{"action": "forward", "label": "Move Forward"},
	{"action": "backward", "label": "Move Backward"},
	{"action": "left", "label": "Move Left"},
	{"action": "right", "label": "Move Right"},
	{"action": "jump", "label": "Jump / Glide"},
	{"action": "crouch", "label": "Crouch / Fast Fall"},
	{"action": "skill_shift", "label": "Dash"},
	{"action": "skill_q", "label": "Ability Q"},
	{"action": "skill_e", "label": "Ability E"},
	{"action": "skill_lmb", "label": "Primary Attack"},
	{"action": "skill_rmb", "label": "Secondary Attack"},
	{"action": "select_earth", "label": "Select Earth"},
	{"action": "select_fire", "label": "Select Fire"},
	{"action": "select_air", "label": "Select Air"},
	{"action": "menu", "label": "Pause Menu"},
]

const SCHEMA := {
	"general": [
		{"key": "username", "label": "Username", "type": "text", "default": "", "max_length": 12},
		{"key": "show_fps", "label": "Show FPS", "type": "bool", "default": false},
		{"key": "show_controls", "label": "Show Controls Overlay", "type": "bool", "default": true},
	],
	"graphics": [
		{"key": "window_mode", "label": "Window Mode", "type": "enum", "default": 0,
			"values": ["Windowed", "Fullscreen", "Borderless Fullscreen"]},
		{"key": "resolution", "label": "Resolution (windowed)", "type": "enum", "default": 2,
			"values": ["1280 x 720", "1600 x 900", "1920 x 1080", "2560 x 1440"]},
		{"key": "vsync", "label": "V-Sync", "type": "enum", "default": 1,
			"values": ["Off", "On", "Adaptive"]},
		{"key": "max_fps", "label": "FPS Limit (0 = unlimited)", "type": "range", "default": 0,
			"min": 0.0, "max": 240.0, "step": 10.0},
		{"key": "msaa", "label": "Anti-Aliasing (MSAA 3D)", "type": "enum", "default": 0,
			"values": ["Off", "2x", "4x", "8x"]},
		{"key": "render_scale", "label": "Render Scale", "type": "range", "default": 100.0,
			"min": 50.0, "max": 100.0, "step": 5.0, "suffix": "%"},
		{"key": "fov", "label": "Field of View", "type": "range", "default": 90.0,
			"min": 70.0, "max": 120.0, "step": 1.0},
	],
	"controls": [
		{"key": "mouse_sensitivity", "label": "Mouse Sensitivity", "type": "range", "default": 1.0,
			"min": 0.1, "max": 5.0, "step": 0.1},
		{"key": "invert_y", "label": "Invert Vertical Axis", "type": "bool", "default": false},
		{"key": "keybinds", "label": "Key Bindings", "type": "keybinds"},
	],
	"audio": [
		{"key": "master_volume", "label": "Master Volume", "type": "range", "default": 100.0,
			"min": 0.0, "max": 100.0, "step": 1.0, "suffix": "%"},
		{"key": "music_volume", "label": "Music", "type": "range", "default": 80.0,
			"min": 0.0, "max": 100.0, "step": 1.0, "suffix": "%"},
		{"key": "sfx_volume", "label": "Effects", "type": "range", "default": 100.0,
			"min": 0.0, "max": 100.0, "step": 1.0, "suffix": "%"},
		{"key": "ambience_volume", "label": "Ambience", "type": "range", "default": 100.0,
			"min": 0.0, "max": 100.0, "step": 1.0, "suffix": "%"},
		{"key": "mute", "label": "Mute Everything", "type": "bool", "default": false},
	],
	"accessibility": [
		{"key": "ui_scale", "label": "Interface Scale", "type": "range", "default": 100.0,
			"min": 75.0, "max": 150.0, "step": 5.0, "suffix": "%"},
		{"key": "camera_shake", "label": "Camera Shake", "type": "range", "default": 100.0,
			"min": 0.0, "max": 100.0, "step": 5.0, "suffix": "%"},
		{"key": "reduce_motion", "label": "Reduce Motion (trails / shake)", "type": "bool", "default": false},
		{"key": "high_contrast_reticle", "label": "High Contrast Reticle", "type": "bool", "default": false},
	],
}

var values := {}

var _fps_layer: CanvasLayer
var _fps_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_load_defaults()
	load_settings()
	apply_all()


func _load_defaults() -> void:
	for category in SCHEMA:
		for entry in SCHEMA[category]:
			if entry.has("default"):
				values[entry["key"]] = entry["default"]


func get_value(key: String) -> Variant:
	return values.get(key)


func set_value(key: String, value: Variant, save := true) -> void:
	if values.get(key) == value:
		return
	values[key] = value
	_apply_value(key)
	setting_changed.emit(key, value)
	if save:
		save_settings()


func find_entry(key: String) -> Dictionary:
	for category in SCHEMA:
		for entry in SCHEMA[category]:
			if entry.get("key") == key:
				return entry
	return {}


func reset_category(category: String) -> void:
	for entry in SCHEMA.get(category, []):
		if entry.has("default"):
			set_value(entry["key"], entry["default"], false)
	if category == "controls":
		reset_keybinds()
	save_settings()


# ---------------------------------------------------------------- persistência

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return

	if config.has_section(SECTION):
		for key in config.get_section_keys(SECTION):
			values[key] = config.get_value(SECTION, key)

	if config.has_section(KEYBIND_SECTION):
		for action in config.get_section_keys(KEYBIND_SECTION):
			if not InputMap.has_action(action):
				continue
			var event := _dict_to_event(config.get_value(KEYBIND_SECTION, action))
			if event:
				InputMap.action_erase_events(action)
				InputMap.action_add_event(action, event)


func save_settings() -> void:
	var config := ConfigFile.new()
	for key in values:
		config.set_value(SECTION, key, values[key])

	for entry in REBINDABLE_ACTIONS:
		var action: String = entry["action"]
		var event := get_action_event(action)
		if event:
			config.set_value(KEYBIND_SECTION, action, _event_to_dict(event))

	config.save(CONFIG_PATH)


# ------------------------------------------------------------------- aplicação

func apply_all() -> void:
	for key in values:
		_apply_value(key)


func _apply_value(key: String) -> void:
	match key:
		"username":
			Global.username = values[key]
		"show_fps":
			_update_fps_counter()
		"window_mode", "resolution":
			_apply_window()
		"vsync":
			var vsync_modes := [
				DisplayServer.VSYNC_DISABLED,
				DisplayServer.VSYNC_ENABLED,
				DisplayServer.VSYNC_ADAPTIVE,
			]
			DisplayServer.window_set_vsync_mode(vsync_modes[int(values[key])])
		"max_fps":
			Engine.max_fps = int(values[key])
		"msaa":
			var viewport := get_viewport()
			if viewport:
				var msaa_modes := [
					Viewport.MSAA_DISABLED,
					Viewport.MSAA_2X,
					Viewport.MSAA_4X,
					Viewport.MSAA_8X,
				]
				viewport.msaa_3d = msaa_modes[int(values[key])]
		"render_scale":
			var viewport := get_viewport()
			if viewport:
				viewport.scaling_3d_scale = float(values[key]) / 100.0
		"master_volume", "music_volume", "sfx_volume", "ambience_volume", "mute":
			_apply_audio()
		"ui_scale":
			var window := get_window()
			if window:
				window.content_scale_factor = float(values[key]) / 100.0
		_:
			# fov, sensibilidade, acessibilidade do player etc. são lidos direto
			# de Settings por quem usa (via setting_changed / get_value).
			pass


func _apply_window() -> void:
	var mode := int(values.get("window_mode", 0))
	match mode:
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		_:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(_resolution_size())
			# Recentraliza depois de mudar o tamanho, senão a janela pode sair da tela
			var screen_size := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
			DisplayServer.window_set_position((screen_size - DisplayServer.window_get_size()) / 2)


func _resolution_size() -> Vector2i:
	match int(values.get("resolution", 2)):
		0: return Vector2i(1280, 720)
		1: return Vector2i(1600, 900)
		3: return Vector2i(2560, 1440)
		_: return Vector2i(1920, 1080)


func _ensure_audio_buses() -> void:
	for bus_name in [MUSIC_BUS, SFX_BUS, AMBIENCE_BUS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, &"Master")


func _apply_audio() -> void:
	var muted: bool = values.get("mute", false)
	_set_bus_volume(&"Master", values.get("master_volume", 100.0), muted)
	_set_bus_volume(MUSIC_BUS, values.get("music_volume", 80.0), muted)
	_set_bus_volume(SFX_BUS, values.get("sfx_volume", 100.0), muted)
	_set_bus_volume(AMBIENCE_BUS, values.get("ambience_volume", 100.0), muted)


func _set_bus_volume(bus_name: StringName, percent: float, muted: bool) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	var linear: float = clampf(float(percent) / 100.0, 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(linear))
	AudioServer.set_bus_mute(index, muted or is_zero_approx(linear))


func _update_fps_counter() -> void:
	var show: bool = values.get("show_fps", false)
	if not show:
		if is_instance_valid(_fps_layer):
			_fps_layer.queue_free()
			_fps_layer = null
			_fps_label = null
		set_process(false)
		return

	if not is_instance_valid(_fps_layer):
		_fps_layer = CanvasLayer.new()
		_fps_layer.layer = 128
		_fps_label = Label.new()
		_fps_label.position = Vector2(16, 12)
		_fps_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		_fps_label.add_theme_constant_override("shadow_offset_x", 2)
		_fps_label.add_theme_constant_override("shadow_offset_y", 2)
		_fps_layer.add_child(_fps_label)
		add_child(_fps_layer)
	set_process(true)


func _process(_delta: float) -> void:
	if is_instance_valid(_fps_label):
		_fps_label.text = "%d FPS" % Engine.get_frames_per_second()


# --------------------------------------------------------------- atalhos úteis

func mouse_sensitivity_scale() -> float:
	return float(values.get("mouse_sensitivity", 1.0))


func pitch_direction() -> float:
	return -1.0 if values.get("invert_y", false) else 1.0


func camera_shake_scale() -> float:
	if values.get("reduce_motion", false):
		return 0.0
	return float(values.get("camera_shake", 100.0)) / 100.0


func reduce_motion() -> bool:
	return values.get("reduce_motion", false)


# ------------------------------------------------------------------- keybinds

func get_action_event(action: String) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
			return event
	return null


func get_action_text(action: String) -> String:
	var event := get_action_event(action)
	if event == null:
		return "Unbound"
	if event is InputEventKey:
		var keycode: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(keycode))
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "Mouse Left"
			MOUSE_BUTTON_RIGHT: return "Mouse Right"
			MOUSE_BUTTON_MIDDLE: return "Mouse Middle"
			MOUSE_BUTTON_WHEEL_UP: return "Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN: return "Wheel Down"
			_: return "Mouse %d" % event.button_index
	return event.as_text()


func rebind_action(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	# Tira o mesmo botão de outras ações, senão dois comandos disparam juntos
	for entry in REBINDABLE_ACTIONS:
		var other: String = entry["action"]
		if other == action:
			continue
		var other_event := get_action_event(other)
		if other_event and _same_event(other_event, event):
			InputMap.action_erase_event(other, other_event)

	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	keybinds_changed.emit()
	save_settings()


func reset_keybinds() -> void:
	InputMap.load_from_project_settings()
	keybinds_changed.emit()
	save_settings()


func _same_event(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return a.physical_keycode == b.physical_keycode and a.keycode == b.keycode
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	return false


func _event_to_dict(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "physical": event.physical_keycode, "keycode": event.keycode}
	if event is InputEventMouseButton:
		return {"type": "mouse", "index": event.button_index}
	if event is InputEventJoypadButton:
		return {"type": "joy", "index": event.button_index}
	return {}


func _dict_to_event(data: Variant) -> InputEvent:
	if typeof(data) != TYPE_DICTIONARY:
		return null
	match data.get("type", ""):
		"key":
			var key_event := InputEventKey.new()
			key_event.physical_keycode = int(data.get("physical", 0))
			key_event.keycode = int(data.get("keycode", 0))
			return key_event
		"mouse":
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = int(data.get("index", 0))
			return mouse_event
		"joy":
			var joy_event := InputEventJoypadButton.new()
			joy_event.button_index = int(data.get("index", 0))
			return joy_event
	return null
