class_name PlayerTurnEnd
extends State

func enter():
	var root: BattleScene = get_tree().current_scene
	var hands = root.get_hands()
	# 手札の破棄
	hands._discard_all_card()
	pass

func update(_delta: float):
	transitioned.emit("EnemyTurnStart")
	
