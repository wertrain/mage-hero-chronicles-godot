class_name SequenceMessage
extends Node2D

func show_message(message: String):
	var tween_in = get_tree().create_tween()
	tween_in.set_ease(Tween.EASE_IN_OUT)
	var viewport_size = get_viewport().size
	var target_size_y = 64.0
	$CanvasLayer/ColorRect.position.y = (viewport_size.y / 2.0) - (target_size_y / 2.0)
	$CanvasLayer/ColorRect.size.x = viewport_size.x
	$CanvasLayer/ColorRect.size.y = 0
	var size = $CanvasLayer/ColorRect.size
	var rect_position = $CanvasLayer/ColorRect.position
	var animation_time = 0.3
	tween_in.set_parallel(true)
	tween_in.tween_property($CanvasLayer/ColorRect, "position", Vector2(rect_position.x , rect_position.y - target_size_y / 2.0), animation_time)
	tween_in.tween_property($CanvasLayer/ColorRect, "size", Vector2(size.x, target_size_y), animation_time)
	$CanvasLayer/ColorRect/Label.text = message
	tween_in.tween_interval(1.0)
	await tween_in.finished
	var tween_out = get_tree().create_tween()
	tween_out.set_parallel(true)
	tween_out.tween_property($CanvasLayer/ColorRect, "position", Vector2(rect_position.x , rect_position.y + target_size_y / 2.0), animation_time)
	tween_out.tween_property($CanvasLayer/ColorRect, "size", Vector2(size.x, 0), animation_time / 2.0)

func _ready() -> void:
	$CanvasLayer/ColorRect.set_deferred("size", Vector2.ZERO)
	$CanvasLayer/ColorRect/Label.text = ""
	pass

func _process(_delta: float) -> void:
	pass
