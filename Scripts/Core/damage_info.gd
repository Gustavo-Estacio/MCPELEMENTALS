extends RefCounted

class_name DamageInfo

var amount: float
var source_peer_id: int
var element: ElementsEnum.Element
var knockback_dir: Vector3 = Vector3.ZERO
var knockback_force: float = 0.0
var status_effect: String = ""  # "burn", "slow", "shock", "" = nenhum
var status_duration: float = 0.0
