class_name BattleEnemy
extends Node2D
	
func get_sprite() -> Sprite2D:
	return $Sprite2D

func get_sprite_rect():
	return $Sprite2D.get_rect()
	
func shake():
	$Shake2D.play_shake()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
