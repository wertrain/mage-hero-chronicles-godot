class_name BattleAciton
extends RefCounted

enum ActionType {
	DAMAGE,
	SHIELD,
	DRAW,
	UNDEFINED
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
var _effect_type: EffectSpawner.EffectType
var _effect_index: int

func set_action_type(type: String) -> void:
	_type = _string_to_action_type(type)

func set_target_type(target: String) -> void:
	_target = _string_to_action_target(target)

func set_effect_type(type: String) -> void:
	_effect_type = _string_to_effect_type(type)

func _string_to_action_type(type: String) -> ActionType:
	match type:
		"damage": return ActionType.DAMAGE
		"shield": return ActionType.SHIELD
		"draw":   return ActionType.DRAW
	return ActionType.UNDEFINED

func _string_to_action_target(target: String) -> ActionTarget:
	match target:
		"damage":        return ActionTarget.ENEMY
		"self":          return ActionTarget.SELF
		"all_enemies":   return ActionTarget.ALL_ENEMIES
		"random_enemy":  return ActionTarget.RANDOM_ENEMY
		"all_allies":    return ActionTarget.ALL_ALLIES
	return ActionTarget.ENEMY

func _string_to_effect_type(type: String) -> EffectSpawner.EffectType:
	match type:
		"impact_a": return EffectSpawner.EffectType.IMPACT_A
		"impact_b": return EffectSpawner.EffectType.IMPACT_B
		"draw":   return EffectSpawner.EffectType.IMPACT_A
	return EffectSpawner.EffectType.IMPACT_A
