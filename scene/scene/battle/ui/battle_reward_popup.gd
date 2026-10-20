class_name BattleRewardPopup
extends Node2D

signal reward_completed

@export var card_scene: PackedScene

var _total_gold: int
var _rewarded_cards: Array[CardData] = []
var _rewarded_items: Array[ItemData] = []
var _rewarded_relic: RelicData
var _card_choice_view: CardChoiceView
var _completed: bool = false
var _gold_reward_resolved: bool = false
var _card_reward_resolved: bool = false
var _item_reward_resolved: bool = false
var _relic_reward_resolved: bool = false

func _ready() -> void:
	# 報酬画面は戦闘シーンから敵・プレイヤー情報を受け取り、選択肢を作る。
	var menu_path := "CanvasLayer/ColorRect/Control_RewardMenu/NinePatchRect/CenterContainer/VBoxContainer/"
	get_node(menu_path + "Button_Coin").pressed.connect(_claim_gold)
	get_node(menu_path + "Button_Card").pressed.connect(_on_card_button_pressed)
	get_node(menu_path + "Button_Item").pressed.connect(_on_item_button_pressed)
	get_node(menu_path + "Button_Treasure").pressed.connect(_on_relic_button_pressed)
	get_node("CanvasLayer/ColorRect/Control_RewardMenu/Button_Skip").pressed.connect(_complete_reward)
	get_node("CanvasLayer/ColorRect/Control_RewardSelectCard/CenterContainer/VBoxContainer/Button_Skip").pressed.connect(_skip_card_reward)
	get_node("CanvasLayer/ColorRect/Control_RewardSelectItem/CenterContainer/VBoxContainer/Button_Skip").pressed.connect(_skip_item_reward)
	# 報酬と休憩所の強化画面で同じカード選択Viewを使う。
	var card_area: Control = get_node("CanvasLayer/ColorRect/Control_RewardSelectCard/CenterContainer/VBoxContainer/MarginContainer_CardsArea")
	_card_choice_view = CardChoiceView.new()
	_card_choice_view.card_scene = card_scene
	# 報酬は候補が少ないため、一覧グリッドではなく従来どおり大きなカードを横並びにする。
	_card_choice_view.show_panel_background = false
	_card_choice_view.card_selected.connect(_on_card_choice_selected)
	_card_choice_view.visible = false
	card_area.add_child(_card_choice_view)
	_card_choice_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var battle: BattleScene = get_tree().current_scene as BattleScene
	_total_gold = 0
	# 複数敵戦では倒した敵全員のゴールドを合算してランに加える。
	for enemy in battle.get_enemies():
		_total_gold += enemy.get_data().gold
	# 所持レリックの勝利報酬ボーナスを、通常の敵ゴールドに加える。
	_total_gold += RunData.get_battle_victory_gold()

	var coin_button: Button = get_node(menu_path + "Button_Coin")
	coin_button.text = "+" + (tr("REWARD_GOLD") % _total_gold)
	var relic_button: Button = get_node(menu_path + "Button_Treasure")
	relic_button.visible = false
	get_node("CanvasLayer/ColorRect/Control_RewardSelectCard/CenterContainer/VBoxContainer/MarginContainer_Title/MarginContainer/CenterContainer/Label").text = tr("REWARD_GET_CARD_NUM") % 1
	get_node("CanvasLayer/ColorRect/Control_RewardSelectItem/CenterContainer/VBoxContainer/MarginContainer_Title/MarginContainer/CenterContainer/Label").text = tr("REWARD_GET_ITEM_NUM") % 1

	var database := DataBase.new()
	# ボスとエリートのレリックも、受け取るまでは報酬メニューの選択肢として保持する。
	if RunData.current_battle_is_boss or RunData.current_battle_is_elite:
		var available_relics: Array[RelicData] = []
		for relic in database.load_relics():
			if not RunData.has_relic(relic.guid):
				available_relics.append(relic)
		Random.get_instance().shuffle_array(available_relics)
		if not available_relics.is_empty():
			_rewarded_relic = available_relics[0]
			relic_button.text = tr("REWARD_GET_TREASURE")
			relic_button.tooltip_text = "%s\n%s" % [_rewarded_relic.name, _rewarded_relic.description]
			relic_button.visible = true
	var card_data := database.load_cards_for_job(RunData.current_job)
	# 現在の職業のカードから3枚を候補として引く。転職前に得たカードはデッキに残る。
	Random.get_instance().shuffle_array(card_data)
	var card_count: int = mini(3, card_data.size())
	for index in range(card_count):
		_rewarded_cards.append(card_data[index])
	_card_choice_view.set_cards(_rewarded_cards)

	_rewarded_items = database.load_items()
	_build_item_choices()
	get_node("CanvasLayer/ColorRect/Control_RewardMenu").visible = true
	get_node("CanvasLayer/ColorRect/Control_RewardSelectCard").visible = false
	get_node("CanvasLayer/ColorRect/Control_RewardSelectItem").visible = false
	_refresh_reward_menu()

