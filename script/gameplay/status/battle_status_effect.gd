class_name BattleStatusEffect
extends RefCounted

enum StatusEffectType {
	ATTACK,
	DEFENCE,
}

enum EffectDurationType {
	PERSISTENT,  # 永続
	TURN_BASED   # ターン経過で消える
}

var _type: StatusEffectType = StatusEffectType.ATTACK
var _value: int = 0
var _duration_type: EffectDurationType = EffectDurationType.PERSISTENT  # 持続時間のタイプ
var _remaining_turns: int = 0

func _init(type: StatusEffectType, value: int) -> void:
	_type = type
	_value = value

func get_type() -> StatusEffectType:
	return _type

func get_value() -> int:
	return _value

func get_duration_type() -> EffectDurationType:
	return _duration_type

func set_duration_type(value: EffectDurationType) -> void:
	_duration_type = value

func get_remaining_turns() -> int:
	return _remaining_turns

func set_remaining_turns(value: int) -> void:
	_remaining_turns = value
