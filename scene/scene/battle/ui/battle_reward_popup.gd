class_name BattleRewardPopup
extends Node2D

signal reward_completed

@export var card_scene: PackedScene

var max_width: float = 700.0
var min_spacing: float = 150.0
var active_card_animation_time: float = 0.3
var _total_gold: int
var _rewarded_cards: Array[Card] = []
var _rewarded_items: Array[ItemData] = []
var _card_positions: Array[Vector2] = []
var _player: BattlePlayerStatus
var _completed: bool = false

func _ready() -> void:
	# 報酬画面は戦闘シーンから敵・プレイヤー情報を受け取り、選択肢を作る。
	var menu_path := "CanvasLayer/ColorRect/Control_RewardMenu/NinePatchRect/CenterContainer/VBoxContainer/"
	get_node(menu_path + "Button_Card").pressed.connect(_on_card_button_pressed)
	get_node(menu_path + "Button_Item").pressed.connect(_on_item_button_pressed)
	get_node("CanvasLayer/ColorRect/Control_RewardMenu/Button_Skip").pressed.connect(_complete_reward)
	get_node("CanvasLayer/ColorRect/Control_RewardSelectCard/CenterContainer/VBoxContainer/Button_Skip").pressed.connect(_on_return_to_top_button_pressed)
	get_node("CanvasLayer/ColorRect/Control_RewardSelectItem/CenterContainer/VBoxContainer/Button_Skip").pressed.connect(_on_return_to_top_button_pressed)
	var battle: BattleScene = get_tree().current_scene as BattleScene
	_player = battle.get_player()
	_total_gold = 0
	# 複数敵戦では倒した敵全員のゴールドを合算してランに加える。
	for enemy in battle.get_enemies():
		_total_gold += enemy.get_data().gold
	RunData.add_gold(_total_gold)

	var coin_button: Button = get_node(menu_path + "Button_Coin")
	coin_button.text = "+" + (tr("REWARD_GOLD") % _total_gold)
	coin_button.disabled = true
	get_node(menu_path + "Button_Treasure").visible = false
	get_node("CanvasLayer/ColorRect/Control_RewardSelectCard/CenterContainer/VBoxContainer/MarginContainer_Title/MarginContainer/CenterContainer/Label").text = tr("REWARD_GET_CARD_NUM") % 1
	get_node("CanvasLayer/ColorRect/Control_RewardSelectItem/CenterContainer/VBoxContainer/MarginContainer_Title/MarginContainer/CenterContainer/Label").text = tr("REWARD_GET_ITEM_NUM") % 1

	var database := DataBase.new()
	var card_data := database.load_cards()
	# 全カードから3枚を候補として引き、選択された1枚だけRunDataのデッキへ追加する。
	card_data.shuffle()
	var card_count: int = mini(3, card_data.size())
	for index in range(card_count):
		var card: Card = card_scene.instantiate()
		card.set_data(card_data[index])
		_rewarded_cards.append(card)
		get_node("CanvasLayer/ColorRect/Control_RewardSelectCard").add_child(card)
	_calculate_cards_position(card_count)

	_rewarded_items = database.load_items()
	_build_item_choices()
	get_node(menu_path + "Button_Card").visible = not _rewarded_cards.is_empty()
	get_node(menu_path + "Button_Item").visible = not _rewarded_items.is_empty()
	get_node("CanvasLayer/ColorRect/Control_RewardMenu").visible = true
	get_node("CanvasLayer/ColorRect/Control_RewardSelectCard").visible = false
	get_node("CanvasLayer/ColorRect/Control_RewardSelectItem").visible = false

func _input(event: InputEvent) -> void:
	if _completed or not (event is InputEventMouseButton):
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not get_node("CanvasLayer/ColorRect/Control_RewardSelectCard").visible:
		return
	var mouse_position := get_viewport().get_mouse_position()
	for card in _rewarded_cards:
		if card.get_rect().has_point(mouse_position):
			get_viewport().set_input_as_handled()
			RunData.add_card(card.get_data())
			_complete_reward()
			return

func _build_item_choices() -> void:
	var area: MarginContainer = get_node("CanvasLayer/ColorRect/Control_RewardSelectItem/CenterContainer/VBoxContainer/MarginContainer_ItemArea")
	var choices := VBoxContainer.new()
	choices.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choices.add_theme_constant_override("separation", 12)
	area.add_child(choices)
	for item in _rewarded_items:
		var button := Button.new()
		button.custom_minimum_size = Vector2(420, 64)
		button.text = item.name + " — " + item.description
		button.pressed.connect(_claim_item.bind(item))
		choices.add_child(button)

func _claim_item(item: ItemData) -> void:
	# 現在実装しているアイテム効果は回復なので、戦闘後にその場で適用して報酬を閉じる。
	for action in item.actions:
		if action.get_type() == BattleAciton.ActionType.HEAL:
			var amount: int = action.get_value().execute_battle_action(_player)
			_player.heal(amount)
	_complete_reward()

func _on_return_to_top_button_pressed() -> void:
	$StateMachine.current_state.transitioned.emit("RewardSelectTop")
	$CanvasLayer/ColorRect/Control_RewardMenu.visible = true
	$CanvasLayer/ColorRect/Control_RewardSelectCard.visible = false
	$CanvasLayer/ColorRect/Control_RewardSelectItem.visible = false

func _on_card_button_pressed() -> void:
	$StateMachine.current_state.transitioned.emit("RewardSelectCard")
	$CanvasLayer/ColorRect/Control_RewardMenu.visible = false
	$CanvasLayer/ColorRect/Control_RewardSelectCard.visible = true
	var center: Vector2 = get_viewport().size / 2.0
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	for index in range(_rewarded_cards.size()):
		var card := _rewarded_cards[index]
		card.z_index = index
		card.position = center
		card.scale = Vector2.ONE * 0.5
		tween.tween_property(card, "scale", Vector2.ONE, active_card_animation_time)
		tween.tween_property(card, "position", _card_positions[index], active_card_animation_time)

func _on_item_button_pressed() -> void:
	$StateMachine.current_state.transitioned.emit("RewardSelectItem")
	$CanvasLayer/ColorRect/Control_RewardMenu.visible = false
	$CanvasLayer/ColorRect/Control_RewardSelectItem.visible = true

func _complete_reward() -> void:
	# ボタン連打などによる重複遷移を防ぎ、報酬完了をBattleSceneへ通知する。
	if _completed:
		return
	_completed = true
	reward_completed.emit()
	queue_free()

func _calculate_cards_position(card_count: int) -> void:
	var center: Vector2 = get_viewport().size / 2.0
	var total_width: float = minf(max_width, card_count * min_spacing)
	var spacing: float = total_width / float(card_count - 1) if card_count > 1 else 0.0
	_card_positions.clear()
	for index in range(card_count):
		var x: float = center.x if card_count == 1 else center.x - total_width / 2.0 + index * spacing
		_card_positions.append(Vector2(x, center.y))
