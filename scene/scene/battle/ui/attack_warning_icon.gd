class_name AttackWarningIcon
extends Node2D

enum Icons {
	ATTACK = Ids.IconType.IRON_SWORD,
	SHIELD = Ids.IconType.IRON_ARMOR,
	SPECIAL = Ids.IconType.MONSTER_EGG,
	CRITICAL = Ids.IconType.SKULL,
	ITEM = Ids.IconType.BLUE_POTION_2,
	BOOK = Ids.IconType.BOOK_3,
}

var _icon_type: Icons = Icons.ATTACK
var _attack_value: int = 0
var _floating_tween: Tween
# 元の位置を保持するための変数
var _original_position: Vector2

func set_icon(type: Icons, value: int) -> void:
	_icon_type = type
	_attack_value = value
	$AtlasSprite2D.set_atlas_region(type)
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
	$AtlasSprite2D.atlas_texture = load("res://art/icon/atlas_texture_rpg_weapon_tool.tres")
	$AtlasSprite2D.scale = Vector2(2.0, 2.0)
	$AtlasSprite2D.modulate = Color(1, 0, 0)
	# 元の位置を保持
	_original_position = position
	set_icon(Icons.ATTACK, 0)
	start_floating()
	set_visible(false)

func _process(_delta: float) -> void:
	pass