func _build_item_choices() -> void:
	var area: MarginContainer = get_node("CanvasLayer/ColorRect/Control_RewardSelectItem/CenterContainer/VBoxContainer/MarginContainer_ItemArea")
	var choices := VBoxContainer.new()
	choices.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choices.add_theme_constant_override("separation", 12)
	for child in area.get_children():
		child.queue_free()
	area.add_child(choices)
	for item in _rewarded_items:
		var button := Button.new()
		button.custom_minimum_size = Vector2(420, 64)
		button.text = item.name + " — " + item.description
		button.pressed.connect(_claim_item.bind(item))
		choices.add_child(button)

func _claim_item(item: ItemData) -> void:
	# 報酬画面では効果を即時発動せず、所持品へ加えて次の戦闘で使えるようにする。
	if _item_reward_resolved or not RunData.add_item(item):
		return
	_item_reward_resolved = true
	_rewarded_items.clear()
	_return_to_reward_menu()

func _claim_relic() -> void:
	# レリックはここで初めて所持品に加わり、報酬メニューから消える。
	if _relic_reward_resolved or _rewarded_relic == null:
		return
	if not RunData.add_relic(_rewarded_relic):
		return
	_relic_reward_resolved = true
	_rewarded_relic = null
	_return_to_reward_menu()

func _claim_gold() -> void:
	# ゴールドはボタンを押した時点で受け取り、選択済みとしてメニューから外す。
	if _gold_reward_resolved:
		return
	RunData.add_gold(_total_gold)
	_gold_reward_resolved = true
	_return_to_reward_menu()

func _claim_card(card_data: CardData) -> void:
	if _card_reward_resolved or card_data == null:
		return
	RunData.add_card(card_data)
	_card_reward_resolved = true
	_clear_card_choices()
	_return_to_reward_menu()

func _on_card_choice_selected(card_data: CardData, _choice_index: int) -> void:
	_claim_card(card_data)

func _skip_card_reward() -> void:
	# 個別画面のスキップは選択画面を閉じるだけ。報酬メニューから再び選べる。
	_return_to_reward_menu()

func _skip_item_reward() -> void:
	# レリック表示とアイテム表示は同じパネルを使うが、どちらも選択肢は保持する。
	_return_to_reward_menu()

func _clear_card_choices() -> void:
	if is_instance_valid(_card_choice_view):
		_card_choice_view.clear_cards()
	_rewarded_cards.clear()

func _return_to_reward_menu() -> void:
	_card_choice_view.dismiss()
	$CanvasLayer/ColorRect/Control_RewardMenu.visible = true
	$CanvasLayer/ColorRect/Control_RewardSelectCard.visible = false
	$CanvasLayer/ColorRect/Control_RewardSelectItem.visible = false
	_refresh_reward_menu()
	if _has_pending_choices():
		$StateMachine.current_state.transitioned.emit("RewardSelectTop")
	else:
		_complete_reward()

