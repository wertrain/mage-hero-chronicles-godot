class_name BattleStatus
extends RefCounted

var _health: int = 100
var _max_health: int = 100
var _current_shield: int = 0

signal health_changed(health, max_life)
	
func get_health() -> int:
	return _health

func get_max_life() -> int:
	return _max_health
	
func get_shield() -> int:
	return _current_shield

func set_health(health: int, max_health: int)-> void:
	_max_health = max_health
	_health = health

func damage(damage_value: int) -> bool:
	_health -= damage_value
	if _health <= 0:
		_health -= 0
	health_changed.emit(_health, _max_health)
	return _health > 0
