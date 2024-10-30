class_name BattleStatusEffectIcon
extends Node2D

enum Icons {
	ATTACK_UP,
	ATTACK_DOWN,
	DEFENCE_UP,
	DEFENCE_DOWN,
}

var _icon_type: Icons = Icons.ATTACK_UP
var _attack_value: int = 0

var _settings = [
	preload("res://art/settings/label_settings_battle_status_up.tres"),
	preload("res://art/settings/label_settings_battle_status_down.tres"),
]

func set_icon(type: BattleStatusEffect.StatusEffectType, value: int) -> void:
	var icon_type = Icons.ATTACK_UP
	match type:
		BattleStatusEffect.StatusEffectType.ATTACK:
			icon_type = Icons.ATTACK_UP if value >= 0 else Icons.ATTACK_DOWN
		BattleStatusEffect.StatusEffectType.DEFENCE:
			icon_type = Icons.DEFENCE_UP if value >= 0 else Icons.DEFENCE_DOWN	
	_icon_type = _icon_type
	_attack_value = value
	$AtlasSprite2D.frame = _icon_type
	$Label.visible = not (value == 0)
	var setting_index = 0 if value >= 0 else 1
	$Label.label_settings = _settings[setting_index]
	$Label.text = "%d" % value	
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
