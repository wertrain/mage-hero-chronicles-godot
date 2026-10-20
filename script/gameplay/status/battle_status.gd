class_name BattleStatus
extends RefCounted

var _health: int = 100
var _max_health: int = 100
var _current_shield: int = 0
var _current_attack: int = 1
var _status_effects: Array[BattleStatusEffect]
var _turn_serial: int = 0
var _effect_application_turns: Dictionary = {}

signal health_changed(health, max_health)
signal shield_changed(shield)
signal shield_reset()
signal status_effects_changed(status_effects)
	
func get_health() -> int:
	return _health

func get_max_health() -> int:
	return _max_health

func get_turn_serial() -> int:
	return _turn_serial
	
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

func get_attack_bonus() -> int:
	# 固定ダメージの攻撃にも、攻撃力上昇・低下分を加えるための補正値。
	var bonus := 0
	for effect in get_status_effects_by_type(BattleStatusEffect.StatusEffectType.OFFENSE):
		bonus += effect.get_value()
	return bonus

func set_health(health: int, max_health: int) -> void:
	_max_health = max_health
	_health = health

func set_shield(shield: int) -> void:
	_current_shield = shield

func set_attack(attack: int) -> void:
	_current_attack = attack

func apply_damage(value: int) -> bool:
	var damage_value = value
	var defense_changed := false
	if _current_shield > 0 and damage_value > 0:
		if damage_value >= _current_shield:
			damage_value -= _current_shield
			_current_shield = 0
		else:
			_current_shield -= damage_value
			damage_value = 0
		shield_changed.emit(_current_shield)
	# 防御状態もシールドとして消費し、表示上の防御値と実際の被ダメージを一致させる。
	for effect in get_status_effects_by_type(BattleStatusEffect.StatusEffectType.DEFENSE):
		if damage_value <= 0:
			break
		var absorbed: int = mini(damage_value, maxi(0, effect.get_value()))
		if absorbed <= 0:
			continue
		damage_value -= absorbed
		effect.set_value(effect.get_value() - absorbed)
		defense_changed = true
		if effect.get_value() <= 0:
			_status_effects.erase(effect)
			_effect_application_turns.erase(effect)
	if defense_changed:
		status_effects_changed.emit(_status_effects)
	if damage_value > 0:
		_health -= damage_value
		if _health <= 0:
			_health = 0
		health_changed.emit(_health, _max_health)
	return _health > 0

func add_shield(amount: int) -> void:
	_current_shield += amount
	shield_changed.emit(_current_shield)

func heal(amount: int) -> void:
	if amount <= 0 or _health <= 0:
		return
	_health = mini(_health + amount, _max_health)
	health_changed.emit(_health, _max_health)

func add_status_effects(status_effect: BattleStatusEffect) -> void:
	if status_effect == null:
		return
	# 毒・火傷は強さを足し合わせる。発動時に強さが1ずつ減るため、
	# まとめておけば「毒2を付与後に毒3を付与」=「毒5」として扱える。
	if status_effect.get_type() in [BattleStatusEffect.StatusEffectType.POISONED, BattleStatusEffect.StatusEffectType.BURNED]:
		if status_effect.get_duration_type() == BattleStatusEffect.EffectDurationType.PERSISTENT:
			for existing_effect in _status_effects:
				if existing_effect.get_type() != status_effect.get_type():
					continue
				if existing_effect.get_duration_type() != BattleStatusEffect.EffectDurationType.PERSISTENT:
					continue
				existing_effect.set_value(existing_effect.get_value() + maxi(0, status_effect.get_value()))
				status_effects_changed.emit(_status_effects)
				return
	_status_effects.append(status_effect)
	_effect_application_turns[status_effect] = _turn_serial
	status_effects_changed.emit(_status_effects)

func add_timed_status_effect(type: BattleStatusEffect.StatusEffectType, value: int, turns: int) -> void:
	# 0ターン指定は戦闘中持続、1以上は対象のターン終了時に残り時間を減らす。
	var effect := BattleStatusEffect.new(type, value)
	if turns > 0:
		effect.set_duration_type(BattleStatusEffect.EffectDurationType.TURN_BASED)
		effect.set_remaining_turns(turns)
	add_status_effects(effect)

func apply_turn_start_effects() -> bool:
	# 毒・火傷は持ち主のターン開始時にダメージ、再生は回復を行う。
	var changed := false
	for effect in _status_effects.duplicate():
		if effect.get_type() == BattleStatusEffect.StatusEffectType.REGEN:
			heal(maxi(0, effect.get_value()))
			continue
		if effect.get_type() in [BattleStatusEffect.StatusEffectType.POISONED, BattleStatusEffect.StatusEffectType.BURNED]:
			apply_damage(maxi(0, effect.get_value()))
			# 毒・火傷はダメージ後に強度が1減り、0になれば消える。
			effect.set_value(effect.get_value() - 1)
			changed = true
			if effect.get_value() <= 0:
				_status_effects.erase(effect)
				_effect_application_turns.erase(effect)
			if _health <= 0:
				if changed:
					status_effects_changed.emit(_status_effects)
				return false
	if changed:
		status_effects_changed.emit(_status_effects)
	return true

func advance_status_effects() -> void:
	# ターン終了時に持続効果だけを進め、切れた効果をアイコン表示からも取り除く。
	var changed := false
	for index in range(_status_effects.size() - 1, -1, -1):
		var effect: BattleStatusEffect = _status_effects[index]
		# このターン中に付与した効果は、使い手のターンが終わっただけでは減らさない。
		if int(_effect_application_turns.get(effect, -1)) == _turn_serial:
			continue
		if effect.get_duration_type() != BattleStatusEffect.EffectDurationType.TURN_BASED:
			continue
		effect.set_remaining_turns(effect.get_remaining_turns() - 1)
		if effect.get_remaining_turns() <= 0:
			_status_effects.remove_at(index)
			_effect_application_turns.erase(effect)
		changed = true
	if changed:
		status_effects_changed.emit(_status_effects)

func begin_turn() -> void:
	# 付与されたターンを記録し、効果時間が丸々使われる前に減るのを防ぐ。
	_turn_serial += 1

func consume_turn_blocker() -> bool:
	# 麻痺・凍結・気絶は次の行動機会を止め、有限効果なら通常のターン終了処理で減衰する。
	for effect in _status_effects:
		if effect.get_type() in [BattleStatusEffect.StatusEffectType.PARALYZED, BattleStatusEffect.StatusEffectType.FROZEN, BattleStatusEffect.StatusEffectType.STUNNED]:
			return true
	return false

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
