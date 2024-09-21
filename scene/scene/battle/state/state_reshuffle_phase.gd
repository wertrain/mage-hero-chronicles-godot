class_name ReshufflePhase
extends State

func enter():
	var root = get_parent().get_parent()
	root.get_hands()._reshuffle()

func update(_delta):
	pass
