class_name HealthBar
extends Node2D

var current_shield: int = 0
var shield_bar_texture = preload("res://art/ui/bar/bar_blue.png")
var normal_bar_texture = preload("res://art/ui/bar/bar_red.png")

func set_health(health: int, max_health: int) -> void:
	$TextureProgressBar.max_value = max_health
	$TextureProgressBar.value = health
	$TextureProgressBar/Label.text = "%d/%d" % [health, max_health]
	$Sprite2D_Shield.visible = current_shield > 0
	$Sprite2D_Shield/Label_Shield.text = "%d" % current_shield
	
func set_shield(shield: int) -> void:
	current_shield = shield
	$Sprite2D_Shield/Label_Shield.text  = "%d" % current_shield
	$Sprite2D_Shield.visible = current_shield > 0
	if $Sprite2D_Shield.visible:
		$TextureProgressBar.texture_progress = shield_bar_texture
	else:
		$TextureProgressBar.texture_progress = normal_bar_texture

func get_health() -> int:
	return $TextureProgressBar.value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
