class_name Hands
extends Node

@export var card_scene: PackedScene
# 全カードが配置される最大幅
@export var max_width: float = 700.0 
# カード間の最小間隔
@export var min_spacing: float = 120.0
# カードが配置される高さ
@export var center_y: float = 700.0
# アクティブなカードのサイズ倍率
@export var active_card_scale: float = 1.3
@export var active_card_offset_y: float = 100
@export var active_card_animation_time: float = 0.1
# 山札と捨て札の座標（画面上のデッキ画像の数値を入力する）
@export var card_pile_position: Vector2
@export var discard_pile_position: Vector2

# シグナル
signal card_drawn(card_data: CardData)
signal active_card_changed(new_active_card_data: CardData)
signal deck_reshuffled
signal card_used(card_data: CardData)
signal card_discarded(card_data: CardData)
signal card_returned_to_deck(card_data: CardData)

var _player: BattlePlayerStatus
# 所持している手札カード配列
var _cards: Array[Card] = []
# マウスオーバー中、またはコントローラー操作時に操作対象の手札カード配列中のインデックス
var _active_card_index = -1
# カードの配置位置 _calculate_cards_position で計算され、枚数ごとに位置が変わる
var _card_positions: Array[Vector2]
# デッキまでの参照（親ノードがインスタンス化する）
var _card_pile: Array[CardData]
var _discard_pile: Array[CardData]
# 入力操作可能か？
var _is_enabled_input: bool

func set_field(player: BattlePlayerStatus, card_pile: Array[CardData], discard_pile: Array[CardData]) -> void:
	_player = player
	_card_pile = card_pile
	_discard_pile = discard_pile

func get_cards() -> Array[Card]:
	return _cards

func get_active_card():
	if (_active_card_index == -1):
		return null
	return _cards[_active_card_index]
	
func use_active_card() -> bool:
	if (_active_card_index == -1):
		return false
	if (!_player.try_consume_energy(_cards[_active_card_index].get_cost())):
		ScreenEffect.play_shake(_cards[_active_card_index], 0.25, 5.0)
		return false
	var use_index = _active_card_index;
	_active_card_index = -1
	_use_card(use_index)
	return true

func set_input_enabled(enabled: bool):
	_is_enabled_input = enabled

func _calculate_cards_position(card_count: int) -> void:
	var viewport_size = get_viewport().size
	var center_x = viewport_size.x / 2  # 画面の中央X座標
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

func _first_draw(card_count: int):
	_is_enabled_input = false
	# カードの配置を計算
	for i in range(card_count):
		var card_data = _card_pile.pop_front()
		if (card_data == null):
			await _reshuffle()
			_first_draw(card_count - i) # 無限ループの恐れはある
			return
		var card = card_scene.instantiate()
		card.set_data(card_data)
		card.position = card_pile_position
		card.scale = Vector2.ZERO
		_cards.push_front(card)
		add_child(card)
		await _update_card_position(_cards.size()).finished
		card_drawn.emit(card_data)
		#var card = card_scene.instantiate()
		#card.position = _card_positions[i]
		#_cards.append(card)
		#add_child(card)
	_is_enabled_input = true

func _reshuffle():
	var card_count:int = min(_discard_pile.size(), 4)
	for i in range(card_count):
		var card = card_scene.instantiate()
		card.position = discard_pile_position
		card.scale = Vector2.ONE * 0.5
		add_child(card)
		var tween = get_tree().create_tween()
		tween.set_parallel(true).set_ease(Tween.EASE_OUT)
		var animation_time = 0.2
		tween.tween_property(card, "scale", Vector2.ZERO, animation_time)
		tween.tween_property(card, "position", Vector2(card_pile_position), animation_time)
		await tween.finished
		remove_child(card)
	_card_pile.append_array(_discard_pile)
	_discard_pile.clear()
	Random.get_instance().shuffle_array(_card_pile)
	deck_reshuffled.emit()

func _ready() -> void:
	_is_enabled_input = true
	pass
	#_arrange_hand()
	#_first_draw(5)

func _process(_delta: float) -> void:
	#if (_active_card_index == -1):
	#	if (Input.is_anything_pressed()):
	#		_active_card_index = 0
	#		_set_active_card(_active_card_index, true)
	#		return
	if (not _is_enabled_input):
		return
	var current_index = _active_card_index
	if (Input.is_action_just_pressed("ui_left")):
		_active_card_index = _active_card_index - 1
		if (_active_card_index < 0):
			_active_card_index = _cards.size() - 1
		_set_active_card(current_index, false)
		_set_active_card(_active_card_index, true)
	if (Input.is_action_just_pressed("ui_right")):
		_active_card_index = _active_card_index + 1
		if (_active_card_index > _cards.size() - 1):
			_active_card_index = 0
		_set_active_card(current_index, false)
		_set_active_card(_active_card_index, true)

func input_card_select(event) -> Card:
	if (not _is_enabled_input):
		return null
	if event is InputEventMouseMotion:
		var mouse_pos = event.position
		if (_active_card_index != -1):
			var card_rect = _cards[_active_card_index].get_rect()
			if card_rect.has_point(mouse_pos):
				return null
			else:
				_set_active_card(_active_card_index, false)
		for i in range(_cards.size()):
			var card_rect = _cards[i].get_rect()
			if card_rect.has_point(mouse_pos):
				if (_active_card_index == i):
					return null
				_set_active_card(_active_card_index, false)
				_set_active_card(i, true)
				_active_card_index = i
	if event is InputEventMouseButton:
		var mouse_pos = event.position
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			for i in range(_cards.size()):
				var card_rect = _cards[i].get_rect()
				if card_rect.has_point(mouse_pos):
					if (_active_card_index == i):
						return _cards[i]
	return null

