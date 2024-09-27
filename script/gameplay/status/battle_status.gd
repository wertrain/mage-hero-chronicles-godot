class_name BattleStatus
extends RefCounted

var _life: int = 100
var _max_life: int = 100
var _current_shield: int = 0

signal life_changed(life, max_life)
	
func get_life() -> int:
	return _life

func get_max_life() -> int:
	return _max_life
	
func get_shield() -> int:
	return _current_shield

func damage(damage_value: int) -> bool:
	_life -= damage_value
	if _life <= 0:
		_life -= 0
	life_changed.emit(_life, _max_life)
	return _life > 0
