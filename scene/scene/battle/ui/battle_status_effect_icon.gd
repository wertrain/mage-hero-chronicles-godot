class_name BattleStatusEffectIcon
extends Node2D

enum Icons {
	None,
	ATTACK_UP,
	ATTACK_DOWN,
	DEFENCE_UP,
	DEFENCE_DOWN,
}

var _icon_type: Icons = Icons.None
var _attack_value: int = 0

var _settings = [
	preload("res://art/settings/label_settings_battle_status_up.tres"),
	preload("res://art/settings/label_settings_battle_status_down.tres"),
]

static func get_icon_type(type: BattleStatusEffect.StatusEffectType, value: int) -> Icons:
	match type:
		BattleStatusEffect.StatusEffectType.OFFENSE:
			return Icons.ATTACK_UP if value >= 0 else Icons.ATTACK_DOWN
		BattleStatusEffect.StatusEffectType.DEFENSE:
			return Icons.DEFENCE_UP if value >= 0 else Icons.DEFENCE_DOWN
	return Icons.None

func add_icon(type: BattleStatusEffect.StatusEffectType, value: int) -> bool:
	var icon_type = get_icon_type(type, value)
	if (icon_type == Icons.None):
		return false
	_icon_type = icon_type
	_attack_value = value
	$AtlasSprite2D.frame = _icon_type
	$Label.visible = not (value == 0)
	var setting_index = 0 if value >= 0 else 1
	$Label.label_settings = _settings[setting_index]
	$Label.text = "%d" % value
	return true
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
