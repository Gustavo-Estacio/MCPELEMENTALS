extends Control

class_name HealthBar

## Barra de vida do player, sempre visível no canto inferior esquerdo da tela.

var _max_health := 1.0
var _current_health := 1.0

var _bar: ProgressBar
var _label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = 20.0
	offset_top = -60.0
	offset_right = 260.0
	offset_bottom = -20.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func setup(current_health: float, max_health: float) -> void:
	_current_health = current_health
	_max_health = max(max_health, 1.0)
	_refresh()


func set_max_health(value: float) -> void:
	_max_health = max(value, 1.0)
	_refresh()


func set_health(value: float) -> void:
	_current_health = clamp(value, 0.0, _max_health)
	_refresh()


func _build() -> void:
	_bar = ProgressBar.new()
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.show_percentage = false
	_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bar.min_value = 0.0
	add_child(_bar)

	var style_bg := StyleBoxFlat.new()
	style_bg.bg_color = Color(0.1, 0.1, 0.1, 0.6)
	style_bg.corner_radius_top_left = 4
	style_bg.corner_radius_top_right = 4
	style_bg.corner_radius_bottom_left = 4
	style_bg.corner_radius_bottom_right = 4
	_bar.add_theme_stylebox_override("background", style_bg)

	var style_fill := StyleBoxFlat.new()
	style_fill.bg_color = Color(0.85, 0.15, 0.15, 0.95)
	style_fill.corner_radius_top_left = 4
	style_fill.corner_radius_top_right = 4
	style_fill.corner_radius_bottom_left = 4
	style_fill.corner_radius_bottom_right = 4
	_bar.add_theme_stylebox_override("fill", style_fill)

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)


func _refresh() -> void:
	if not is_instance_valid(_bar):
		return
	_bar.max_value = _max_health
	_bar.value = _current_health
	_label.text = "%d / %d" % [round(_current_health), round(_max_health)]
