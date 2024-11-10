class_name BattleActionMessageWindow
extends Node2D

var _remain_time: float = 0.0

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	if visible:
		_remain_time -= delta
		if (_remain_time < 0):
			_remain_time = 0
			visible = false

func _set_message(message: String) -> void:
	$MarginContainer/MarginContainer/CenterContainer/Label.text = message

## メッセージを表示する（await 可能）
func show_message(message:String, seconds: float):
	visible = true
	_set_message(message)
	_remain_time = seconds
	return get_tree().create_timer(seconds).timeout
