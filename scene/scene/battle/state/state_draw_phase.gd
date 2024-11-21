class_name DrawPhase
extends State

var await_draw: bool 

func enter():
	var root: BattleScene = get_tree().current_scene
	var hands: Hands = root.get_hands()
	hands.set_input_enabled(false)
	await_draw = true
	await hands._first_draw(5)
	hands.set_input_enabled(true)
	await_draw = false

func update(_delta):
	if (not await_draw):
		transitioned.emit("EnemyPreparation")
