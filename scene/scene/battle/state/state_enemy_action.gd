class_name EnemyAction
extends State

enum _ActionSequence {
	EntryEnemy,
	StartAction,
	ShowActionName,
	UpdateAction,
	CheckNext,
	Wait
}

var _battle_scene: BattleScene
var _sequence: _ActionSequence
var _action_enemy_index: int = 0
var _enemies: Array[BattleEnemy]
var _player: BattlePlayerStatus
var _current_action: EnemyBattleAcitonBase
var _current_enemy: BattleEnemy
var _is_running_current_action: bool
var _is_show_message: bool
var _turn_blocked_enemies: Dictionary = {}

func enter():
	_battle_scene = get_tree().current_scene as BattleScene
	_enemies = _battle_scene.get_enemies()
	_player = _battle_scene.get_player()
	_sequence = _ActionSequence.EntryEnemy
	_turn_blocked_enemies.clear()
	# 敵ターン開始時に毒・火傷を処理し、倒れた敵は行動対象から除外する。
	for enemy in _enemies:
		if enemy.is_dead():
			continue
		enemy.get_status().begin_turn()
		if not enemy.get_status().apply_turn_start_effects():
			enemy.get_status().add_status_effects(BattleStatusEffect.new(BattleStatusEffect.StatusEffectType.DEAD, 0))
			ScreenEffect.play_fadeout(enemy)
			_battle_scene.trigger_relic_hook(RunData.RelicHook.ENEMY_DEFEATED, {"player": _player, "enemy": enemy})
		elif enemy.get_status().consume_turn_blocker():
			_turn_blocked_enemies[enemy.get_instance_id()] = true
			enemy.get_action_queue().clear()
			enemy.hidden_warning_icon()
	# 生きている敵だけを先頭から順に行動させる。
	_action_enemy_index = _get_next_enemy_index(0)
	_is_running_current_action = false
	_is_show_message = false

func update(_delta: float):
	match _sequence:
		_ActionSequence.EntryEnemy:
			if _action_enemy_index < 0:
				var has_living_enemy := false
				for enemy in _enemies:
					if not enemy.is_dead():
						has_living_enemy = true
						enemy.get_status().advance_status_effects()
				if not has_living_enemy:
					# 毒などのターン開始効果で敵が全滅した場合は勝利判定へ送る。
					transitioned.emit("CheckVictoryOrDefeat")
				elif _player.get_health() <= 0:
					transitioned.emit("GameOver")
				else:
					# 行動阻害で敵全員の手番が飛んだ場合も、敵ターンを終えて戻る。
					transitioned.emit("PlayerTurnStart")
				return
			_current_enemy = _enemies[_action_enemy_index]
			_current_action = _current_enemy.get_action_queue().pop_front()	
			_sequence = _ActionSequence.ShowActionName
		_ActionSequence.ShowActionName:
			_current_enemy.hidden_warning_icon()
			_sequence = _ActionSequence.Wait
			var message_duration: float = 1.5
			await _battle_scene.show_action_message(_current_action.get_name(), message_duration, _current_enemy.position)
			_sequence = _ActionSequence.StartAction
		_ActionSequence.StartAction:
			_sequence = _ActionSequence.UpdateAction
			_apply_action()
		_ActionSequence.UpdateAction:
			_apply_screen_effect()
			_sequence = _ActionSequence.CheckNext
		_ActionSequence.CheckNext:
			if _is_running_current_action:
				return
			_action_enemy_index = _get_next_enemy_index(_action_enemy_index + 1)
			# 敵全員の行動後に、敗北判定かプレイヤーターンへ移る。
			if (_action_enemy_index < 0):
				# 敵の行動が終わったところで、敵側に付いた一時効果の残りターンを進める。
				for enemy in _enemies:
					if not enemy.is_dead():
						enemy.get_status().advance_status_effects()
				if _player.get_health() <= 0:
					transitioned.emit("GameOver")
				else:
					transitioned.emit("PlayerTurnStart")
			else:
				_sequence = _ActionSequence.EntryEnemy

