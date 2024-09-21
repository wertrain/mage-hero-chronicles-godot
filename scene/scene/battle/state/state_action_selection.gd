class_name ActionSelection
extends State

func enter():
	pass
		
func update(_delta):
	var hands: Hands = get_parent().get_parent().get_hands();
	if (Input.is_action_just_pressed("ui_accept")):
		if (hands._draw_card() == null):
			hands._reshuffle()

func input(event):
	var hands: Hands = get_parent().get_parent().get_hands();
	var card = hands.input_card_select(event)
	if card:
		#transitioned.emit("TargetSelection")
		transitioned.emit("PlayCard")
		hands.use_active_card()
