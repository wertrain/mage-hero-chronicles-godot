class_name InitialDrawPhase
extends State

func enter():
	var root = get_parent().get_parent()
	root.get_hands()._first_draw(5)

func update(_delta):
	transitioned.emit("ActionSelection")
