extends PanelContainer

class_name StatsPanel

## Painel de stats mostrado à direita da tela enquanto o jogador segura TAB.
## Construído dinamicamente a partir de PlayerStats.DEFINITIONS — pra adicionar
## um stat novo basta descrever ele lá, esse painel se atualiza sozinho.

var _stats: PlayerStats
var _value_labels := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	offset_left = -260.0
	offset_right = -20.0
	offset_top = -220.0
	offset_bottom = 220.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
	_build()


func setup(stats: PlayerStats) -> void:
	_stats = stats
	_stats.stat_changed.connect(_on_stat_changed)
	_refresh_all()


func _build() -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var title := Label.new()
	title.text = "STATS"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)

	column.add_child(HSeparator.new())

	for definition in PlayerStats.DEFINITIONS:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 12)
		column.add_child(row)

		var name_label := Label.new()
		name_label.text = definition["label"]
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.custom_minimum_size.x = 150
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var value_label := Label.new()
		value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size.x = 60
		value_label.text = PlayerStats.format_value(definition["format"], definition["default"])
		row.add_child(value_label)

		_value_labels[definition["key"]] = value_label


func _refresh_all() -> void:
	if not _stats:
		return
	for definition in PlayerStats.DEFINITIONS:
		_on_stat_changed(definition["key"], _stats.get_stat(definition["key"]))


func _on_stat_changed(key: String, _value: float) -> void:
	var label: Label = _value_labels.get(key)
	if is_instance_valid(label):
		label.text = _stats.format_stat(key)
