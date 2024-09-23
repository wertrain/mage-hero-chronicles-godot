class_name BattleAciton
extends RefCounted

enum ActionType {
	DAMAGE,
	SHIELD,
	DRAW
}

enum ActionTarget {
	ENEMY,
	SELF,
	ALL_ENEMIES,
	RANDOM_ENEMY,
	ALL_ALLIES
}

var _type: ActionType
var _target: ActionTarget
var _value: int
var _turns: int
