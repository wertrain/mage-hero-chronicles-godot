class_name BattleStatusEffectIcon
extends Node2D

enum Icons {
	None,
	ATTACK_UP,
	ATTACK_DOWN,
	DEFENCE_UP,
	DEFENCE_DOWN,
	EFFECT,
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
		BattleStatusEffect.StatusEffectType.DEAD:
			return Icons.None
	return Icons.EFFECT

func add_icon(type: BattleStatusEffect.StatusEffectType, value: int, remaining_turns: int = 0) -> bool:
	var icon_type = get_icon_type(type, value)
	if (icon_type == Icons.None):
		return false
	_icon_type = icon_type
	_attack_value = value
	$AtlasSprite2D.visible = icon_type != Icons.EFFECT
	if icon_type != Icons.EFFECT:
		# このスプライトはフレーム分割ではなくAtlasTextureなので、アトラス領域を切り替える。
		$AtlasSprite2D.set_atlas_region(int(_icon_type))
	$Label.visible = icon_type == Icons.EFFECT or value != 0
	var setting_index = 1 if icon_type == Icons.EFFECT or value < 0 else 0
	$Label.label_settings = _settings[setting_index]
	$Label.text = _status_label(type, value)
	# アイコンにカーソルを合わせると、数値が何を意味するか確認できる。
	$Label.mouse_filter = Control.MOUSE_FILTER_STOP
	$Label.tooltip_text = tr(_status_tooltip_key(type))
	if remaining_turns > 0:
		$Label.text += " (%d)" % remaining_turns
		$Label.tooltip_text += "\n" + (tr("BATTLE_STATUS_REMAINING_TURNS") % remaining_turns)
	if icon_type == Icons.EFFECT:
		# 「再生4 (3)」のような長い表示もラベル上でホバー判定できる幅を確保する。
		$Label.position = Vector2(-40, -2)
		$Label.size = Vector2(80, 22)
	return true

func _status_label(type: BattleStatusEffect.StatusEffectType, value: int) -> String:
	match type:
		BattleStatusEffect.StatusEffectType.POISONED:
			return tr("BATTLE_STATUS_POISONED_LABEL") % value
		BattleStatusEffect.StatusEffectType.BURNED:
			return tr("BATTLE_STATUS_BURNED_LABEL") % value
		BattleStatusEffect.StatusEffectType.REGEN:
			return tr("BATTLE_STATUS_REGEN_LABEL") % value
		BattleStatusEffect.StatusEffectType.PARALYZED:
			return tr("BATTLE_STATUS_PARALYZED_LABEL") % value
		BattleStatusEffect.StatusEffectType.CONFUSED:
			return tr("BATTLE_STATUS_CONFUSED_LABEL") % value
		BattleStatusEffect.StatusEffectType.FROZEN:
			return tr("BATTLE_STATUS_FROZEN_LABEL") % value
		BattleStatusEffect.StatusEffectType.STUNNED:
			return tr("BATTLE_STATUS_STUNNED_LABEL") % value
	return (tr("BATTLE_STATUS_VALUE_LABEL") % value)

func _status_tooltip_key(type: BattleStatusEffect.StatusEffectType) -> String:
	match type:
		BattleStatusEffect.StatusEffectType.OFFENSE:
			return "BATTLE_STATUS_OFFENSE_TOOLTIP"
		BattleStatusEffect.StatusEffectType.DEFENSE:
			return "BATTLE_STATUS_DEFENSE_TOOLTIP"
		BattleStatusEffect.StatusEffectType.POISONED:
			return "BATTLE_STATUS_POISONED_TOOLTIP"
		BattleStatusEffect.StatusEffectType.BURNED:
			return "BATTLE_STATUS_BURNED_TOOLTIP"
		BattleStatusEffect.StatusEffectType.REGEN:
			return "BATTLE_STATUS_REGEN_TOOLTIP"
		BattleStatusEffect.StatusEffectType.PARALYZED:
			return "BATTLE_STATUS_PARALYZED_TOOLTIP"
		BattleStatusEffect.StatusEffectType.CONFUSED:
			return "BATTLE_STATUS_CONFUSED_TOOLTIP"
		BattleStatusEffect.StatusEffectType.FROZEN:
			return "BATTLE_STATUS_FROZEN_TOOLTIP"
		BattleStatusEffect.StatusEffectType.STUNNED:
			return "BATTLE_STATUS_STUNNED_TOOLTIP"
	return "BATTLE_STATUS_VALUE_TOOLTIP"
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
