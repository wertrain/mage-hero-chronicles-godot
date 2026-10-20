class_name RunStartScreen
extends Control

## 冒険を始める前に職業と入口を選ぶ。小さな選択画面にして、遊び始めるまでを短く保つ。
const BATTLE_SCENE_PATH := "res://scene/scene/battle/battle_scene.tscn"
const JOBS := ["warrior", "mage"]
const STARTS := ["road", "forest", "ruins"]

var _selected_job := "warrior"
var _selected_start := "road"
var _job_buttons: Dictionary = {}
var _start_buttons: Dictionary = {}
var _job_summary: Label
var _selection_root: Control
var _start_summary: Label

func _ready() -> void:
	_build_screen()
	_refresh_selection()

func _build_screen() -> void:
	# Controlの子をコードで組み立て、選択肢を増やすときも定義をまとめて扱えるようにする。
	var backdrop := ColorRect.new()
	backdrop.color = Color("#101820")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_selection_root = center
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 620)
	center.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)
	var title := _label("RUN_START_TITLE", 32, HORIZONTAL_ALIGNMENT_CENTER)
	layout.add_child(title)
	layout.add_child(_label("RUN_START_SUBTITLE", 16, HORIZONTAL_ALIGNMENT_CENTER))

	layout.add_child(_label("RUN_START_JOB_HEADER", 20))
	var jobs := HBoxContainer.new()
	jobs.add_theme_constant_override("separation", 14)
	layout.add_child(jobs)
	for job in JOBS:
		var button := _choice_button("RUN_START_JOB_" + job.to_upper(), 210, 76)
		button.pressed.connect(_select_job.bind(job))
		_job_buttons[job] = button
		jobs.add_child(button)
	_job_summary = _label("", 15)
	layout.add_child(_job_summary)

	layout.add_child(_label("RUN_START_ROUTE_HEADER", 20))
	var starts := HBoxContainer.new()
	starts.add_theme_constant_override("separation", 12)
	layout.add_child(starts)
	for route_id in STARTS:
		var button := _choice_button("RUN_START_ROUTE_" + route_id.to_upper(), 260, 76)
		button.pressed.connect(_select_start.bind(route_id))
		_start_buttons[route_id] = button
		starts.add_child(button)
	_start_summary = _label("", 15)
	layout.add_child(_start_summary)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)
	var begin := _choice_button("RUN_START_BEGIN", 300, 52)
	begin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	begin.pressed.connect(_begin_run)
	layout.add_child(begin)
	var debug_start := Button.new()
	debug_start.text = tr("RUN_START_DEBUG_WARRIOR")
	debug_start.flat = true
	debug_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	debug_start.pressed.connect(_begin_debug_run)
	layout.add_child(debug_start)

func _label(text_key: String, font_size: int, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = tr(text_key) if not text_key.is_empty() else ""
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#f4ead0"))
	return label

func _choice_button(text_key: String, width: float, height: float) -> Button:
	var button := Button.new()
	button.text = tr(text_key)
	button.custom_minimum_size = Vector2(width, height)
	button.add_theme_font_size_override("font_size", 18)
	return button

func _select_job(job: String) -> void:
	_selected_job = job
	_refresh_selection()

func _select_start(route_id: String) -> void:
	_selected_start = route_id
	_refresh_selection()

func _refresh_selection() -> void:
	_job_summary.text = tr("RUN_START_JOB_DESC_" + _selected_job.to_upper())
	_start_summary.text = tr("RUN_START_ROUTE_DESC_" + _selected_start.to_upper())
	for job in _job_buttons:
		_job_buttons[job].modulate = Color("#ffe39b") if job == _selected_job else Color("#c1c7c9")
	for route_id in _start_buttons:
		_start_buttons[route_id].modulate = Color("#ffe39b") if route_id == _selected_start else Color("#c1c7c9")

func _begin_run() -> void:
	# 職業を決めたらすぐ戦闘には進まず、先に全体マップで初戦の道を選ぶ。
	RunData.prepare_new_run(_selected_job, _selected_start)
	var database := DataBase.new()
	database.load_cards()
	RunData.initialize(database.load_deck(_selected_job))
	_selection_root.hide()
	var journey_screen := JourneyScreen.new()
	journey_screen.name = "InitialJourneyScreen"
	journey_screen.initial_route_selection = true
	journey_screen.route_selected.connect(_on_initial_route_selected)
	add_child(journey_screen)


func _on_initial_route_selected(node_id: String, node_type: String, _amount: int) -> void:
	# 開始位置をマップで選び終えたあと、接続先の初戦を選ぶと戦闘へ移る。
	if node_type != "battle" or not node_id.begins_with("battle_1_"):
		return
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)

func _begin_debug_run() -> void:
	# エディタ実行時と同じ戦士初戦を維持し、毎回この選択画面を操作しなくて済む導線。
	RunData.prepare_new_run("warrior", "road")
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)
