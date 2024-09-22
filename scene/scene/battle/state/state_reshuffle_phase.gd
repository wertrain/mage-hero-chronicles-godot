class_name ReshufflePhase
extends State

func enter():
	var root: BattleScene = get_tree().current_scene
	var hands: Hands = root.get_hands();
	hands._reshuffle()

func update(_delta):
	pass
