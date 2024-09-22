class_name ActionSelection
extends State

func enter():
	pass
		
func update(_delta):
	var root: BattleScene = get_tree().current_scene
	var hands: Hands = root.get_hands()
	if (Input.is_action_just_pressed("ui_accept")):
		if (hands._draw_card() == null):
			hands._reshuffle()

func input(event):
	var root: BattleScene = get_tree().current_scene
	var hands: Hands = root.get_hands()
	var card = hands.input_card_select(event)
	if card:
		#transitioned.emit("TargetSelection")
		if (hands.use_active_card()):
			transitioned.emit("PlayCard")
