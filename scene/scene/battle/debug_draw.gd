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
	# ゲームUIの配置に影響しないよう、デバッグ情報は画面右上にまとめる。
	var panel_size := Vector2(300, 76)
	var panel_position := Vector2(get_viewport_rect().size.x - panel_size.x - 12, 12)
	draw_rect(Rect2(panel_position, panel_size), Color(0.025, 0.035, 0.055, 0.78), true)
	var font := SystemFont.new()
	var text_x := panel_position.x + 10
	var height := panel_position.y + 20
	draw_string(font, Vector2(text_x, height), "[Enabled DebugDraw]")
	height += 22
	draw_string(font, Vector2(text_x, height), "seed: %012d" % current_seed)
	height += 22
	draw_string(font, Vector2(text_x, height), "Ctrl+Shift+K: Force battle victory")

	#for card in $"../Hands".get_cards():
	#	draw_rect(card.get_rect(), Color.RED, true, 3.0)
