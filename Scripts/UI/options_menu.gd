extends Control

class_name OptionsMenu

## Menu de opções reaproveitado pelo menu principal e pelo menu de pause.
## Os submenus (General / Graphics / Controls / Audio / Accessibility) e os
## controles de cada um são gerados a partir do Settings.SCHEMA.

signal closed

const ROW_MIN_WIDTH := 320
const CONTROL_MIN_WIDTH := 220
const VALUE_MIN_WIDTH := 64

## Aba DEV encostada na esquerda: painel estreito, sem escurecer a tela.
const DOCK_WIDTH_RATIO := 0.25
const DOCK_ROW_MIN_WIDTH := 96
const DOCK_CONTROL_MIN_WIDTH := 90
const DOCK_VALUE_MIN_WIDTH := 40
const DOCK_FONT_SIZE := 12
const PANEL_SIZE := Vector2(760, 520)

var _tabs: TabContainer
var _keybind_buttons := {}
var _listening_action := ""
var _listening_button: Button

var _preset_save_button: Button
var _preset_picker: OptionButton
var _preset_status: Label
var _preset_dialog: ConfirmationDialog
var _preset_name_edit: LineEdit

var _dim: ColorRect
var _center: CenterContainer
var _dock: MarginContainer
var _panel: PanelContainer
var _title: Label
var _reset_button: Button
var _panel_margin: MarginContainer
var _dev_rows: Array[Control] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	Settings.keybinds_changed.connect(_refresh_keybind_labels)
	hide()


func open() -> void:
	show()
	_refresh_all()
	_update_preset_controls()  # a pasta de presets pode ter mudado fora do jogo
	_update_layout()
	_tabs.get_tab_bar().grab_focus()


func close() -> void:
	_cancel_listening()
	hide()
	closed.emit()


func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.6)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	_center = CenterContainer.new()
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_center)

	# Dock da aba DEV: 1/4 da tela à esquerda, pro resto da tela ficar livre pra
	# ver o efeito dos sliders no jogo.
	_dock = MarginContainer.new()
	_dock.anchor_left = 0.0
	_dock.anchor_top = 0.0
	_dock.anchor_right = DOCK_WIDTH_RATIO
	_dock.anchor_bottom = 1.0
	_dock.offset_left = 0.0
	_dock.offset_top = 0.0
	_dock.offset_right = 0.0
	_dock.offset_bottom = 0.0
	for side in ["left", "top", "right", "bottom"]:
		_dock.add_theme_constant_override("margin_" + side, 8)
	add_child(_dock)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	_panel = panel
	_center.add_child(panel)

	_panel_margin = MarginContainer.new()
	panel.add_child(_panel_margin)
	var margin := _panel_margin

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	_title = Label.new()
	_title.text = "Options"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	column.add_child(_title)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.clip_tabs = false
	column.add_child(_tabs)

	for category in Settings.CATEGORIES:
		_tabs.add_child(_build_category(category))

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	column.add_child(footer)

	# Salvar/carregar preset só aparece na aba DEV (canto de baixo à esquerda).
	_preset_save_button = Button.new()
	_preset_save_button.text = "Salvar essa configuração"
	_preset_save_button.pressed.connect(_on_save_preset_pressed)
	footer.add_child(_preset_save_button)

	_preset_picker = OptionButton.new()
	_preset_picker.custom_minimum_size.x = 170
	_preset_picker.item_selected.connect(_on_preset_selected)
	footer.add_child(_preset_picker)

	_preset_status = Label.new()
	_preset_status.modulate = Color(1, 1, 1, 0.7)
	_preset_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preset_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(_preset_status)

	_reset_button = Button.new()
	_reset_button.text = "Reset This Tab"
	_reset_button.pressed.connect(_on_reset_pressed)
	footer.add_child(_reset_button)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.pressed.connect(close)
	footer.add_child(back_button)

	_tabs.tab_changed.connect(func(_index: int):
		_update_preset_controls()
		_update_layout()
	)
	_update_preset_controls()
	_update_layout()


