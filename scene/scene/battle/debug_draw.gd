class_name DebugDraw
extends Node2D

var current_seed: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _draw() -> void:
	var height = 30
	draw_string(SystemFont.new(), Vector2(30, height), "[Enabled DebugDraw]")
	height += 30
	draw_string(SystemFont.new(), Vector2(30, height), "seed: %012d" % current_seed)

	#for card in $"../Hands".get_cards():
	#	draw_rect(card.get_rect(), Color.RED, true, 3.0)
