class_name BattleAcitonValue
extends RefCounted

enum ValueType {
	FIXED,
	CALCULATION
}

var _type: ValueType
var _expression: String

func _init(value: Dictionary) -> void:
	_type = _string_to_value_type(value["type"])
	_expression = value["expression"]

func _string_to_value_type(value: String) -> ValueType:
	match value:
		"fixed":        return ValueType.FIXED
		"calculation":  return ValueType.CALCULATION
	return ValueType.FIXED
