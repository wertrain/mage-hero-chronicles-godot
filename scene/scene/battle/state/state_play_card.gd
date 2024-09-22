class_name PlayCard
extends State

func enter():
	var root: BattleScene = get_tree().current_scene
	root.get_monster().shake()
	await get_tree().create_timer(1).timeout
	transitioned.emit("ActionSelection")