func _build_category(category: String) -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = Settings.CATEGORY_LABELS.get(category, category.capitalize())
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	for entry in Settings.SCHEMA[category]:
		match entry["type"]:
			"keybinds":
				list.add_child(_build_keybinds_section(entry))
			"header":
				list.add_child(_build_header(entry))
			_:
				var row := _build_row(entry)
				if category == "dev":
					_dev_rows.append(row)  # encolhem quando o painel vira dock
				list.add_child(row)

	return scroll


## Título de grupo, usado pra separar os efeitos na aba DEV.
func _build_header(entry: Dictionary) -> Control:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)
	section.add_child(HSeparator.new())

	var title := Label.new()
	title.text = entry["label"]
	title.add_theme_font_size_override("font_size", 18)
	section.add_child(title)

	return section


func _build_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)

	var label := Label.new()
	label.text = entry["label"]
	label.custom_minimum_size.x = ROW_MIN_WIDTH
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	row.add_child(label)

	var key: String = entry["key"]

	match entry["type"]:
		"bool":
			var check := CheckButton.new()
			check.button_pressed = Settings.get_value(key)
			check.toggled.connect(func(pressed: bool): Settings.set_value(key, pressed))
			check.set_meta("setting_key", key)
			row.add_child(check)
		"enum":
			var option := OptionButton.new()
			option.custom_minimum_size.x = CONTROL_MIN_WIDTH
			for item in entry["values"]:
				option.add_item(item)
			option.selected = int(Settings.get_value(key))
			option.item_selected.connect(func(index: int): Settings.set_value(key, index))
			option.set_meta("setting_key", key)
			row.add_child(option)
		"range":
			var slider := HSlider.new()
			slider.custom_minimum_size.x = CONTROL_MIN_WIDTH
			slider.min_value = entry["min"]
			slider.max_value = entry["max"]
			slider.step = entry["step"]
			slider.value = float(Settings.get_value(key))
			slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER

			var value_label := Label.new()
			value_label.custom_minimum_size.x = VALUE_MIN_WIDTH
			value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			value_label.text = _format_value(entry, slider.value)

			slider.value_changed.connect(func(value: float):
				value_label.text = _format_value(entry, value)
				Settings.set_value(key, value)
			)
			slider.set_meta("setting_key", key)
			slider.set_meta("value_label", value_label)
			row.add_child(slider)
			row.add_child(value_label)
		"text":
			var line_edit := LineEdit.new()
			line_edit.custom_minimum_size.x = CONTROL_MIN_WIDTH
			line_edit.max_length = entry.get("max_length", 32)
			line_edit.text = str(Settings.get_value(key))
			line_edit.text_changed.connect(func(text: String): Settings.set_value(key, text))
			line_edit.set_meta("setting_key", key)
			row.add_child(line_edit)

	return row


func _build_keybinds_section(entry: Dictionary) -> Control:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)

	var separator := HSeparator.new()
	section.add_child(separator)

	var title := Label.new()
	title.text = entry["label"]
	title.add_theme_font_size_override("font_size", 18)
	section.add_child(title)

	var hint := Label.new()
	hint.text = "Click a binding and press the new key (ESC cancels)."
	hint.modulate = Color(1, 1, 1, 0.7)
	section.add_child(hint)

	for action_entry in Settings.REBINDABLE_ACTIONS:
		var action: String = action_entry["action"]

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)

		var label := Label.new()
		label.text = action_entry["label"]
		label.custom_minimum_size.x = ROW_MIN_WIDTH
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var button := Button.new()
		button.custom_minimum_size.x = 220
		button.text = Settings.get_action_text(action)
		button.pressed.connect(_start_listening.bind(action, button))
		row.add_child(button)

		_keybind_buttons[action] = button
		section.add_child(row)

	var reset_button := Button.new()
	reset_button.text = "Reset Key Bindings"
	reset_button.pressed.connect(Settings.reset_keybinds)
	section.add_child(reset_button)

	return section


