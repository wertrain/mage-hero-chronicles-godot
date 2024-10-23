class_name BattleAcitonValue
extends RefCounted

enum ValueType {
	FIXED,
	CALCULATION
}

var _type: ValueType
var _expression: String

func _init(value: Dictionary) -> void:
	if value.has("type"):
		_type = _string_to_value_type(value["type"])
	if value.has("expression"):
		_expression = value["expression"]

func _string_to_value_type(value: String) -> ValueType:
	match value:
		"fixed":        return ValueType.FIXED
		"calculation":  return ValueType.CALCULATION
	return ValueType.FIXED

# バトルアクションを処理する関数
func execute_battle_action(status :BattleStatus) -> int:
	var result = 0
	if _type == BattleAcitonValue.ValueType.FIXED:
		result = float(_expression)
	elif _type == BattleAcitonValue.ValueType.CALCULATION:
		var expression = _expression
		# ステータスを数式に置換
		expression = expression.replace("current_shield", str(status.get_shield()))
		expression = expression.replace("current_attack", str(status.get_attack()))
		result = _evaluate_expression(expression)
	return result

# 数式を評価する関数
func _evaluate_expression(expression: String) -> float:
	var expr = Expression.new()
	var error = expr.parse(expression, [])
	if error != OK:
		push_error("Failed: evaluate expression")
		return 0.0
	var result = expr.execute([], null)
	return result if result != null else 0.0
