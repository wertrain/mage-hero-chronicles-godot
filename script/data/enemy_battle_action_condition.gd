# Json で定義される敵の攻撃パターンの発生条件
class_name EnemyBattleAcitonCondition
extends RefCounted

enum ConditionType {
	HP_BELOW,
	TURN_NUMBER,
	PLAYER_STATUS,
	RANDOM_CHANCE,
	UNDEFINED
}

var _type: ConditionType
var _expression: String

func set_condition_type(type: String) -> void:
	_type = _string_to_condition_type(type)

func _string_to_condition_type(type: String) -> ConditionType:
	match type:
		"hp_below":      return ConditionType.HP_BELOW
		"turn_number":   return ConditionType.TURN_NUMBER
		"player_status": return ConditionType.PLAYER_STATUS
		"random_chance": return ConditionType.RANDOM_CHANCE
	return ConditionType.UNDEFINED