func _start_listening(action: String, button: Button) -> void:
	_cancel_listening()
	_listening_action = action
	_listening_button = button
	button.text = "Press a key..."


func _cancel_listening() -> void:
	if _listening_action == "":
		return
	if is_instance_valid(_listening_button):
		_listening_button.text = Settings.get_action_text(_listening_action)
	_listening_action = ""
	_listening_button = null


func _input(event: InputEvent) -> void:
	if _listening_action == "":
		return

	var accepted: InputEvent = null

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_cancel_listening()
			get_viewport().set_input_as_handled()
			return
		var key_event := InputEventKey.new()
		key_event.physical_keycode = event.physical_keycode
		key_event.keycode = event.keycode
		accepted = key_event
	elif event is InputEventMouseButton and event.pressed:
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = event.button_index
		accepted = mouse_event
	elif event is InputEventJoypadButton and event.pressed:
		var joy_event := InputEventJoypadButton.new()
		joy_event.button_index = event.button_index
		accepted = joy_event

	if accepted == null:
		return

	var action := _listening_action
	_listening_action = ""
	_listening_button = null
	Settings.rebind_action(action, accepted)
	_refresh_keybind_labels()
	get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- layout DEV

## Na aba DEV o painel encosta na esquerda ocupando 1/4 da tela e o fundo para
## de escurecer: dá pra mexer nos sliders vendo o jogo mudar atrás. Nas outras
## abas ele volta pro centro, do tamanho normal.
func _update_layout() -> void:
	var docked: bool = Settings.CATEGORIES[_tabs.current_tab] == "dev"
	var target: Node = _dock if docked else _center

	if _panel.get_parent() != target:
		_panel.reparent(target, false)

	_dim.visible = not docked
	_panel.custom_minimum_size = Vector2.ZERO if docked else PANEL_SIZE
	_title.text = "DEV" if docked else "Options"
	_title.add_theme_font_size_override("font_size", 20 if docked else 28)

	for side in ["left", "top", "right", "bottom"]:
		_panel_margin.add_theme_constant_override("margin_" + side, 10 if docked else 24)

	# Com clip_tabs off o TabBar exige a largura de todas as abas somadas, o que
	# estouraria o painel estreito.
	_tabs.clip_tabs = docked

	_reset_button.text = "Reset" if docked else "Reset This Tab"
	_preset_save_button.text = "Salvar" if docked else "Salvar essa configuração"
	_preset_picker.custom_minimum_size.x = 110 if docked else 170
	if docked:
		_preset_status.visible = false  # não cabe no painel estreito

	for row in _dev_rows:
		_apply_row_width(row, docked)


## 0 = volta pro tamanho do tema.
func _set_font_size(control: Control, size: int) -> void:
	if size <= 0:
		control.remove_theme_font_size_override("font_size")
	else:
		control.add_theme_font_size_override("font_size", size)


func _apply_row_width(row: Control, docked: bool) -> void:
	row.add_theme_constant_override("separation", 6 if docked else 16)

	for index in row.get_child_count():
		var child := row.get_child(index) as Control
		if child == null:
			continue
		if index == 0:  # rótulo da opção
			child.custom_minimum_size.x = DOCK_ROW_MIN_WIDTH if docked else ROW_MIN_WIDTH
			_set_font_size(child, DOCK_FONT_SIZE if docked else 0)
		elif child is Label:  # valor do slider
			child.custom_minimum_size.x = DOCK_VALUE_MIN_WIDTH if docked else VALUE_MIN_WIDTH
			_set_font_size(child, DOCK_FONT_SIZE if docked else 0)
		elif child is HSlider or child is OptionButton or child is LineEdit:
			child.custom_minimum_size.x = DOCK_CONTROL_MIN_WIDTH if docked else CONTROL_MIN_WIDTH


# ---------------------------------------------------------------- presets DEV

