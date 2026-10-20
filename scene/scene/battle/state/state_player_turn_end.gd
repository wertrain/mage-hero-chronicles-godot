class_name PlayerTurnEnd
extends State

var _ready_for_enemy_turn: bool = false

func enter():
	var root: BattleScene = get_tree().current_scene
	_ready_for_enemy_turn = false
	root.set_end_turn_enabled(false)
	var hands: Hands = root.get_hands()
	# 手札の退場と捨て札移動が終わってから敵ターンへ進み、非同期処理の重なりを防ぐ。
	await hands._discard_all_card()
	# このターン終了時点で一時効果を減らし、残りターン0の効果を外す。
	root.get_player().advance_status_effects()
	_ready_for_enemy_turn = true

func update(_delta: float):
	if _ready_for_enemy_turn:
		_ready_for_enemy_turn = false
		transitioned.emit("EnemyTurnStart")
	
