class_name InitialDrawPhase
extends State

func enter():
	var root: BattleScene = get_tree().current_scene
	var hands: Hands = root.get_hands()
	hands._first_draw(5)

func update(_delta):
	transitioned.emit("EnemyPreparation")
