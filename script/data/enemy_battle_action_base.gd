# Json で定義される敵の行動パターンのベースクラス
# 攻撃のタイプと対象、行動によって発生する効果を持つ
# 通常の攻撃パターンと、複数ターンにわたる攻撃パターンに分岐する
class_name EnemyBattleAcitonBase
extends RefCounted

enum ActionType {
	ATTACK,
	SHIELD,
	BUFF,
	DEBUFF,
	MULTI_TURN_ACTION,
	UNDEFINED
}

enum ActionTarget {
	PLAYER,
	SELF,
	ALL_PLAYERS,
	RANDOM_ALLIES,
	ALL_ALLIES
}

var _name: String
var _type: ActionType
var _target: ActionTarget
var _value: BattleAcitonValue

func get_name() -> String:
	return _name

func set_name(name: String) -> void:
	_name = name

func set_action_type(type: String) -> void:
	_type = _string_to_action_type(type)

func set_target_type(target: String) -> void:
	_target = _string_to_action_target(target)

func get_value() -> BattleAcitonValue:
	return _value

func set_value(value: BattleAcitonValue) -> void:
	_value = value

func _string_to_action_type(type: String) -> ActionType:
	match type:
		"attack": return ActionType.ATTACK
		"shield": return ActionType.SHIELD
		"buff": return ActionType.BUFF
		"debuff": return ActionType.DEBUFF
		"multi_turn_action": return ActionType.MULTI_TURN_ACTION
	return ActionType.UNDEFINED

func _string_to_action_target(target: String) -> ActionTarget:
	match target:
		"player":        return ActionTarget.PLAYER
		"self":          return ActionTarget.SELF
		"all_players":   return ActionTarget.ALL_PLAYERS
		"random_allies": return ActionTarget.RANDOM_ALLIES
		"all_allies":    return ActionTarget.ALL_ALLIES
	return ActionTarget.PLAYER