func _update_preset_controls() -> void:
	var is_dev: bool = Settings.CATEGORIES[_tabs.current_tab] == "dev"
	_preset_save_button.visible = is_dev
	_preset_picker.visible = is_dev
	_preset_status.visible = is_dev
	if is_dev:
		_refresh_preset_list()
	else:
		_preset_status.text = ""


func _refresh_preset_list() -> void:
	_preset_picker.clear()
	_preset_picker.add_item("Carregar preset...")
	_preset_picker.set_item_disabled(0, true)
	for preset_name in Settings.preset_names():
		_preset_picker.add_item(preset_name)
	_preset_picker.selected = 0


func _on_save_preset_pressed() -> void:
	if _preset_dialog == null:
		_preset_dialog = ConfirmationDialog.new()
		_preset_dialog.title = "Salvar configuração DEV"
		_preset_dialog.ok_button_text = "Salvar"
		_preset_dialog.cancel_button_text = "Cancelar"
		_preset_dialog.confirmed.connect(_save_current_preset)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = "Nome do preset:"
		box.add_child(label)

		_preset_name_edit = LineEdit.new()
		_preset_name_edit.custom_minimum_size.x = 280
		_preset_name_edit.max_length = 40
		_preset_name_edit.text_submitted.connect(func(_text: String):
			_preset_dialog.hide()
			_save_current_preset()
		)
		box.add_child(_preset_name_edit)

		_preset_dialog.add_child(box)
		add_child(_preset_dialog)

	_preset_name_edit.text = ""
	_preset_dialog.popup_centered()
	_preset_name_edit.grab_focus()


func _save_current_preset() -> void:
	var preset_name := _preset_name_edit.text.strip_edges()
	if Settings.save_preset(preset_name):
		_preset_status.text = "Preset \"%s\" salvo" % preset_name
		_refresh_preset_list()
	else:
		_preset_status.text = "Não deu pra salvar o preset"


func _on_preset_selected(index: int) -> void:
	if index <= 0:
		return
	var preset_name := _preset_picker.get_item_text(index)
	if Settings.load_preset(preset_name):
		_preset_status.text = "Preset \"%s\" carregado" % preset_name
		_refresh_all()
	else:
		_preset_status.text = "Não deu pra carregar o preset"
	_preset_picker.selected = 0


func _on_reset_pressed() -> void:
	var category: String = Settings.CATEGORIES[_tabs.current_tab]
	Settings.reset_category(category)
	_refresh_all()


func _refresh_keybind_labels() -> void:
	for action in _keybind_buttons:
		var button: Button = _keybind_buttons[action]
		if is_instance_valid(button):
			button.text = Settings.get_action_text(action)


func _refresh_all() -> void:
	_refresh_keybind_labels()
	_refresh_widgets(self)


func _refresh_widgets(node: Node) -> void:
	for child in node.get_children():
		if child.has_meta("setting_key"):
			var key: String = child.get_meta("setting_key")
			var value: Variant = Settings.get_value(key)
			if child is CheckButton:
				child.set_pressed_no_signal(value)
			elif child is OptionButton:
				child.selected = int(value)
			elif child is HSlider:
				child.set_value_no_signal(float(value))
				var value_label: Label = child.get_meta("value_label")
				if is_instance_valid(value_label):
					value_label.text = _format_value(Settings.find_entry(key), float(value))
			elif child is LineEdit:
				child.text = str(value)
		_refresh_widgets(child)


func _format_value(entry: Dictionary, value: float) -> String:
	if entry.is_empty():
		return str(value)
	var suffix: String = entry.get("suffix", "")
	var step: float = entry.get("step", 1.0)
	if step < 0.1:
		return "%.2f%s" % [value, suffix]
	if step < 1.0:
		return "%.1f%s" % [value, suffix]
	if entry.get("key", "") == "max_fps" and is_zero_approx(value):
		return "Off"
	return "%d%s" % [int(round(value)), suffix]
