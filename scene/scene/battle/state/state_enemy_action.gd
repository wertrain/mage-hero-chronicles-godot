class_name EnemyAction
extends State

enum _ActionSequence {
	EntryEnemy,
	StartAction,
	UpdateAction,
	CheckNext
}

var _sequence: _ActionSequence
var _action_enemy_index: int = 0
var _enemies: Array[BattleEnemy]
var _player: BattlePlayerStatus
var _current_action: EnemyBattleAciton
var _current_enemy: BattleEnemy
var _is_running_current_action: bool

func enter():
	var root: BattleScene = get_tree().current_scene
	_enemies = root.get_enemies()
	_player = root.get_player()
	_sequence = _ActionSequence.EntryEnemy
	_action_enemy_index = 0
	_is_running_current_action = false

func update(_delta: float):
	match _sequence:
		_ActionSequence.EntryEnemy:
			_current_enemy = _enemies[_action_enemy_index]
			_current_action = _current_enemy.get_action_queue().pop_front()
			_sequence = _ActionSequence.StartAction
		_ActionSequence.StartAction:
			_sequence = _ActionSequence.UpdateAction
			_is_running_current_action = true
			await _current_enemy.start_attack_action().finished
			_apply_action()
			_is_running_current_action = false
		_ActionSequence.UpdateAction:
			var root: BattleScene = get_tree().current_scene
			ScreenEffect.play_flash_screen(root, Color.RED)
			ScreenEffect.play_shake(root.get_camera())
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
			var damage = _current_action._value.execute_battle_action(_current_enemy.get_status())
			_player.apply_damage(damage)
	_current_enemy.hidden_warning_icon()