## アクションを反映させる
func _apply_action():
	match _current_action._type:
		EnemyBattleAciton.ActionType.ATTACK:
			# 敵のスプライトアニメーション
			_is_running_current_action = true
			await _current_enemy.start_attack_action(SpriteAnimator.AnimationType.FORWARD_SCALE).finished
			_is_running_current_action = false
			# ダメージ計算
			var enemy_status: BattleStatus = _current_enemy.get_status()
			var damage: int = _current_action._value.execute_battle_action(enemy_status)
			# 計算式攻撃はcurrent_attack経由ですでに補正されるため、固定値攻撃だけに加算する。
			if _current_action._value._type == BattleAcitonValue.ValueType.FIXED:
				damage += enemy_status.get_attack_bonus()
			_player.apply_damage(damage)
		EnemyBattleAciton.ActionType.ATTACK_UP:
			# 攻撃強化は大きく跳ねる攻撃ではなく、力を溜める動きで予告内容と合わせる。
			_is_running_current_action = true
			await _current_enemy.start_action_animation(SpriteAnimator.AnimationType.CHARGE_SCALE).finished
			_is_running_current_action = false
			var attack_up_value: int = _current_action._value.execute_battle_action(_current_enemy.get_status())
			_apply_status_to_targets(BattleStatusEffect.StatusEffectType.OFFENSE, attack_up_value)
		EnemyBattleAciton.ActionType.SHIELD:
			# 身を固める動きを見せてから防御を付け、プレイヤーが次のターンに攻撃で削れるようにする。
			_is_running_current_action = true
			await _current_enemy.start_action_animation(SpriteAnimator.AnimationType.DEFEND).finished
			_is_running_current_action = false
			var shield_value: int = _current_action._value.execute_battle_action(_current_enemy.get_status())
			_apply_status_to_targets(BattleStatusEffect.StatusEffectType.DEFENSE, maxi(0, shield_value))
		EnemyBattleAciton.ActionType.ATTACK_DOWN, EnemyBattleAciton.ActionType.DEBUFF:
			_is_running_current_action = true
			await _current_enemy.start_action_animation(SpriteAnimator.AnimationType.CAST).finished
			_is_running_current_action = false
			var attack_down_value: int = _current_action._value.execute_battle_action(_current_enemy.get_status())
			_apply_status_to_targets(BattleStatusEffect.StatusEffectType.OFFENSE, -absi(attack_down_value))
		EnemyBattleAciton.ActionType.POISON:
			_is_running_current_action = true
			await _current_enemy.start_action_animation(SpriteAnimator.AnimationType.CAST).finished
			_is_running_current_action = false
			var poison_value: int = _current_action._value.execute_battle_action(_current_enemy.get_status())
			_apply_status_to_targets(BattleStatusEffect.StatusEffectType.POISONED, absi(poison_value))
	_current_enemy.hidden_warning_icon()

func _apply_status_to_targets(effect_type: BattleStatusEffect.StatusEffectType, value: int) -> void:
	# 敵行動の対象指定に合わせ、プレイヤーにも敵にも同じ効果処理を適用する。
	var targets: Array[BattleStatus] = []
	match _current_action._target:
		EnemyBattleAciton.ActionTarget.SELF:
			targets.append(_current_enemy.get_status())
		EnemyBattleAciton.ActionTarget.ALL_ALLIES:
			for enemy in _enemies:
				if not enemy.is_dead():
					targets.append(enemy.get_status())
		EnemyBattleAciton.ActionTarget.RANDOM_ALLIES:
			var allies: Array[BattleEnemy] = []
			for enemy in _enemies:
				if not enemy.is_dead():
					allies.append(enemy)
			if not allies.is_empty():
				var selected_ally: BattleEnemy = Random.get_instance().pick_array_item(allies) as BattleEnemy
				targets.append(selected_ally.get_status())
		_:
			targets.append(_player)
	for target_status in targets:
		target_status.add_timed_status_effect(effect_type, value, _current_action.get_turns())

## アクションを反映させる
func _apply_screen_effect():
	var root: BattleScene = get_tree().current_scene
	match _current_action._type:
		EnemyBattleAciton.ActionType.ATTACK:
			ScreenEffect.play_flash_screen(root, Color.RED)
			ScreenEffect.play_shake(root.get_camera())
		EnemyBattleAciton.ActionType.ATTACK_UP:
			ScreenEffect.play_flash(_current_enemy, Color(1.0, 0.82, 0.35))
		EnemyBattleAciton.ActionType.SHIELD:
			ScreenEffect.play_flash(_current_enemy, Color(0.55, 0.8, 1.0))
		EnemyBattleAciton.ActionType.POISON:
			ScreenEffect.play_flash(_current_enemy, Color(0.55, 1.0, 0.45))
		EnemyBattleAciton.ActionType.ATTACK_DOWN, EnemyBattleAciton.ActionType.DEBUFF:
			ScreenEffect.play_flash(_current_enemy, Color(0.8, 0.65, 1.0))

func _get_next_enemy_index(start_index: int) -> int:
	for index in range(start_index, _enemies.size()):
		if not _enemies[index].is_dead() and not _turn_blocked_enemies.has(_enemies[index].get_instance_id()):
			return index
	return -1
