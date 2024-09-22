class_name EnemyTurnStart
extends State

func enter():
	var root: BattleScene = get_tree().current_scene
	await root.get_sequence_message().show_message("Enemy's Turn")
