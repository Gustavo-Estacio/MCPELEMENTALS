extends PanelContainer

class_name SpellSlot

## Um slot individual (Q ou E) da SpellSlotBar. Usa o drag-and-drop nativo do
## Godot: segurar e arrastar um slot em cima do outro troca a ordem das spells.

var owner_bar: SpellSlotBar
var slot_id: String = ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = slot_id.to_upper().left(1)
	preview.add_theme_font_size_override("font_size", 24)
	set_drag_preview(preview)
	return {"slot_id": slot_id}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("slot_id", "") != "" and data.get("slot_id", "") != slot_id


func _drop_data(_at_position: Vector2, _data: Variant) -> void:
	if owner_bar:
		owner_bar.swap_slots()
