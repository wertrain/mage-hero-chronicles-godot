class_name CardChoiceView
extends PanelContainer

## 報酬・強化・山札確認で共通利用するカード一覧。
## 一枚ずつ大きく見せる用途ではなく、複数カードを並べて全体を見渡すための部品。

signal card_selected(card_data: CardData, choice_index: int)

@export var card_scene: PackedScene
@export var gallery_threshold: int = 6
## 一覧時は一行のカード数を抑え、カード本文を読みやすい大きさで表示する。
@export var gallery_card_scale: float = 0.95
@export var gallery_cell_size: Vector2 = Vector2(220, 300)
@export var row_card_scale: float = 1.0
@export var row_cell_size: Vector2 = Vector2(160, 250)
## 別のパネル内に一覧を埋め込む場合はfalseにし、二重の枠を避ける。
@export var show_panel_background: bool = true

var _card_data: Array[CardData] = []
var _cells: Array[Button] = []
var _selection_enabled := false
var _gallery_mode := false
var _flow: HFlowContainer
var _scroll: ScrollContainer
var _preview_popup: CardPreviewPopup
var _preview_cards: Array[CardData] = []
var _preview_hide_ticket: int = 0
var _suppress_hover_until_exit := false
var _active_preview_index := -1

func _ready() -> void:
	_build_list()
	_apply_panel_style()
	_rebuild_cards()

func _notification(what: int) -> void:
	# CardChoiceViewを親画面ごと隠した場合も、CanvasLayerのプレビューを残さない。
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_active_preview_index = -1
		if is_instance_valid(_preview_popup):
			_preview_popup.hide_preview()

func set_cards(cards: Array[CardData], allow_selection: bool = true, force_gallery: bool = false, preview_cards: Array[CardData] = []) -> void:
	# 同じ一覧部品を、選択画面と閲覧専用の山札確認の両方に使う。
	_active_preview_index = -1
	if is_instance_valid(_preview_popup):
		_preview_popup.hide_preview()
	_card_data = cards.duplicate()
	_preview_cards.clear()
	if preview_cards.size() == cards.size():
		_preview_cards = preview_cards.duplicate()
	else:
		_preview_cards = cards.duplicate()
	_selection_enabled = allow_selection
	_gallery_mode = force_gallery or cards.size() >= gallery_threshold
	if is_inside_tree():
		_rebuild_cards()

func present_cards() -> void:
	# 画面を開いた瞬間にカーソルがカード上にあっても、最初の表示ではプレビューを出さない。
	_active_preview_index = -1
	_suppress_hover_until_exit = _is_pointer_over_card_visual()
	visible = true
	_selection_enabled = true

func dismiss() -> void:
	_selection_enabled = false
	_active_preview_index = -1
	visible = false
	if is_instance_valid(_preview_popup):
		_preview_popup.hide_preview()

func clear_cards() -> void:
	dismiss()
	_card_data.clear()
	_preview_cards.clear()
	if is_instance_valid(_flow):
		_rebuild_cards()

func _build_list() -> void:
	# PanelContainerが一覧の外枠になり、その内側だけをScrollContainerでスクロールする。
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(margin)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(_scroll)
	# HFlowContainerは列数を固定せず、画面幅に合わせて折り返して各行を中央に寄せる。
	_flow = HFlowContainer.new()
	_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_flow.add_theme_constant_override("h_separation", 12)
	_flow.add_theme_constant_override("v_separation", 14)
	_scroll.add_child(_flow)
	_preview_popup = CardPreviewPopup.new()
	_preview_popup.card_scene = card_scene
	add_child(_preview_popup)

func _apply_panel_style() -> void:
	if not show_panel_background:
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		return
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.035, 0.055, 0.085, 0.97)
	panel.border_color = Color(0.52, 0.66, 0.76, 0.9)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(12)
	panel.content_margin_left = 8
	panel.content_margin_top = 8
	panel.content_margin_right = 8
	panel.content_margin_bottom = 8
	add_theme_stylebox_override("panel", panel)

