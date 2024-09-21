class_name PlayCard
extends State

func enter():
	var root = get_parent().get_parent()
	root.get_monster().shake()
	await get_tree().create_timer(1).timeout
	root.get_monster().shake()
	await get_tree().create_timer(1).timeout
	transitioned.emit("ActionSelection")
