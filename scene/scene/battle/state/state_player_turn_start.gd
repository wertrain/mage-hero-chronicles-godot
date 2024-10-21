class_name PlayerTurnStart
extends State

func enter():
	var root: BattleScene = get_tree().current_scene
	root.get_sequence_message().show_message("Player's Turn")
	root.get_player().reset_energy()
	root.get_player().reset_shield()

func update(_delta):
	transitioned.emit("DrawPhase")
