class_name ElementsEnum

# Sistema centralizado de enumerações para o sistema elemental
# Acesso: ElementsEnum.Element.FIRE, ElementsEnum.Slot.PROJECTILE

enum Element {
	FIRE = 0,
	WATER = 1,
	EARTH = 2,
	AIR = 3,
	ELECTRIC = 4,
}

enum Slot {
	AUTO_ATTACK = 0,      # LMB
	SPECIAL_ATTACK = 1,   # RMB
	PROJECTILE = 2,       # Q
	SPECIAL_SKILL = 3,    # E
	DASH = 4,             # SHIFT
	JUMP = 5,             # SPACE
	ULTIMATE = 6,         # R
}

static func get_element_name(elem: int) -> String:
	return Element.keys()[elem]


static func get_slot_name(slot: int) -> String:
	return Slot.keys()[slot]
