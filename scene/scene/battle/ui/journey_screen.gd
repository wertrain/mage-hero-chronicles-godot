class_name JourneyScreen
extends CanvasLayer

signal route_selected(rest_before_battle: bool, fight_boss: bool)
signal new_run_requested
signal card_upgrade_requested(index: int, upgraded_card: CardData)

var show_campaign_clear: bool = false
var _layout: VBoxContainer
var _title: Label
var _summary: Label

func _ready() -> void:
	# 旅の進行画面はシーン再読み込み後も前面に出るCanvasLayerとして組み立てる。
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.035, 0.045, 0.08, 0.96)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 470)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)
	_layout = VBoxContainer.new()
	_layout.add_theme_constant_override("separation", 22)
	margin.add_child(_layout)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 34)
	_layout.add_child(_title)

	_summary = Label.new()
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary.add_theme_font_size_override("font_size", 20)
	_layout.add_child(_summary)

	var gold := Label.new()
	gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_layout.add_child(gold)

	if show_campaign_clear:
		_title.text = tr("JOURNEY_CLEAR_TITLE")
		_summary.text = tr("JOURNEY_CLEAR_BODY")
		gold.text = tr("JOURNEY_GOLD") % RunData.gold
		var new_run_button := _make_button(tr("JOURNEY_NEW_RUN"))
		new_run_button.pressed.connect(func(): new_run_requested.emit())
		_layout.add_child(new_run_button)
		return

	_title.text = tr("JOURNEY_TITLE")
	var progress_text := tr("JOURNEY_PROGRESS") % RunData.completed_battles
	_summary.text = progress_text
	gold.text = tr("JOURNEY_GOLD") % RunData.gold

	var route := HBoxContainer.new()
	route.alignment = BoxContainer.ALIGNMENT_CENTER
	route.add_theme_constant_override("separation", 12)
	_layout.add_child(route)
	for index in range(3):
		var node_label := Label.new()
		node_label.text = tr("JOURNEY_BATTLE_NODE") % (index + 1)
		node_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var node_color: Color = Color(0.55, 0.9, 0.65) if index < RunData.completed_battles else Color(0.95, 0.78, 0.35) if index == RunData.completed_battles else Color(0.9, 0.9, 0.9)
		node_label.add_theme_color_override("font_color", node_color)
		route.add_child(node_label)
		var arrow := Label.new()
		arrow.text = "→"
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		route.add_child(arrow)
	var boss_node := Label.new()
	boss_node.text = tr("JOURNEY_BOSS_NODE")
	boss_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	route.add_child(boss_node)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	_layout.add_child(buttons)
	var is_boss_next: bool = RunData.completed_battles >= 3
	var rest_text := tr("JOURNEY_REST_BOSS") if is_boss_next else tr("JOURNEY_REST_CONTINUE")
	var continue_text := tr("JOURNEY_BOSS") if is_boss_next else tr("JOURNEY_CONTINUE")
	var upgradeable_indices: Array[int] = []
	# 強化先を持つカードだけを候補にする。強化済みカードは候補から外れる。
	for index in range(RunData.deck.size()):
		if not RunData.deck[index].upgrade_guid.is_empty():
			upgradeable_indices.append(index)
	if RunData.completed_battles > 0 and not upgradeable_indices.is_empty():
		var upgrade_button := _make_button(tr("JOURNEY_UPGRADE_CARD"))
		upgrade_button.pressed.connect(_show_upgrade_choices.bind(upgradeable_indices, is_boss_next))
		buttons.add_child(upgrade_button)
	var rest_button := _make_button(rest_text)
	rest_button.disabled = RunData.current_health >= 100
	rest_button.pressed.connect(func(): route_selected.emit(true, is_boss_next))
	buttons.add_child(rest_button)
	var continue_button := _make_button(continue_text)
	continue_button.pressed.connect(func(): route_selected.emit(false, is_boss_next))
	buttons.add_child(continue_button)

func _show_upgrade_choices(indices: Array[int], is_boss_next: bool) -> void:
	# 進行ルート表示をカード一覧に置き換え、長いデッキはスクロールして選べるようにする。
	for child in _layout.get_children():
		if child is HBoxContainer or child is VBoxContainer:
			_layout.remove_child(child)
			child.queue_free()
	_title.text = tr("JOURNEY_UPGRADE_TITLE")
	_summary.text = tr("JOURNEY_UPGRADE_PROMPT")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 280)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_layout.add_child(scroll)
	var choices := VBoxContainer.new()
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("separation", 8)
	scroll.add_child(choices)
	var database := DataBase.new()
	database.load_cards()
	for index in indices:
		var card: CardData = RunData.deck[index]
		# 元カードに記録されたGUIDを使い、DBの強化版定義をボタンに結び付ける。
		var upgraded_card := database.get_card(card.upgrade_guid)
		if upgraded_card == null:
			continue
		var button := _make_button(card.name + " → " + upgraded_card.name)
		button.pressed.connect(_select_upgrade.bind(index, upgraded_card, is_boss_next))
		choices.add_child(button)

func _select_upgrade(index: int, upgraded_card: CardData, is_boss_next: bool) -> void:
	# BattleScene側でデッキを置換してから、休憩後の次戦へ進む。
	card_upgrade_requested.emit(index, upgraded_card)
	route_selected.emit(false, is_boss_next)

func _make_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 20)
	return button
