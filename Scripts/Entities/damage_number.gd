extends Label3D

class_name DamageNumber

## Número flutuante de dano: sobe, se espalha um pouco na horizontal e desaparece.
## Puramente cosmético — sem colisão, sem autoridade de rede própria (ver
## Global.spawn_damage_number, que é quem decide se isso deve existir pra todo mundo).

const RISE_HEIGHT := 1.3
const LIFETIME := 0.85
const HORIZONTAL_DRIFT := 0.35
# Fonte 5x menor que a original (48/68) — pedido explícito pra reduzir o tamanho do
# efeito de acerto.
const BASE_FONT_SIZE := 10
const CRIT_FONT_SIZE := 14  # dano alto (crit) sai maior, igual a maioria dos ARPGs

@export var amount: int = 0:
	set(value):
		amount = value
		_refresh_text()

@export var tint: Color = Color(1.0, 0.92, 0.55):
	set(value):
		tint = value
		modulate = value

var _elapsed := 0.0
var _start_pos: Vector3
var _drift_x: float
var _drift_z: float


func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	fixed_size = true
	outline_size = 3
	outline_modulate = Color(0, 0, 0, 0.85)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	modulate = tint
	_refresh_text()

	_start_pos = position
	_drift_x = randf_range(-HORIZONTAL_DRIFT, HORIZONTAL_DRIFT)
	_drift_z = randf_range(-HORIZONTAL_DRIFT, HORIZONTAL_DRIFT)


func _refresh_text() -> void:
	text = str(amount)
	font_size = CRIT_FONT_SIZE if amount >= 100 else BASE_FONT_SIZE


func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = clampf(_elapsed / LIFETIME, 0.0, 1.0)
	var eased_up: float = 1.0 - pow(1.0 - t, 2)  # ease-out: sobe rápido, desacelera no topo

	position = _start_pos + Vector3(_drift_x * t, RISE_HEIGHT * eased_up, _drift_z * t)
	modulate.a = 1.0 - t
	outline_modulate.a = (1.0 - t) * 0.85

	# Cada máquina remove sua própria cópia quando o timer acaba — mesmo padrão do
	# Explosion (Scripts/Entities/explosion.gd): efeito puramente cosmético, sem
	# gating de autoridade no cleanup.
	if _elapsed >= LIFETIME:
		queue_free()
