class_name SequenceMessage
extends Node2D

func show_message(message: String):
	var tween_in = get_tree().create_tween()
	tween_in.set_ease(Tween.EASE_IN_OUT)
	var target_size_y = 64.0
	var rect: ColorRect = $CanvasLayer/ColorRect
	# 縦中央アンカーを保ち、sizeではなく上下オフセットで高さを変える。
	rect.offset_top = 0.0
	rect.offset_bottom = 0.0
	var animation_time = 0.3
	tween_in.set_parallel(true)
	tween_in.tween_property(rect, "offset_top", -target_size_y / 2.0, animation_time)
	tween_in.tween_property(rect, "offset_bottom", target_size_y / 2.0, animation_time)
	$CanvasLayer/ColorRect/Label.text = message
	tween_in.tween_interval(1.0)
	await tween_in.finished
	var tween_out = get_tree().create_tween()
	tween_out.set_parallel(true)
	tween_out.tween_property(rect, "offset_top", target_size_y / 2.0, animation_time / 2.0)
	tween_out.tween_property(rect, "offset_bottom", target_size_y / 2.0, animation_time / 2.0)

func _ready() -> void:
	$CanvasLayer/ColorRect.offset_top = 0.0
	$CanvasLayer/ColorRect.offset_bottom = 0.0
	$CanvasLayer/ColorRect/Label.text = ""
