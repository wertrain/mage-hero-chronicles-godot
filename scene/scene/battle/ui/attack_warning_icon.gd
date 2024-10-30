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
var _floating_tween: Tween
# 元の位置を保持するための変数
var _original_position: Vector2

func set_icon(type: Icons, value: int) -> void:
	_icon_type = type
	_attack_value = value
	$AnimatedSprite2D.play(_icon_map[type])
	$Label.visible = not (value == 0)
	$Label.text = "%d" % value	

func start_floating():
	var float_distance = 5  # 小さな上下動き
	var duration = 1.0  # アニメーションの速さ
	_floating_tween = get_tree().create_tween()
	_floating_tween.tween_property(self, "position", _original_position + Vector2(0, -float_distance), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_floating_tween.tween_property(self, "position", _original_position + Vector2(0, +float_distance), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_floating_tween.set_loops(0)

func stop_floating():
	if (_floating_tween != null and _floating_tween.is_running()):
		_floating_tween.stop()

func _ready() -> void:
	# 元の位置を保持
	_original_position = position
	set_icon(Icons.ATTACK, 0)
	start_floating()
	set_visible(false)

func _process(_delta: float) -> void:
	pass
