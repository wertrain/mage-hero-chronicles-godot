class_name AttackWarningIcon
extends Node2D

enum Icons {
	ATTACK,
	SPECIAL,
	INCANTATION,
	CRITICAL,
	DEADLY,
	UPPER,
	DOWNER,
	ERUPTION
}

var _icon_map: Dictionary = {
	Icons.ATTACK: "sword",
	Icons.SPECIAL: "mysterious",
	Icons.INCANTATION: "incantation",
	Icons.CRITICAL: "critical",
	Icons.DEADLY: "deadly",
	Icons.UPPER: "upper",
	Icons.DOWNER: "downer",
	Icons.ERUPTION: "eruption"
}

var _icon_type: Icons = Icons.ATTACK
var _attack_value: int = 0
# 元の位置を保持するための変数
var _original_position: Vector2
var _float_elapsed: float = 0.0

func set_icon(type: Icons, value: int) -> void:
	_icon_type = type
	_attack_value = value
	$AnimatedSprite2D.play(_icon_map[type])
	$Label.visible = not (value == 0)
	$Label.text = "%d" % value	

func _ready() -> void:
	# 元の位置を保持
	_original_position = position
	_float_elapsed = 0.0
	set_icon(Icons.ATTACK, 0)
	set_visible(false)

func _process(delta: float) -> void:
	# Tweenの無限ループに頼らず、予告アイコンを滑らかに上下させる。
	if not visible:
		return
	_float_elapsed += delta
	position = _original_position + Vector2(0, sin(_float_elapsed * TAU / 2.0) * 5.0)
