extends Control

class_name SkillHUD

## HUD de cooldowns e cargas, centralizada embaixo no meio da tela.
##
## A HUD é burra de propósito: todo frame ela lê Player.get_skill_slots() e só
## desenha. Quem sabe o que é cooldown, carga ou skill ativa é o Player.

const SLOT_SIZE := Vector2(43.0, 43.0)
const SLOT_SEPARATION := 5
const BOTTOM_MARGIN := 12.0
const MAX_SLOTS := 6
const MAX_PIPS := 5

const ELEMENT_COLORS := {
	ElementsEnum.Element.EARTH: Color(0.78, 0.55, 0.28),
	ElementsEnum.Element.FIRE: Color(1.0, 0.45, 0.2),
	ElementsEnum.Element.AIR: Color(0.7, 0.88, 1.0),
	ElementsEnum.Element.WATER: Color(0.35, 0.75, 1.0),
}

var _player: Player
var _row: HBoxContainer
var _slots: Array[Control] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Ancoragem na mão: set_anchors_preset() preserva o tamanho atual (zero) nos
	# offsets, e a faixa acabaria com largura 0 encostada na esquerda.
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_right = 0.0
	offset_top = -(SLOT_SIZE.y + 18.0 + BOTTOM_MARGIN)
	offset_bottom = -BOTTOM_MARGIN
	_build()


func setup(player: Player) -> void:
	_player = player


func _build() -> void:
	_row = HBoxContainer.new()
	_row.anchor_left = 0.0
	_row.anchor_top = 0.0
	_row.anchor_right = 1.0
	_row.anchor_bottom = 1.0
	_row.offset_left = 0.0
	_row.offset_top = 0.0
	_row.offset_right = 0.0
	_row.offset_bottom = 0.0
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override("separation", SLOT_SEPARATION)
	add_child(_row)

	for index in MAX_SLOTS:
		var slot := _build_slot()
		_slots.append(slot)
		_row.add_child(slot)


func _build_slot() -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.size_flags_vertical = Control.SIZE_SHRINK_END
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Pips de carga ficam acima do quadrado, fora dele.
	var pips := HBoxContainer.new()
	pips.name = "Pips"
	pips.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	pips.offset_top = -7.0
	pips.offset_bottom = -3.0
	pips.alignment = BoxContainer.ALIGNMENT_CENTER
	pips.add_theme_constant_override("separation", 2)
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(pips)

	for index in MAX_PIPS:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(6.0, 2.5)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.add_child(pip)

	var body := Control.new()
	body.name = "Body"
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.clip_contents = true  # o preenchimento não pode vazar pelas bordas
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(body)

	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.05, 0.05, 0.07, 0.72)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(background)

	# Sobe de baixo pra cima conforme a skill recarrega: cheio = pronto.
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.anchor_left = 0.0
	fill.anchor_right = 1.0
	fill.anchor_top = 1.0
	fill.anchor_bottom = 1.0
	fill.offset_left = 0.0
	fill.offset_right = 0.0
	fill.offset_top = 0.0
	fill.offset_bottom = 0.0
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(fill)

	var border := Panel.new()
	border.name = "Border"
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border_style := StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)
	border_style.set_border_width_all(1)
	border_style.set_corner_radius_all(3)
	border.add_theme_stylebox_override("panel", border_style)
	slot.add_child(border)

	var key_label := Label.new()
	key_label.name = "Key"
	key_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	key_label.offset_top = 3.0
	key_label.offset_bottom = 14.0
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 8)
	key_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	key_label.add_theme_constant_override("shadow_offset_x", 1)
	key_label.add_theme_constant_override("shadow_offset_y", 1)
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(key_label)

	var time_label := Label.new()
	time_label.name = "Time"
	time_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 10)
	time_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	time_label.add_theme_constant_override("shadow_offset_x", 1)
	time_label.add_theme_constant_override("shadow_offset_y", 1)
	time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(time_label)

	var name_label := Label.new()
	name_label.name = "SkillName"
	name_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_label.offset_top = -11.0
	name_label.offset_bottom = -2.0
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 6)
	name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(name_label)

	return slot


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return

	var slots: Array = _player.get_skill_slots()
	var element_color: Color = ELEMENT_COLORS.get(_player.player_element, Color.WHITE)

	for index in _slots.size():
		var slot_node := _slots[index]
		if index >= slots.size():
			slot_node.visible = false
			continue
		slot_node.visible = true
		_update_slot(slot_node, slots[index], element_color)


func _update_slot(slot_node: Control, data: Dictionary, element_color: Color) -> void:
	var ratio: float = data["ratio"]
	var charges: int = data["charges"]
	var max_charges: int = data["max_charges"]
	var active: bool = data["active"]
	var ready_to_use: bool = (ratio >= 1.0 or active) and (charges != 0)

	var fill: ColorRect = slot_node.get_node("Body/Fill")
	fill.anchor_top = clampf(1.0 - ratio, 0.0, 1.0)
	if active:
		fill.color = Color(element_color.r, element_color.g, element_color.b, 0.75)
	elif ready_to_use:
		fill.color = Color(element_color.r, element_color.g, element_color.b, 0.45)
	else:
		fill.color = Color(element_color.r, element_color.g, element_color.b, 0.28)

	var border: Panel = slot_node.get_node("Border")
	var border_style: StyleBoxFlat = border.get_theme_stylebox("panel")
	border_style.border_color = element_color if ready_to_use else Color(0.35, 0.35, 0.4, 0.9)

	var key_label: Label = slot_node.get_node("Key")
	key_label.text = data["key"]
	key_label.modulate = Color.WHITE if ready_to_use else Color(1, 1, 1, 0.55)

	var name_label: Label = slot_node.get_node("SkillName")
	name_label.text = data["name"]
	name_label.modulate = Color(1, 1, 1, 0.85 if ready_to_use else 0.5)

	var time_label: Label = slot_node.get_node("Time")
	var remaining: float = data["remaining"]
	time_label.text = "%.1f" % remaining if remaining > 0.0 else ""

	var pips: HBoxContainer = slot_node.get_node("Pips")
	pips.visible = max_charges > 0
	for pip_index in pips.get_child_count():
		var pip: ColorRect = pips.get_child(pip_index)
		pip.visible = pip_index < max_charges
		pip.color = element_color if pip_index < charges else Color(0.25, 0.25, 0.3, 0.9)
