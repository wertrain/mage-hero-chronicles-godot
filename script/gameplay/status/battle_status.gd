class_name BattleStatus
extends RefCounted

var _health: int = 100
var _max_health: int = 100
var _current_shield: int = 0

signal health_changed(health, max_health)
signal shield_changed(shield)
	
func get_health() -> int:
	return _health

func get_max_health() -> int:
	return _max_health
	
func get_shield() -> int:
	return _current_shield

func set_health(health: int, max_health: int) -> void:
	_max_health = max_health
	_health = health

func set_shield(shield: int) -> void:
	_current_shield = shield

func apply_damage(value: int) -> bool:
	var damage_value = value
	if _current_shield > 0 and damage_value > 0:
		if damage_value >= _current_shield:
			damage_value -= _current_shield
			_current_shield = 0
		else:
			_current_shield -= damage_value
			damage_value = 0
		shield_changed.emit(_current_shield)
	if damage_value > 0:
		_health -= damage_value
		if _health <= 0:
			_health = 0
		health_changed.emit(_health, _max_health)
	return _health > 0

func add_shield(amount: int) -> void:
	_current_shield += amount
	shield_changed.emit(_current_shield)
