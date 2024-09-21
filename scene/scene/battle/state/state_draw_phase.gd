class_name DrawPhase
extends State

@export var actor: CharacterBody2D
@export var jump_velocity: int = -350

func enter():
	await get_tree().create_timer(0.5).timeout
	transitioned.emit("ActionSelection")
		
func update(_delta):
	pass
