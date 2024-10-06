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
var _action: EnemyBattleAciton

func enter():
	var root: BattleScene = get_tree().current_scene
	_enemies = root.get_enemies()
	_sequence = _ActionSequence.EntryEnemy

func update(_delta: float):
	match _sequence:
		_ActionSequence.EntryEnemy:
			_action = _enemies[_action_enemy_index].get_action_queue().pop_front()
			_sequence = _ActionSequence.StartAction
		_ActionSequence.StartAction:
			var root: BattleScene = get_tree().current_scene
			ScreenEffect.play_flash_screen(root, Color.RED)
			ScreenEffect.play_shake(root.get_camera())
			_sequence = _ActionSequence.UpdateAction
		_ActionSequence.UpdateAction:
			_sequence = _ActionSequence.CheckNext
		_ActionSequence.CheckNext:
			_action_enemy_index = _action_enemy_index + 1
			if (_action_enemy_index >= _enemies.size()):
				transitioned.emit("PlayerTurnStart")
			else:
				_sequence = _ActionSequence.EntryEnemy
