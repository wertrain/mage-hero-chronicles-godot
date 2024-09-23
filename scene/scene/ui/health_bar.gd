class_name HealthBar
extends Node2D

func set_health(health: int, max_health: int):
	$TextureProgressBar.max_value = max_health
	$TextureProgressBar.value = health
	$TextureProgressBar/Label.text = "%d/%d" % [health, max_health]

func get_health() -> int:
	return $TextureProgressBar.value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
