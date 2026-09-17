extends HBoxContainer

class_name SpellSlotBar

## Barra com os slots Q e E, arrastáveis entre si (só funciona enquanto TAB
## está sendo segurado — nesse momento o mouse fica livre pra arrastar).
## Arrastar o slot E pro Q (ou vice-versa) troca a ordem: a spell que estava
## no E passa a ser conjurada apertando Q, e vice-versa.
##
## Isso NÃO troca o keybind físico (isso continua no menu de Options) — só
## troca qual spell cada tecla conjura, através de Player.spell_slots_swapped.

signal slots_swapped

const SLOT_SIZE := Vector2(72, 72)

var _player: Player
var _slot_q: PanelContainer
var _slot_e: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_constant_override("separation", 10)
	hide()

	_slot_q = _make_slot("q_slot")
	_slot_e = _make_slot("e_slot")
	add_child(_slot_q)
	add_child(_slot_e)


func setup(player: Player) -> void:
	_player = player
	refresh()


func refresh() -> void:
	if not _player:
		return
	_set_slot_text(_slot_q, "Q", _player.get_ability_name_for_key("q"))
	_set_slot_text(_slot_e, "E", _player.get_ability_name_for_key("e"))


func _make_slot(slot_id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = SLOT_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_script(preload("res://Scripts/UI/spell_slot.gd"))
	panel.owner_bar = self
	panel.slot_id = slot_id

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(column)

	var key_label := Label.new()
	key_label.name = "KeyLabel"
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 18)
	column.add_child(key_label)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 10)
	column.add_child(name_label)

	return panel


func _set_slot_text(panel: PanelContainer, key_letter: String, ability_name: String) -> void:
	var column := panel.get_child(0)
	var key_label: Label = column.get_node("KeyLabel")
	var name_label: Label = column.get_node("NameLabel")
	key_label.text = key_letter
	name_label.text = ability_name


# Chamado pelos slots (spell_slot.gd) quando um drag termina em cima do outro.
func swap_slots() -> void:
	if not _player:
		return
	_player.toggle_spell_slots()
	refresh()
	slots_swapped.emit()
