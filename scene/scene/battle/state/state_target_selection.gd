class_name TargetSelection
extends State

@export var arrow_scene: PackedScene

var arrow

func enter():
	arrow = arrow_scene.instantiate();
	arrow.z_index = 10
	add_child(arrow)
	var root: BattleScene = get_tree().current_scene
	var hands: Hands = root.get_hands();
	
	var card = hands.get_active_card()
	arrow.start_point = card.position
	var viewport_size = get_viewport().size
	var center = viewport_size / 2  # 画面の中央X座標
	arrow.end_point = center
	pass

func exit():
	remove_child(arrow)

func update(_delta):
	pass

func input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			transitioned.emit("ActionSelection")
