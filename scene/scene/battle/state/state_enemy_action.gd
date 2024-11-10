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

func enter():
	_battle_scene = get_tree().current_scene as BattleScene
	_enemies = _battle_scene.get_enemies()
	_player = _battle_scene.get_player()
	_sequence = _ActionSequence.EntryEnemy
	_action_enemy_index = 0
	_is_running_current_action = false
	_is_show_message = false

func update(_delta: float):
	match _sequence:
		_ActionSequence.EntryEnemy:
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
			_action_enemy_index = _action_enemy_index + 1
			if (_action_enemy_index >= _enemies.size()):
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
			var damage = _current_action._value.execute_battle_action(_current_enemy.get_status())
			_player.apply_damage(damage)
		EnemyBattleAciton.ActionType.ATTACK_UP:
			# 敵のスプライトアニメーション
			_is_running_current_action = true
			await _current_enemy.start_attack_action(SpriteAnimator.AnimationType.JUMP_SLAM).finished
			_is_running_current_action = false
			# 攻撃力アップの値計算
			var value = _current_action._value.execute_battle_action(_current_enemy.get_status())
			# 対象の決定と反映
			match _current_action._target:
				EnemyBattleAciton.ActionTarget.SELF:
					_current_enemy.get_status().add_status_effects(
						BattleStatusEffect.new(BattleStatusEffect.StatusEffectType.ATTACK, value))
	_current_enemy.hidden_warning_icon()

## アクションを反映させる
func _apply_screen_effect():
	var root: BattleScene = get_tree().current_scene
	match _current_action._type:
		EnemyBattleAciton.ActionType.ATTACK:
			ScreenEffect.play_flash_screen(root, Color.RED)
			ScreenEffect.play_shake(root.get_camera())
		EnemyBattleAciton.ActionType.ATTACK_UP:
			ScreenEffect.play_shake(root.get_camera())