func _draw_card() -> CardData:
	var card_data = _card_pile.pop_front()
	if (card_data == null):
		return null
	_calculate_cards_position(_cards.size() + 1)
	var card = card_scene.instantiate()
	card.set_data(card_data)
	card.position = card_pile_position
	card.scale = Vector2.ZERO
	_cards.push_front(card)
	add_child(card)
	_update_card_position(_cards.size())
	card_drawn.emit(card_data)
	return card_data

func _use_card(index: int) -> void:
	var card = _cards[index]
	# カード削除アニメーションの開始
	var tween_to_center = get_tree().create_tween()
	var animation_time = active_card_animation_time * 2
	var viewport_size = get_viewport().size
	tween_to_center.set_parallel(true)
	tween_to_center.set_ease(Tween.EASE_OUT)
	tween_to_center.tween_property(card, "scale", Vector2.ONE, animation_time)
	tween_to_center.tween_property(card, "position", 
		Vector2(viewport_size.x / 2, (viewport_size.y / 2)), animation_time)
	await tween_to_center.finished
	
	var tween_action = get_tree().create_tween()
	animation_time = active_card_animation_time
	tween_action.set_ease(Tween.EASE_OUT)
	tween_action.tween_property(card, "scale", Vector2.ONE * 1.2, animation_time)
	tween_action.tween_property(card, "scale", Vector2.ONE, animation_time)
	await tween_action.finished
	
	var tween_to_discard_pile = get_tree().create_tween()
	tween_to_discard_pile.set_parallel(true)
	tween_to_discard_pile.set_ease(Tween.EASE_IN)
	animation_time = active_card_animation_time * 3
	tween_to_discard_pile.tween_property(card, "scale", Vector2.ZERO, animation_time)
	tween_to_discard_pile.tween_property(card, "position", Vector2(discard_pile_position), animation_time)
	# 配列的には先に削除しておいて並べなおす
	var data = card.get_data()
	card_used.emit(data)
	_cards.remove_at(index)
	_update_card_position(_cards.size())
	# Tween の完了を待ってノードから削除
	await tween_to_discard_pile.finished
	_discard_pile.push_back(data)
	remove_child(card)
	card_discarded.emit(data)

func _discard_card(index: int) -> void:
	var card = _cards[index]
	var tween_to_discard_pile = get_tree().create_tween()
	tween_to_discard_pile.set_parallel(true)
	tween_to_discard_pile.set_ease(Tween.EASE_IN)
	var animation_time = active_card_animation_time * 3
	tween_to_discard_pile.tween_property(card, "scale", Vector2.ZERO, animation_time)
	tween_to_discard_pile.tween_property(card, "position", Vector2(discard_pile_position), animation_time)
	# 配列的には先に削除しておいて並べなおす
	var data = card.get_data()
	_cards.remove_at(index)
	_update_card_position(_cards.size())
	# Tween の完了を待ってノードから削除
	await tween_to_discard_pile.finished
	_discard_pile.push_back(data)
	remove_child(card)
	card_discarded.emit(data)
	
func _discard_all_card() -> void:
	var tween_to_discard_pile = get_tree().create_tween()
	for index in range(_cards.size()):
		var card = _cards[index]
		tween_to_discard_pile.set_parallel(true)
		tween_to_discard_pile.set_ease(Tween.EASE_IN)
		var animation_time = active_card_animation_time * 3
		tween_to_discard_pile.tween_property(card, "scale", Vector2.ZERO, animation_time)
		tween_to_discard_pile.tween_property(card, "position", Vector2(discard_pile_position), animation_time)
	# Tween の完了を待ってノードから削除
	await tween_to_discard_pile.finished
	for card in _cards:
		var data = card.get_data()
		_discard_pile.push_back(data)
		remove_child(card)
		card_discarded.emit(data)
	_cards.clear()

# 枚数に応じたカードの位置を計算し、そこに移動させる
func _update_card_position(card_count: int) -> Tween:
	_calculate_cards_position(card_count)
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	for i in range(_cards.size()):
		var card = _cards[i]
		card.z_index = i
		var animation_time = active_card_animation_time * 3
		tween.tween_property(card, "scale", Vector2.ONE, animation_time)
		tween.tween_property(card, "position", _card_positions[i], animation_time)
	return tween
	
func _set_active_card(index: int, is_active: bool) -> void:
	if (index == -1):
		return
	if (_cards.size() <= index):
		return
	var card = _cards[index]
	for i in range(_cards.size()):
		_cards[i].z_index = i
	card.z_index = (_cards.size())
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	if (is_active):
		tween.tween_property(card, "scale", Vector2.ONE * active_card_scale, active_card_animation_time)
		tween.tween_property(card, "position",
			 _card_positions[index] + Vector2.UP * (active_card_offset_y * active_card_scale), 
			active_card_animation_time)
	else:
		tween.tween_property(card, "scale", Vector2.ONE, active_card_animation_time)
		tween.tween_property(card, "position", 
			_card_positions[index],
			active_card_animation_time)
	tween.play()
	active_card_changed.emit(card.get_data())
