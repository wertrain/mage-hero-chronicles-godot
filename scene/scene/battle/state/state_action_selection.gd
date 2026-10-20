class_name ActionSelection
extends State

func enter():
	var root: BattleScene = get_tree().current_scene
	var hands: Hands = root.get_hands()
	hands.set_input_enabled(true)
	root.set_end_turn_enabled(true)
		
func update(_delta):
	pass
	#var root: BattleScene = get_tree().current_scene
	#var hands: Hands = root.get_hands()
	#if (Input.is_action_just_pressed("ui_accept")):
	#	if (hands._draw_card() == null):
	#		hands._reshuffle()

func input(event):
	var root: BattleScene = get_tree().current_scene
	var hands: Hands = root.get_hands()
	var card = hands.input_card_select(event)
	if card:
		if (not hands.is_use_active_card()):
			return
		hands.set_input_enabled(false)
		root.set_end_turn_enabled(false)
		var params = {"card": card}
		transitioned_with_param.emit("TargetSelection", params)
