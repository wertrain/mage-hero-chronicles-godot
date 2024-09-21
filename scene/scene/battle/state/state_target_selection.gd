class_name TargetSelection
extends State

@export var arrow_scene: PackedScene

var arrow

func enter():
	arrow = arrow_scene.instantiate();
	arrow.z_index = 10
	add_child(arrow)
	var card = $"../../Hands".get_active_card()
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
		var mouse_pos = event.position
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			transitioned.emit("ActionSelection")