func _refresh_reward_menu() -> void:
	var menu_path := "CanvasLayer/ColorRect/Control_RewardMenu/NinePatchRect/CenterContainer/VBoxContainer/"
	get_node(menu_path + "Button_Coin").visible = not _gold_reward_resolved
	get_node(menu_path + "Button_Card").visible = _has_card_choice()
	get_node(menu_path + "Button_Item").visible = _has_item_choice()
	get_node(menu_path + "Button_Item").disabled = RunData.items.size() >= RunData.ITEM_CAPACITY
	get_node(menu_path + "Button_Treasure").visible = _has_relic_choice()

func _has_card_choice() -> bool:
	return not _card_reward_resolved and not _rewarded_cards.is_empty()

func _has_item_choice() -> bool:
	return not _item_reward_resolved and not _rewarded_items.is_empty()

func _has_relic_choice() -> bool:
	return not _relic_reward_resolved and _rewarded_relic != null

func _has_pending_choices() -> bool:
	return not _gold_reward_resolved or _has_card_choice() or _has_item_choice() or _has_relic_choice()

func _on_card_button_pressed() -> void:
	if not _has_card_choice():
		return
	$StateMachine.current_state.transitioned.emit("RewardSelectCardState")
	$CanvasLayer/ColorRect/Control_RewardMenu.visible = false
	$CanvasLayer/ColorRect/Control_RewardSelectCard.visible = true
	_card_choice_view.present_cards()

func _on_item_button_pressed() -> void:
	if not _has_item_choice() or RunData.items.size() >= RunData.ITEM_CAPACITY:
		return
	$StateMachine.current_state.transitioned.emit("RewardSelectItemState")
	$CanvasLayer/ColorRect/Control_RewardMenu.visible = false
	$CanvasLayer/ColorRect/Control_RewardSelectItem.visible = true
	_set_item_selection_header("REWARD_GET_ITEM_NUM", "REWARD_GET_ITEM_SKIP")
	_build_item_choices()

func _on_relic_button_pressed() -> void:
	if not _has_relic_choice():
		return
	$StateMachine.current_state.transitioned.emit("RewardSelectItemState")
	$CanvasLayer/ColorRect/Control_RewardMenu.visible = false
	$CanvasLayer/ColorRect/Control_RewardSelectItem.visible = true
	_set_item_selection_header("REWARD_GET_RELIC_NUM", "REWARD_GET_RELIC_SKIP")
	_build_relic_choice()

func _set_item_selection_header(title_key: String, skip_key: String) -> void:
	var title_label: Label = get_node("CanvasLayer/ColorRect/Control_RewardSelectItem/CenterContainer/VBoxContainer/MarginContainer_Title/MarginContainer/CenterContainer/Label")
	if title_key == "REWARD_GET_ITEM_NUM":
		title_label.text = tr(title_key) % 1
	else:
		title_label.text = tr(title_key)
	get_node("CanvasLayer/ColorRect/Control_RewardSelectItem/CenterContainer/VBoxContainer/Button_Skip").text = tr(skip_key)

func _build_relic_choice() -> void:
	var area: MarginContainer = get_node("CanvasLayer/ColorRect/Control_RewardSelectItem/CenterContainer/VBoxContainer/MarginContainer_ItemArea")
	for child in area.get_children():
		child.queue_free()
	var choices := VBoxContainer.new()
	choices.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choices.add_theme_constant_override("separation", 16)
	area.add_child(choices)
	var relic_name := Label.new()
	relic_name.text = _rewarded_relic.name
	relic_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choices.add_child(relic_name)
	var relic_description := Label.new()
	relic_description.text = _rewarded_relic.description
	relic_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	relic_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choices.add_child(relic_description)
	var claim_button := Button.new()
	claim_button.text = tr("REWARD_GET_RELIC_CLAIM")
	claim_button.pressed.connect(_claim_relic)
	choices.add_child(claim_button)

func _complete_reward() -> void:
	# ボタン連打などによる重複遷移を防ぎ、報酬完了をBattleSceneへ通知する。
	if _completed:
		return
	_completed = true
	reward_completed.emit()
	queue_free()
