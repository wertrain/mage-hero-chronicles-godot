class_name CheckVictoryOrDefeat
extends State

var isMessageShown: bool

func enter():
	var root: BattleScene = get_tree().current_scene
	isMessageShown = false
	await root.get_sequence_message().show_message("VICTORY")
	isMessageShown = true

func update(_delta: float):
	if isMessageShown:
		transitioned.emit("ActionSelection")