func _rebuild_cards() -> void:
	if not is_instance_valid(_flow):
		return
	_active_preview_index = -1
	if is_instance_valid(_preview_popup):
		_preview_popup.hide_preview()
	for cell in _cells:
		if is_instance_valid(cell):
			_flow.remove_child(cell)
			cell.queue_free()
	_cells.clear()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if _gallery_mode else ScrollContainer.SCROLL_MODE_DISABLED
	var active_cell_size: Vector2 = gallery_cell_size if _gallery_mode else row_cell_size
	var active_card_scale: float = gallery_card_scale if _gallery_mode else row_card_scale
	if card_scene == null:
		if not _card_data.is_empty():
			push_error("CardChoiceView requires a card scene")
		return
	for index in range(_card_data.size()):
		var data: CardData = _card_data[index]
		# 透明なボタンをカードの台座にし、カード自体の絵を保ったままクリック可能にする。
		var cell := Button.new()
		cell.custom_minimum_size = active_cell_size
		cell.flat = true
		cell.focus_mode = Control.FOCUS_NONE
		# 閲覧専用でもPASSにして、ホバープレビューと親ScrollContainerの操作を両立する。
		cell.mouse_filter = Control.MOUSE_FILTER_STOP if _selection_enabled else Control.MOUSE_FILTER_PASS
		cell.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _selection_enabled else Control.CURSOR_ARROW
		# OS標準の文字ツールチップではなく、カード絵を使う共通プレビューを表示する。
		cell.tooltip_text = ""
		cell.mouse_entered.connect(_on_cell_mouse_entered.bind(index))
		cell.mouse_exited.connect(_on_cell_mouse_exited.bind(index))
		cell.gui_input.connect(_on_cell_gui_input.bind(index))
		if _selection_enabled:
			cell.pressed.connect(_on_cell_pressed.bind(index))
		_flow.add_child(cell)
		_cells.append(cell)
		var card: Card = card_scene.instantiate() as Card
		card.set_data(data)
		# カードの装飾・ツールチップControlがボタン入力を奪わないよう、表示側は入力を通す。
		_set_card_controls_mouse_ignored(card)
		card.position = active_cell_size / 2.0
		card.scale = Vector2.ONE * active_card_scale
		cell.add_child(card)
	# 新しい候補を開くたび、スクロール位置を先頭に戻して一覧の始まりを見せる。
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = 0

func _set_card_controls_mouse_ignored(node: Node) -> void:
	# Cardシーン内のControlは見た目専用にし、選択当たり判定を外側のボタンに一本化する。
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_card_controls_mouse_ignored(child)

func _on_cell_pressed(index: int) -> void:
	if not _selection_enabled or index < 0 or index >= _card_data.size():
		return
	_preview_hide_ticket += 1
	_preview_popup.hide_preview()
	_selection_enabled = false
	card_selected.emit(_card_data[index], index)

func _on_cell_mouse_entered(index: int) -> void:
	_update_card_preview(index)

func _on_cell_gui_input(event: InputEvent, index: int) -> void:
	# セルの余白に入っただけでは反応せず、ポインター移動ごとにカード画像の矩形を判定する。
	if event is InputEventMouseMotion:
		_update_card_preview(index)

func _update_card_preview(index: int) -> void:
	if _suppress_hover_until_exit or index < 0 or index >= _card_data.size() or not is_instance_valid(_preview_popup):
		return
	var cell: Button = _cells[index]
	var card: Card = cell.get_child(0) as Card
	var is_over_card: bool = card != null and card.get_visual_rect_in_viewport().has_point(get_viewport().get_mouse_position())
	if not is_over_card:
		if _active_preview_index == index:
			_preview_hide_ticket += 1
			_active_preview_index = -1
			_preview_popup.hide_preview()
		return
	if _active_preview_index == index:
		return
	_active_preview_index = index
	_preview_hide_ticket += 1
	var selected_card: CardData = _card_data[index]
	var preview_card: CardData = _preview_cards[index]
	if preview_card.guid != selected_card.guid:
		# 強化画面では一覧上の元カードと重複させず、強化後だけを見せる。
		_preview_popup.show_upgrade_preview(preview_card, get_viewport().get_mouse_position())
	else:
		# 報酬やデッキ一覧ではカード本体が見えているため、説明に登場する別カードだけを出す。
		_preview_popup.show_referenced_cards(selected_card, get_viewport().get_mouse_position())

func _on_cell_mouse_exited(index: int) -> void:
	# 開いた瞬間からカード上にいたケースでは、カーソルが一度離れたら通常のホバーを有効にする。
	_suppress_hover_until_exit = false
	if _active_preview_index == index:
		_active_preview_index = -1
	_schedule_card_preview_hide()

func _is_pointer_over_card_visual() -> bool:
	for index in range(_cells.size()):
		var cell: Button = _cells[index]
		if not is_instance_valid(cell):
			continue
		var card: Card = cell.get_child(0) as Card
		if card != null and card.get_visual_rect_in_viewport().has_point(get_viewport().get_mouse_position()):
			return true
	return false

func _schedule_card_preview_hide() -> void:
	_preview_hide_ticket += 1
	var ticket: int = _preview_hide_ticket
	_hide_preview_after_pointer_leaves(ticket)

func _hide_preview_after_pointer_leaves(ticket: int) -> void:
	# 一覧からプレビュー領域へカーソルを移す時間を確保する。
	await get_tree().create_timer(0.35).timeout
	if ticket != _preview_hide_ticket or not is_instance_valid(_preview_popup):
		return
	if not _preview_popup.is_pointer_inside():
		_preview_popup.hide_preview()
		_active_preview_index = -1
