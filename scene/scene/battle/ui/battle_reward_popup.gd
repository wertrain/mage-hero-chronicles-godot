class_name BattleRewardPopup
extends Node2D

var _total_gold: int = 0
var _rewarded_cards: Array[Card]
var _selectable_cards_num: int = 1

var _button_coin: Button
var _button_card: Button
var _button_item: Button
var _button_treasure: Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CanvasLayer/ColorRect/NinePatchRect/CenterContainer/VBoxContainer/Button_Card.button_down.connect(_on_button_pressed)
	_button_coin = $CanvasLayer/ColorRect/NinePatchRect/CenterContainer/VBoxContainer/Button_Coin
	if _total_gold > 0:
		_button_coin.text = tr("REWARD_GOLD") % _total_gold
	else:
		_button_coin.visible = false
	$CanvasLayer/ColorRect/Control/CenterContainer/VBoxContainer/MarginContainer_Title/MarginContainer/CenterContainer/Label.text = tr("REWARD_GET_CARD_NUM") % _selectable_cards_num
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_button_pressed():
	print("ボタンが押されました！")
