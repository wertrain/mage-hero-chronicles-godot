class_name BattleStatus
extends RefCounted

var _health: int = 100
var _max_health: int = 100
var _current_shield: int = 0
var _current_attack: int = 1
var _status_effects: Array[BattleStatusEffect]

signal health_changed(health, max_health)
signal shield_changed(shield)
signal shield_reset()
signal status_effects_changed(status_effects)
	
func get_health() -> int:
	return _health

func get_max_health() -> int:
	return _max_health
	
func get_shield() -> int:
	var total_shield = _current_shield
	for effect in get_status_effects_by_type(BattleStatusEffect.StatusEffectType.DEFENSE):
		total_shield += effect.get_value()
	return total_shield

func get_attack() -> int:
	var total_attack = _current_attack
	for effect in get_status_effects_by_type(BattleStatusEffect.StatusEffectType.OFFENSE):
		total_attack += effect.get_value()
	return total_attack

func set_health(health: int, max_health: int) -> void:
	_max_health = max_health
	_health = health

func set_shield(shield: int) -> void:
	_current_shield = shield

func set_attack(attack: int) -> void:
	_current_attack = attack

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

func add_status_effects(status_effect: BattleStatusEffect) -> void:
	_status_effects.append(status_effect)
	status_effects_changed.emit(_status_effects)

func reset_shield() -> void:
	_current_shield = 0
	shield_reset.emit()

# 特定のタイプのステータスエフェクトを取得する
func get_status_effects_by_type(type: BattleStatusEffect.StatusEffectType) -> Array[BattleStatusEffect]:
	var result: Array[BattleStatusEffect] = []
	for effect in _status_effects:
		if effect.get_type() == type:
			result.append(effect)
	return result

func has_status_effect(type: BattleStatusEffect.StatusEffectType) -> bool:
	for effect in _status_effects:
		if effect.get_type() == type:
			return true
	return false
