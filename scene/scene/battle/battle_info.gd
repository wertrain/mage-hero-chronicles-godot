# バトル中の情報を保持するクラス
# 基本的にこのクラスでインスタンスを生成することはせず、外部から設定する
class_name BattleInfo
extends RefCounted

var _turn_number: int = 0
var _enemies: Array[BattleEnemy] = []
var _player: BattlePlayer

func get_player() -> BattlePlayer:
	return _player

func get_enemies() -> Array[BattleEnemy]:
	return _enemies

func get_turn_number() -> int:
	return _turn_number
	
func increment_turn() -> int:
	return _turn_number
