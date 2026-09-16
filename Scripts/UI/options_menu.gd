extends Control

class_name OptionsMenu

## Menu de opções reaproveitado pelo menu principal e pelo menu de pause.
## Os submenus (General / Graphics / Controls / Audio / Accessibility) e os
## controles de cada um são gerados a partir do Settings.SCHEMA.

signal closed

const ROW_MIN_WIDTH := 320

var _tabs: TabContainer
var _keybind_buttons := {}
var _listening_action := ""
var _listening_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	Settings.keybinds_changed.connect(_refresh_keybind_labels)
	hide()


func open() -> void:
	show()
	_refresh_all()
	_tabs.get_tab_bar().grab_focus()


func close() -> void:
	_cancel_listening()
	hide()
	closed.emit()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 520)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var title := Label.new()
	title.text = "Options"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.clip_tabs = false
	column.add_child(_tabs)

	for category in Settings.CATEGORIES:
		_tabs.add_child(_build_category(category))

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 12)
	column.add_child(footer)

	var reset_button := Button.new()
	reset_button.text = "Reset This Tab"
	reset_button.pressed.connect(_on_reset_pressed)
	footer.add_child(reset_button)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.pressed.connect(close)
	footer.add_child(back_button)


func _build_category(category: String) -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = Settings.CATEGORY_LABELS.get(category, category.capitalize())
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	for entry in Settings.SCHEMA[category]:
		if entry["type"] == "keybinds":
			list.add_child(_build_keybinds_section(entry))
		else:
			list.add_child(_build_row(entry))

	return scroll


func _build_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)

	var label := Label.new()
	label.text = entry["label"]
	label.custom_minimum_size.x = ROW_MIN_WIDTH
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
			option.custom_minimum_size.x = 220
			for item in entry["values"]:
				option.add_item(item)
			option.selected = int(Settings.get_value(key))
			option.item_selected.connect(func(index: int): Settings.set_value(key, index))
			option.set_meta("setting_key", key)
			row.add_child(option)
		"range":
			var slider := HSlider.new()
			slider.custom_minimum_size.x = 220
			slider.min_value = entry["min"]
			slider.max_value = entry["max"]
			slider.step = entry["step"]
			slider.value = float(Settings.get_value(key))
			slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER

			var value_label := Label.new()
			value_label.custom_minimum_size.x = 64
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
			line_edit.custom_minimum_size.x = 220
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
	if entry.get("step", 1.0) < 1.0:
		return "%.1f%s" % [value, suffix]
	if entry.get("key", "") == "max_fps" and is_zero_approx(value):
		return "Off"
	return "%d%s" % [int(round(value)), suffix]
