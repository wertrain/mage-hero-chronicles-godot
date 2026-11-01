class_name CardPreviewPopup
extends CanvasLayer

## カード選択Viewで共通利用する、カード絵付きのホバープレビュー。
## 強化後カード、または説明文に登場する関連カードだけを表示する。

@export var card_scene: PackedScene

var _panel: PanelContainer
var _card_row: HBoxContainer
var _display_cards: Array[CardData] = []
var _display_captions: Array[String] = []
var _cards_by_guid: Dictionary = {}

func _ready() -> void:
	layer = 50
	_build_popup()
	# 説明文に名前が登場するカードを探せるよう、一度だけ全カードを読み込む。
	var database := DataBase.new()
	for card in database.load_cards():
		_cards_by_guid[card.guid] = card

func _build_popup() -> void:
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.035, 0.055, 0.98)
	panel_style.border_color = Color(0.68, 0.78, 0.84, 0.96)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 12
	panel_style.content_margin_top = 10
	panel_style.content_margin_right = 12
	panel_style.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)
	_card_row = HBoxContainer.new()
	_card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_row.add_theme_constant_override("separation", 8)
	column.add_child(_card_row)
	_panel.visible = false

func show_upgrade_preview(upgraded_card: CardData, mouse_position: Vector2) -> void:
	# 強化前は一覧上に表示されているので、ここには強化後だけを載せる。
	_display_cards.clear()
	_display_captions.clear()
	_display_cards.append(upgraded_card)
	_display_captions.append("強化後")
	_rebuild_card_row()
	_panel.visible = true
	_update_panel_position(mouse_position)

func show_referenced_cards(owner_card: CardData, mouse_position: Vector2) -> void:
	# 報酬一覧では元カードを重ねず、説明文に出てくる別カードだけを表示する。
	_display_cards.clear()
	_display_captions.clear()
	for referenced_card in _find_referenced_cards(owner_card):
		_display_cards.append(referenced_card)
		_display_captions.append(referenced_card.name)
	if _display_cards.is_empty():
		hide_preview()
		return
	_rebuild_card_row()
	_panel.visible = true
	_update_panel_position(mouse_position)

func hide_preview() -> void:
	if is_instance_valid(_panel):
		_panel.visible = false

func is_pointer_inside() -> bool:
	return is_instance_valid(_panel) and _panel.visible and _panel.get_global_rect().has_point(get_viewport().get_mouse_position())

func _find_referenced_cards(owner_card: CardData) -> Array[CardData]:
	var found: Array[CardData] = []
	if owner_card == null:
		return found
	var searchable_text: String = "%s %s" % [owner_card.description, owner_card.detail_description]
	var candidates: Array[CardData] = []
	for candidate_variant in _cards_by_guid.values():
		var candidate: CardData = candidate_variant as CardData
		if candidate == null or candidate.guid == owner_card.guid or candidate.name.length() < 2:
			continue
		if searchable_text.contains(candidate.name):
			candidates.append(candidate)
	# 名前が長いカードを優先し、短い名前の部分一致で候補が増えすぎないようにする。
	candidates.sort_custom(func(a: CardData, b: CardData) -> bool: return a.name.length() > b.name.length())
	for index in range(mini(candidates.size(), 3)):
		found.append(candidates[index])
	return found

func _rebuild_card_row() -> void:
	for child in _card_row.get_children():
		_card_row.remove_child(child)
		child.queue_free()
	for index in range(_display_cards.size()):
		_add_card_slot(_display_cards[index], _display_captions[index])
	var slot_count: int = _card_row.get_child_count()
	var card_row_width: float = float(slot_count) * 154.0 + float(maxi(0, slot_count - 1)) * 8.0
	_panel.size = Vector2(maxf(190.0, card_row_width + 24.0), 306.0)
	_update_panel_position(get_viewport().get_mouse_position())

func _add_card_slot(card_data: CardData, caption: String) -> void:
	if card_data == null or card_scene == null:
		return
	var slot := VBoxContainer.new()
	slot.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_theme_constant_override("separation", 2)
	slot.custom_minimum_size = Vector2(154, 270)
	var title := Label.new()
	title.text = caption
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.78, 0.85, 0.9))
	slot.add_child(title)
	var card := card_scene.instantiate() as Card
	card.set_data(card_data)
	_set_card_controls_mouse_ignored(card)
	card.position = Vector2(77, 139)
	slot.add_child(card)
	_card_row.add_child(slot)

func _set_card_controls_mouse_ignored(node: Node) -> void:
	# プレビュー内のカード装飾がリンク操作を遮らないよう、見た目用Controlは入力を通す。
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_card_controls_mouse_ignored(child)

func _update_panel_position(mouse_position: Vector2) -> void:
	if not is_instance_valid(_panel) or not _panel.visible:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var panel_size: Vector2 = _panel.size
	var position := mouse_position + Vector2(20, 18)
	if position.x + panel_size.x > viewport_size.x - 8:
		position.x = mouse_position.x - panel_size.x - 20
	if position.y + panel_size.y > viewport_size.y - 8:
		position.y = viewport_size.y - panel_size.y - 8
	_panel.position = Vector2(maxf(8.0, position.x), maxf(8.0, position.y))

