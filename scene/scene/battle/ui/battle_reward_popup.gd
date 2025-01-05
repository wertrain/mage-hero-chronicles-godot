class_name BattleRewardPopup
extends Node2D

@export var card_scene: PackedScene
# 全カードが配置される最大幅
var max_width: float = 700.0 
# カード間の最小間隔
var min_spacing: float = 150.0
# アクティブなカードのサイズ倍率
var active_card_scale: float = 1.3
var active_card_offset_y: float = 100
var active_card_animation_time: float = 0.3

var _total_gold: int = 0
var _rewarded_cards: Array[Card]
var _selectable_cards_num: int = 1
# カードの配置位置 _calculate_cards_position で計算され、枚数ごとに位置が変わる
var _card_positions: Array[Vector2]

var _button_coin: Button
var _button_card: Button
var _button_item: Button
var _button_treasure: Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CanvasLayer/ColorRect/NinePatchRect/CenterContainer/VBoxContainer/Button_Card.button_down.connect(_on_card_button_pressed)
	$CanvasLayer/ColorRect/Control_RewardSelectCard/CenterContainer/VBoxContainer/Button_Skip.button_down.connect(_on_return_to_top_button_pressed)
	_button_coin = $CanvasLayer/ColorRect/NinePatchRect/CenterContainer/VBoxContainer/Button_Coin
	if _total_gold > 0:
		_button_coin.text = tr("REWARD_GOLD") % _total_gold
	else:
		_button_coin.visible = false
	# ウィンドウの初期表示状態を適用
	$CanvasLayer/ColorRect/NinePatchRect.visible = true
	$CanvasLayer/ColorRect/Control_RewardSelectCard.visible = false
	
	$CanvasLayer/ColorRect/Control_RewardSelectCard/CenterContainer/VBoxContainer/MarginContainer_Title/MarginContainer/CenterContainer/Label.text = tr("REWARD_GET_CARD_NUM") % _selectable_cards_num
	# カードを読み込む（バトルシーンでもロードしているので共通化してもよさそう）
	var database = DataBase.new()
	var cards_origin: Array[CardData] = database.load_cards()
	for i in range(4):
		var card: Card = card_scene.instantiate()
		card.set_data(cards_origin[2])
		_rewarded_cards.push_back(card)
		$CanvasLayer/ColorRect/Control_RewardSelectCard.add_child(card)
	_calculate_cards_position(_rewarded_cards.size())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func _on_return_to_top_button_pressed():
	$CanvasLayer/ColorRect/NinePatchRect.visible = true
	$CanvasLayer/ColorRect/Control_RewardSelectCard.visible = false

func _on_card_button_pressed():
	$CanvasLayer/ColorRect/NinePatchRect.visible = false
	$CanvasLayer/ColorRect/Control_RewardSelectCard.visible = true
	var viewport_size = get_viewport().size
	var center_x = viewport_size.x / 2  # 画面の中央X座標
	var center_y = viewport_size.y / 2  # 画面の中央X座標
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	for i in range(_rewarded_cards.size()):
		var card = _rewarded_cards[i]
		card.z_index = i
		card.position = Vector2(center_x, center_y)
		card.scale = Vector2.ONE * 0.5
		var animation_time = active_card_animation_time
		tween.tween_property(card, "scale", Vector2.ONE, animation_time)
		tween.tween_property(card, "position", _card_positions[i], animation_time)
	
func _calculate_cards_position(card_count: int) -> void:
	var viewport_size = get_viewport().size
	var center_x = viewport_size.x / 2  # 画面の中央X座標
	var center_y = viewport_size.y / 2  # 画面の中央X座標
	# 最大幅を超えないようにカード間のスペースを計算
	var total_width = min(max_width, card_count * min_spacing)
	var card_spacing = 0
	if card_count > 1:
		card_spacing = total_width / (card_count - 1)
	_card_positions.clear()	
	# カードの配置を計算
	for i in range(card_count):
		# カードのX座標を計算
		var card_pos_x = center_x
		if card_count > 1:
			card_pos_x = center_x - (total_width / 2) + i * card_spacing
		# カードの位置を設定
		var card_pos = Vector2(card_pos_x, center_y)  # Y座標は固定
		_card_positions.append(card_pos)
