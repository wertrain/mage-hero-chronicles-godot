class_name JourneyScreen
extends CanvasLayer

const CARD_SCENE: PackedScene = preload("res://scene/card/card.tscn")
## 専用のイベント絵が揃うまで、既存の森背景を差し替え可能な共通プレースホルダーに使う。
const EVENT_IMAGE_PLACEHOLDER: Texture2D = preload("res://art/background/magicforest.jpg")

## 戦闘後に表示する全体ルートマップ。
## ノードと道筋を一度に見せ、現在地から線でつながる場所だけ選択可能にする。

signal route_selected(node_id: String, node_type: String, amount: int)
signal event_selected(node_id: String, heal_amount: int, gold_delta: int)
signal card_upgrade_requested(index: int, upgraded_card: CardData)
signal relic_selected(node_id: String, relic: RelicData)
signal shop_relic_purchased(relic: RelicData)
signal job_change_selected(node_id: String, target_job: String, reward_card: CardData)
signal new_run_requested

## ノード間隔と横方向の配置。高さはルート構成から自動計算する。
const MAP_ROW_HEIGHT := 130.0
## 端の行先にも余白ができるよう、道の配置は変えず背景の左右にセルを足す。
const MAP_SIDE_PADDING := 80.0
## 7列にして各開始レーンにイベント道と戦闘道を並べ、横方向の詰まりを避ける。
const NODE_COLUMNS := [40.0, 140.0, 240.0, 340.0, 440.0, 540.0, 640.0, 740.0, 840.0, 940.0, 1040.0]
## マス数ごとの配置パターン。横の間隔を空けて、道とラベルを読みやすくする。
const ROUTE_COLUMNS_BY_NODE_COUNT := {
	2: [[0, 10], [1, 9], [2, 8], [3, 7]],
	3: [[0, 5, 10], [0, 3, 7], [3, 7, 10], [1, 5, 9]],
	4: [[0, 3, 7, 10], [0, 2, 8, 10], [1, 4, 6, 9]],
	5: [[0, 2, 5, 8, 10], [0, 3, 5, 7, 10], [1, 3, 5, 7, 9]],
}
const MAP_TILE_SIZE := 64
const FALLBACK_ROUTE_EVENT_TYPES := ["event_herbalist", "event_shrine", "event_caravan", "event_forge"]

var _map_rect := Rect2()
var _map_content_size := Vector2.ZERO
var _node_positions: Dictionary = {}
var _node_data: Dictionary = {}
## 同じ段の道同士が重なって別ルートに見えないよう、区間ごとに通路の高さを分ける。
var _route_edge_channel_offsets: Dictionary = {}

var show_campaign_clear := false
## 新しい旅の最初に、複数の初戦ルートから選ぶための簡易マップ。
var initial_route_selection := false
var map_background_texture: Texture2D
var _buttons: Dictionary = {}
var _node_labels: Dictionary = {}
var _map: Control
var _map_content: Control
var _scroll: ScrollContainer
var _player_marker_position := Vector2.ZERO
var _displayed_player_node_id := ""
var _player_marker_tween: Tween
var _dialog: VBoxContainer
var _dialog_title: Label
var _dialog_body: Label
var _event_illustration_frame: PanelContainer
var _event_illustration: TextureRect
var _job_reward_card_view: CardChoiceView
## イベント名をキーに画像を登録できる。未登録のイベントは共通絵を表示する。
var _event_illustrations: Dictionary = {}
var _upgrade_backdrop: ColorRect
var _upgrade_header_panel: PanelContainer
var _upgrade_window: PanelContainer
var _upgrade_title: Label
var _upgrade_body: Label
var _upgrade_skip: Button
var _gold_label: Label
var _progress_label: Label
var _job_label: Label
var _map_footer: Label
var _card_choice_view: CardChoiceView
var _deck_overlay: ColorRect
var _deck_title: Label
var _deck_choice_view: CardChoiceView
var _deck_button: Button
var _upgrade_deck_indices: Array[int] = []
var _upgrade_targets: Array[CardData] = []
var _upgrade_node_id: String = ""
## 同じカード選択画面を使う休憩所の強化も、到着地点の種類は「休憩」のまま記録する。
var _upgrade_route_node_type: String = "upgrade"
## 鍛冶イベントでは、強化対象を選んだ時だけ費用を支払う。見送る場合は消費しない。
var _upgrade_gold_cost: int = 0
var _reachable := {}
## 描画されている道を実際にたどった移動経路。見た目の接続と選択可否を一致させる。
var _reachable_paths: Dictionary = {}
## 初回マップで開始地点を決めた後は、そのレーンから進めるノードだけを描く。
var _visible_route_nodes := {}
## 店を開き直したり、カード削除画面から戻ったりしても在庫・購入状態を保つ。
var _active_shop_id := ""
var _shop_card_stock: Array[CardData] = []
var _shop_card_sold: Array[bool] = []
var _shop_item_stock: ItemData
var _shop_item_sold := false
var _shop_relic_stock: RelicData
var _shop_relic_sold := false
var _shop_card_removal_used := false

func _ready() -> void:
	# 全画面の薄暗い幕の上にマップを置き、背後の戦闘画面と区別する。
	layer = 20
	_build_route_graph()
	_build_ui()
	_refresh_map()
	if show_campaign_clear:
		_show_clear_dialog()

func _build_route_graph() -> void:
	# 入口からボスまでの道をつなぐ。区間の合流数と有無はシードから決める。
	_node_data.clear()
	_node_positions.clear()
	_route_edge_channel_offsets.clear()
	# 全体マップの最下段に複数の開始地点を並べ、最初の行先へつなぐ。
	var entry_ids: Array[String] = []
	var first_battle_ids: Array[String] = []
	var entry_columns: Array[int] = []
	var entry_label_ids: Array[String] = []
	for start_index in range(RunData.STARTING_POSITION_IDS.size()):
		var start_id: String = str(RunData.STARTING_POSITION_IDS[start_index])
		# 4つの開始地点を左右へ均等に広げ、真ん中に寄りすぎないようにする。
		var start_column: int = roundi((float(start_index) + 0.5) * 11.0 / float(RunData.STARTING_POSITION_IDS.size()) - 0.5)
		entry_ids.append("start_" + start_id)
		first_battle_ids.append("battle_1_" + start_id)
		entry_columns.append(start_column)
		entry_label_ids.append(start_id.to_upper())
	for lane_index in range(entry_ids.size()):
		var column: int = entry_columns[lane_index]
		_add_route_node(entry_ids[lane_index], "start_position", "JOURNEY_INITIAL_" + entry_label_ids[lane_index], 0, column)
		# 通常は初戦、イベント多めプリセットでは入口ごとに選ばれたイベントを置く。
		# 入口の先からは、ほかの区間と同じ共通ルート生成を使う。
		var encounter_type: String = RunData.starting_lane_encounter_types[lane_index] if lane_index < RunData.starting_lane_encounter_types.size() else "battle"
		var encounter_label: String = _label_for_route_type(encounter_type) if encounter_type.begins_with("event_") else "JOURNEY_BATTLE_NODE"
		_add_route_node(first_battle_ids[lane_index], encounter_type, encounter_label, 1, column, 1)
		_node_data[entry_ids[lane_index]]["next"] = [first_battle_ids[lane_index]]
	var previous_node_ids: Array = first_battle_ids.duplicate()
	var previous_row := 1
	var previous_stage := 1
	for segment_index in range(RunData.route_segments.size()):
		# 開始後からボス前までは、区間の種類に関係なく同じ段生成・接続処理を使う。
		var first_segment_row: int = previous_row + 1
		var segment_result: Dictionary = _build_flexible_route_segment(segment_index, previous_node_ids, first_segment_row, previous_stage)
		previous_node_ids = segment_result["exit_ids"]
		previous_row = int(segment_result["exit_row"])
		previous_stage = int(segment_result["exit_stage"])
	# 転職マスはラン全体で最低1つ確保する。既存のセルを置き換えるので道筋は増やさない。
	_ensure_guaranteed_job_change_node()
	# 区間の後にもう1戦を共通の山場として置き、その先にボス前の準備地点を置く。
	var final_battle_stage: int = RunData.get_normal_battle_count()
	var final_battle_row: int = previous_row + 1
	var final_battle_id := "battle_%d" % final_battle_stage
	_add_route_node(final_battle_id, "battle", "JOURNEY_BATTLE_NODE", final_battle_row, -1, final_battle_stage)
	for previous_node_id in previous_node_ids:
		_node_data[str(previous_node_id)]["next"] = [final_battle_id]
	var boss_route_row: int = final_battle_row + 1
	# ボス前の寄り道はRunDataの調整設定からシード生成される。0個なら直行ルート。
	var boss_route_ids: Array[String] = []
	var boss_route_types: Array = RunData.boss_preparation_types
	for index in range(boss_route_types.size()):
		var route_type: String = str(boss_route_types[index])
		var route_id := "boss_prep_%d_%s" % [index + 1, route_type]
		# ボス前だけは専用の候補を使いつつ、端を避けて中央寄りに配置する。
		var route_column: int = 5 if boss_route_types.size() == 1 else roundi(1.0 + float(index) * 8.0 / float(boss_route_types.size() - 1))
		_add_route_node(route_id, route_type, _label_for_route_type(route_type), boss_route_row, route_column)
		boss_route_ids.append(route_id)
	_node_data[final_battle_id]["next"] = boss_route_ids if not boss_route_ids.is_empty() else ["boss"]
	var boss_row: int = boss_route_row + 1 if not boss_route_ids.is_empty() else final_battle_row + 1
	_add_route_node("boss", "boss", "JOURNEY_BOSS_NODE", boss_row, -1)
	for route_id in boss_route_ids:
		_node_data[route_id]["next"] = ["boss"]
	_position_route_nodes(boss_row)
	# 新しい旅では開始地点をまだ選んでいない状態でマップを開く。
	if initial_route_selection and RunData.current_route_node_id == "new_run":
		RunData.route_history = ["new_run"]
	# 開発中に旧マップの進行状態が残っていても、完了戦数に対応した地点から続けられる。
	elif not _node_data.has(RunData.current_route_node_id):
		if RunData.boss_defeated:
			RunData.current_route_node_id = "boss"
		elif RunData.completed_battles <= 1:
			RunData.current_route_node_id = "battle_1_left"
		else:
			var completed_stage: int = mini(RunData.completed_battles, RunData.get_normal_battle_count())
			# 旧形式の進行地点が見つからない場合も、必ず現在のマップ上にある地点へ戻す。
			RunData.current_route_node_id = "battle_1_left"
			for node_id in _node_data:
				var fallback_node: Dictionary = _node_data[node_id]
				if int(fallback_node["stage"]) == completed_stage and fallback_node["type"] in ["battle", "elite"]:
					RunData.current_route_node_id = node_id
					break
		RunData.route_history = [RunData.current_route_node_id]

func _build_flexible_route_segment(segment_index: int, previous_node_ids: Array, first_row: int, previous_stage: int) -> Dictionary:
	# 区間を同じ形の3列メッシュにせず、行ごとの幅と接続をシードから作る。
	var row_count: int = clampi(int(RunData.ROUTE_GENERATION_CONFIG["route_rows_per_segment"]), 2, 8)
	var route_types: Array = RunData.route_segments[segment_index].duplicate()
	if route_types.is_empty():
		route_types = ["rest"]
	var node_ids_by_row: Array[Array] = []
	var lane_columns_by_row: Array[Array] = []
	var elite_in_segment: bool = segment_index < RunData.route_segment_has_elite.size() and RunData.route_segment_has_elite[segment_index]
	var elite_row_index: int = floori(float(row_count) / 2.0)
	var node_count_weights: Array = RunData.ROUTE_GENERATION_CONFIG["route_node_count_weights"]
	for row_index in range(row_count):
		# 区間ごとのシード乱数で、同じシードなら同じ選択肢を再現する。
		# 乱数器を行ごとに分け、行数や別の抽選を変えても後続の行がずれないようにする。
		var row_rng := RandomNumberGenerator.new()
		row_rng.seed = int(RunData.run_seed) + (segment_index + 1) * 1009 + (row_index + 1) * 9176
		# 行ごとの乱数からマス数を決める。同じシードなら幅も同じになる。
		var node_count: int = 2 + row_rng.rand_weighted(PackedFloat32Array(node_count_weights))
		# 同じマス数でも複数の列配置から選び、縦に同じ形が続くのを抑える。
		var column_patterns: Array = ROUTE_COLUMNS_BY_NODE_COUNT[node_count]
		var selected_columns: Array = column_patterns[row_rng.randi_range(0, column_patterns.size() - 1)]
		var lane_columns: Array[int] = []
		if row_index > 0 and lane_columns_by_row[row_index - 1].size() == node_count:
			# 同じ数のマスが続く段は同じ列を使い、道が不要に横切らないようにする。
			for previous_column_value in lane_columns_by_row[row_index - 1]:
				lane_columns.append(int(previous_column_value))
		else:
			for column_value in selected_columns:
				lane_columns.append(int(column_value))
		var safe_type: String = _select_flexible_safe_type(route_types, row_rng)
		var event_type: String = _select_flexible_event_type(route_types, safe_type, row_rng)
		# マス数に応じて役割を決める。2個の段では戦闘を避ける選択肢を抽選する。
		var lane_types: Array[String] = []
		if node_count == 2:
			lane_types.append("battle")
			lane_types.append(event_type if row_rng.randf() < 0.5 else safe_type)
		else:
			lane_types.append(safe_type)
			lane_types.append("battle")
			lane_types.append(event_type)
		if node_count > 3:
			# 4個以上の段には、別の安全な選択肢も加える。
			var excluded_safe_types: Array[String] = [safe_type]
			var second_safe_type: String = _select_flexible_safe_type(route_types, row_rng, excluded_safe_types)
			lane_types.append(second_safe_type)
		if node_count > 4:
			# 5個の段ではイベントの種類をもう1つ増やし、戦闘以外の選択肢も広げる。
			var excluded_event_types: Array[String] = [event_type]
			lane_types.append(_select_flexible_event_type(route_types, safe_type, row_rng, excluded_event_types))
		# 同じ列に同じ種類が続かないよう、列の役割自体もシードで入れ替える。
		for shuffle_index in range(lane_types.size() - 1, 0, -1):
			var swap_index: int = row_rng.randi_range(0, shuffle_index)
			var temporary_type: String = lane_types[shuffle_index]
			lane_types[shuffle_index] = lane_types[swap_index]
			lane_types[swap_index] = temporary_type
		var row_node_ids: Array[String] = []
		for lane_index in range(lane_columns.size()):
			var node_type: String = lane_types[lane_index]
			# イベントマスのごく一部を、転職の申し出がある珍しいイベントにする。
			if node_type.begins_with("event_") and row_rng.randf() < float(RunData.ROUTE_GENERATION_CONFIG["rare_job_change_event_chance"]):
				node_type = "event_job_change"
			if elite_in_segment and row_index == elite_row_index and node_type == "battle":
				node_type = "elite"
			var node_id := "route_%d_row_%d_lane_%d_%s" % [segment_index + 1, row_index + 1, lane_index + 1, node_type]
			var label_key: String = _label_for_route_type(node_type) if node_type != "battle" and node_type != "elite" else ("JOURNEY_ELITE_NODE" if node_type == "elite" else "JOURNEY_BATTLE_NODE")
			var node_stage: int = previous_stage + row_index + 1 if node_type in ["battle", "elite"] else 0
			_add_route_node(node_id, node_type, label_key, first_row + row_index, lane_columns[lane_index], node_stage)
			row_node_ids.append(node_id)
		node_ids_by_row.append(row_node_ids)
		lane_columns_by_row.append(lane_columns)
	# 前区間からの入口も同じ順序保存ルールでつなぐ。
	_connect_ordered_route_rows(previous_node_ids, node_ids_by_row[0], int(RunData.run_seed) + (segment_index + 1) * 1009)
	# 各段は左右の順番を保つ連続グループとして接続する。
	# マス数が減る段では隣り合う道だけが明示的に合流し、増える段では道が分岐する。
	for row_index in range(row_count - 1):
		_connect_ordered_route_rows(node_ids_by_row[row_index], node_ids_by_row[row_index + 1], int(RunData.run_seed) + (segment_index + 1) * 1009 + (row_index + 1) * 9176)
	# 区間の出口は抽選で合流させるか、複数レーンのまま次へ渡す。
	var merge_stage: int = previous_stage + row_count + 1
	var merge_row: int = first_row + row_count
	var merge_rng := RandomNumberGenerator.new()
	merge_rng.seed = int(RunData.run_seed) + (segment_index + 1) * 58013
	var should_merge: bool = merge_rng.randf() < clampf(float(RunData.ROUTE_GENERATION_CONFIG["route_segment_merge_chance"]), 0.0, 1.0)
	if should_merge:
		# 最終行を左右に連続したグループへ分けて、複数の合流点へ接続する。
		# 次の区間はこれらの合流点を複数の入口として受け取り、選択肢を保つ。
		var last_row_ids: Array = node_ids_by_row[row_count - 1]
		var merge_group_count: int = _choose_merge_group_count(last_row_ids.size(), merge_rng)
		var merge_battle_ids: Array[String] = []
		for group_index in range(merge_group_count):
			var group_start: int = floori(float(group_index) * float(last_row_ids.size()) / float(merge_group_count))
			var group_end: int = floori(float(group_index + 1) * float(last_row_ids.size()) / float(merge_group_count))
			var group_center_lane: int = floori(float(group_start + group_end - 1) / 2.0)
			var center_node: Dictionary = _node_data[str(last_row_ids[group_center_lane])]
			var merge_battle_id: String = "battle_%d_segment_%d_merge_%d" % [merge_stage, segment_index + 1, group_index + 1]
			_add_route_node(merge_battle_id, "battle", "JOURNEY_BATTLE_NODE", merge_row, int(center_node["column"]), merge_stage)
			merge_battle_ids.append(merge_battle_id)
		_connect_ordered_route_rows(last_row_ids, merge_battle_ids, int(RunData.run_seed) + (segment_index + 1) * 58013)
		return {"exit_ids": merge_battle_ids, "exit_row": merge_row, "exit_stage": merge_stage}
	# 合流しない場合は出口の各マスから次区間、または最後の共通戦闘へそれぞれ道を伸ばす。
	return {"exit_ids": node_ids_by_row[row_count - 1].duplicate(), "exit_row": first_row + row_count - 1, "exit_stage": previous_stage + row_count}

func _ensure_guaranteed_job_change_node() -> void:
	# すでに開始エリア由来の転職マスがあるならそのまま使う。
	var candidate_ids: Array[String] = []
	for node_id_value in _node_data:
		var node_id: String = str(node_id_value)
		var node_type: String = str(_node_data[node_id]["type"])
		if node_type == "job_change":
			return
		# ボス直前の専用候補と、戦闘を置き換えないよう通常ルートのマスだけを見る。
		if node_id.begins_with("boss_prep_") or node_type in ["battle", "elite", "boss", "start_position"]:
			continue
		if node_type in ["rest", "treasure", "upgrade", "shop"]:
			candidate_ids.append(node_id)
	# 安全マスが候補にない構成なら、イベントを転職マスに置き換える。
	if candidate_ids.is_empty():
		for node_id_value in _node_data:
			var node_id: String = str(node_id_value)
			var node_type: String = str(_node_data[node_id]["type"])
			if node_id.begins_with("boss_prep_") or node_type in ["battle", "elite", "boss", "start_position"]:
				continue
			if node_type.begins_with("event_"):
				candidate_ids.append(node_id)
	if candidate_ids.is_empty():
		return
	# 同じシードでは、保証マスの位置も毎回同じになるよう専用乱数を使う。
	var job_change_rng := RandomNumberGenerator.new()
	job_change_rng.seed = int(RunData.run_seed) + 771923
	var selected_id: String = candidate_ids[job_change_rng.randi_range(0, candidate_ids.size() - 1)]
	_node_data[selected_id]["type"] = "job_change"
	_node_data[selected_id]["label"] = _label_for_route_type("job_change")

func _choose_merge_group_count(source_count: int, rng: RandomNumberGenerator) -> int:
	# 調整設定から合流先の数を選ぶ。入力側のマス数を超えないようにする。
	var weights: Array = RunData.ROUTE_GENERATION_CONFIG["route_merge_group_count_weights"]
	if weights.is_empty():
		return mini(2, source_count)
	var selected_count: int = 2 + rng.rand_weighted(PackedFloat32Array(weights))
	return clampi(selected_count, 1, source_count)

func _connect_ordered_route_rows(source_ids: Array, target_ids: Array, branch_seed: int) -> void:
	# 各手番で上の段へ進み、横へは隣のレーンだけ選べる「すごろく型」の接続を作る。
	# 全てのマスから全方向へ道を出さず、設定数だけ横道を足してマップの混雑を抑える。
	if source_ids.is_empty() or target_ids.is_empty():
		return
	var ordered_sources: Array = source_ids.duplicate()
	ordered_sources.sort_custom(_route_node_column_less)
	var ordered_targets: Array = target_ids.duplicate()
	ordered_targets.sort_custom(_route_node_column_less)
	var source_count: int = ordered_sources.size()
	var target_count: int = ordered_targets.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = branch_seed
	var destinations_by_source: Array[Array] = []
	for source_index in range(source_count):
		destinations_by_source.append([])
	if target_count >= source_count:
		# 行き先が多いときは、まず隣り合うまとまりを各レーンへ割り当て全マスを到達可能にする。
		var child_counts: Array[int] = []
		var extras: int = target_count - source_count
		for source_index in range(source_count):
			child_counts.append(1)
		var candidate_sources: Array[int] = []
		if source_count == 3:
			# 3→5のような幅の変化は、隣り合う入口で小さな分岐に分ける。
			var first_pair_index: int = rng.randi_range(0, 1)
			candidate_sources.append(first_pair_index)
			candidate_sources.append(first_pair_index + 1)
		elif source_count >= 4:
			# 幅が増えるときは中央寄りに分岐を置き、端から端への道を避ける。
			for source_index in range(1, source_count - 1):
				candidate_sources.append(source_index)
		else:
			for source_index in range(source_count):
				candidate_sources.append(source_index)
		for shuffle_index in range(candidate_sources.size() - 1, 0, -1):
			var swap_index: int = rng.randi_range(0, shuffle_index)
			var temporary_index: int = candidate_sources[shuffle_index]
			candidate_sources[shuffle_index] = candidate_sources[swap_index]
			candidate_sources[swap_index] = temporary_index
		for extra_index in range(extras):
			child_counts[candidate_sources[extra_index % candidate_sources.size()]] += 1
		var target_cursor := 0
		for source_index in range(source_count):
			for child_index in range(child_counts[source_index]):
				destinations_by_source[source_index].append(target_cursor)
				target_cursor += 1
	else:
		# 行き先が少ないときは、全ての上段マスに少なくとも一つ道が届くよう順番に対応させる。
		for source_index in range(source_count):
			var target_index: int = floori(float(source_index) * float(target_count) / float(source_count))
			destinations_by_source[source_index].append(target_index)
	# 直進先に加えて、少数のマスだけ隣の上段へ行ける道を追加する。
	# すべてのマスを網目状につなぐのではなく、移動のたびに少しずつ進路を選ばせる。
	var minimum_branches: int = int(RunData.ROUTE_GENERATION_CONFIG["route_lateral_branch_min_count"])
	var maximum_branches: int = int(RunData.ROUTE_GENERATION_CONFIG["route_lateral_branch_max_count"])
	var branch_count: int = mini(rng.randi_range(minimum_branches, maxi(minimum_branches, maximum_branches)), source_count)
	var branch_candidates: Array[Vector2i] = []
	for source_index in range(source_count):
		var current_destinations: Array = destinations_by_source[source_index]
		var current_target: int = int(current_destinations[0])
		if current_destinations.size() > 1:
			continue
		# 進行方向の左右どちらにも候補を作り、後で交差しない組み合わせだけ選ぶ。
		for direction in [-1, 1]:
			var neighbor_target: int = current_target + direction
			if neighbor_target >= 0 and neighbor_target < target_count:
				branch_candidates.append(Vector2i(source_index, neighbor_target))
	for shuffle_index in range(branch_candidates.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, shuffle_index)
		var temporary_index: Vector2i = branch_candidates[shuffle_index]
		branch_candidates[shuffle_index] = branch_candidates[swap_index]
		branch_candidates[swap_index] = temporary_index
	var branches_added := 0
	for branch_candidate in branch_candidates:
		if branches_added >= branch_count:
			break
		var source_index: int = branch_candidate.x
		var neighbor_target: int = branch_candidate.y
		if destinations_by_source[source_index].has(neighbor_target):
			continue
		var proposed_min: int = mini(int(destinations_by_source[source_index][0]), neighbor_target)
		var proposed_max: int = maxi(int(destinations_by_source[source_index][-1]), neighbor_target)
		var would_cross := false
		for boundary_index in range(source_count - 1):
			var left_max: int = proposed_max if boundary_index == source_index else int(destinations_by_source[boundary_index][-1])
			var right_min: int = proposed_min if boundary_index + 1 == source_index else int(destinations_by_source[boundary_index + 1][0])
			if left_max > right_min:
				would_cross = true
				break
		if would_cross:
			continue
		destinations_by_source[source_index].append(neighbor_target)
		destinations_by_source[source_index].sort()
		branches_added += 1
	for source_index in range(source_count):
		var destinations: Array[String] = []
		for target_index in destinations_by_source[source_index]:
			destinations.append(str(ordered_targets[int(target_index)]))
		_node_data[str(ordered_sources[source_index])]["next"] = destinations

func _route_node_column_less(left_id: Variant, right_id: Variant) -> bool:
	return int(_node_data[str(left_id)]["column"]) < int(_node_data[str(right_id)]["column"])

func _set_route_edge_channel(source_id: String, target_id: String, group_index: int, group_count: int) -> void:
	# 隣の分岐グループとは別の横通路を使う。同じグループ内の枝だけが同じ高さで合流・分岐する。
	var channel_offset: float = (float(group_index) - float(group_count - 1) / 2.0) * 26.0
	_route_edge_channel_offsets[_route_edge_key(source_id, target_id)] = channel_offset

func _route_edge_key(source_id: String, target_id: String) -> String:
	return source_id + "->" + target_id

func _select_flexible_safe_type(route_types: Array, row_rng: RandomNumberGenerator, excluded_types: Array[String] = []) -> String:
	# 区間候補に休憩や宝箱などがあれば優先し、イベント多めプリセットでも戦闘回避策を用意する。
	var safe_types: Array[String] = []
	var configured_safe_types: Array = RunData.ROUTE_GENERATION_CONFIG["flexible_safe_route_types"]
	for route_type_value in route_types:
		var route_type: String = str(route_type_value)
		if not route_type.begins_with("event_") and route_type not in ["battle", "elite"] and not safe_types.has(route_type) and not excluded_types.has(route_type):
			safe_types.append(route_type)
	if safe_types.is_empty():
		for route_type_value in configured_safe_types:
			var configured_type: String = str(route_type_value)
			if not excluded_types.has(configured_type):
				safe_types.append(configured_type)
	var configured_weights: Array = RunData.ROUTE_GENERATION_CONFIG["flexible_safe_route_weights"]
	var weights: Array = []
	for safe_type in safe_types:
		var configured_index: int = _configured_safe_types_index(safe_type)
		weights.append(int(configured_weights[configured_index]) if configured_index >= 0 and configured_index < configured_weights.size() else 1)
	if safe_types.is_empty():
		return "rest"
	return safe_types[row_rng.rand_weighted(PackedFloat32Array(weights))]

func _configured_safe_types_index(route_type: String) -> int:
	# 配列の重みは候補名と同じ順に管理し、候補の順序を変えても対応を追跡する。
	var configured_safe_types: Array = RunData.ROUTE_GENERATION_CONFIG["flexible_safe_route_types"]
	for index in range(configured_safe_types.size()):
		if str(configured_safe_types[index]) == route_type:
			return index
	return -1

func _select_flexible_event_type(route_types: Array, safe_type: String, row_rng: RandomNumberGenerator, excluded_types: Array[String] = []) -> String:
	# 既に候補にあるイベントを優先し、イベントがない候補でも最低1つのイベント道を確保する。
	var event_types: Array[String] = []
	for route_type_value in route_types:
		var route_type: String = str(route_type_value)
		if route_type.begins_with("event_") and not event_types.has(route_type) and not excluded_types.has(route_type):
			event_types.append(route_type)
	if event_types.is_empty():
		event_types.assign(FALLBACK_ROUTE_EVENT_TYPES)
	var selected_event: String = event_types[row_rng.randi_range(0, event_types.size() - 1)]
	if selected_event == safe_type or excluded_types.has(selected_event):
		# 同じイベントが隣り合う選択肢にならないよう、別の既存イベントを使う。
		for fallback_event in FALLBACK_ROUTE_EVENT_TYPES:
			if fallback_event != safe_type and not excluded_types.has(fallback_event):
				return fallback_event
	return selected_event

func _position_route_nodes(last_row: int) -> void:
	# 行数からマップの高さを決め、左右に背景用の余白を足す。ルート本体の間隔は変えない。
	_map_rect = Rect2(0, 0, 1080.0 + MAP_SIDE_PADDING * 2.0, (last_row + 1) * MAP_ROW_HEIGHT)
	# 横幅は背景マップと同じにして、従来どおり画面幅に収める。縦方向には上下の余白を残す。
	_map_content_size = _map_rect.size + Vector2(0, 120)
	for node_id in _node_data:
		var node: Dictionary = _node_data[node_id]
		var column: int = node["column"]
		var x: float = MAP_SIDE_PADDING + (540.0 if column < 0 else NODE_COLUMNS[column])
		var y: float = _map_rect.size.y - 45.0 - node["row"] * MAP_ROW_HEIGHT
		_node_positions[node_id] = Vector2(x, y)

func _add_route_node(node_id: String, node_type: String, label_key: String, row: int, column: int, stage: int = 0) -> void:
	# rowは開始地点から上へ進む階層。分岐を横に広げて道筋を読み取りやすくする。
	_node_data[node_id] = {"type": node_type, "label": label_key, "stage": stage, "row": row, "column": column, "next": []}

func _label_for_route_type(node_type: String) -> String:
	# RunDataのルート候補だけで分岐の内容を差し替えられるよう、表示名を対応付ける。
	match node_type:
		"rest":
			return "JOURNEY_NODE_CAMP"
		"treasure":
			return "JOURNEY_NODE_TREASURE"
		"upgrade":
			return "JOURNEY_UPGRADE_CARD"
		"event_herbalist", "event_shrine", "event_caravan", "event_forge", "event_job_change":
			# マップ上ではイベントの中身を伏せ、選択してから内容を明かす。
			return "JOURNEY_NODE_EVENT"
		"shop":
			return "JOURNEY_NODE_SHOP"
		"job_change":
			return "JOURNEY_NODE_JOB_CHANGE"
		_:
			return "JOURNEY_NODE_CONTINUE"

func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.035, 0.045, 0.075, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	shade.add_child(root)
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 54)
	header.add_theme_constant_override("separation", 18)
	root.add_child(header)
	var title := Label.new()
	title.text = tr("JOURNEY_TITLE")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	header.add_child(title)
	_gold_label = Label.new()
	_gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_gold_label)
	_job_label = Label.new()
	_job_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_job_label)
	_progress_label = Label.new()
	_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_progress_label)
	_deck_button = Button.new()
	_deck_button.pressed.connect(_show_deck)
	header.add_child(_deck_button)
	# ScrollContainerは表示窓、CenterContainerはその中で仮想マップを中央に置く役割。
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(0, 0)
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(_scroll)
	var centering := CenterContainer.new()
	centering.custom_minimum_size = _map_content_size
	centering.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centering.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_child(centering)
	_map_content = Control.new()
	_map_content.custom_minimum_size = _map_content_size
	centering.add_child(_map_content)
	_map = Control.new()
	_map.position = (_map_content_size - _map_rect.size) / 2.0
	_map.custom_minimum_size = _map_rect.size
	_map.draw.connect(_draw_map)
	_map_content.add_child(_map)
	# ノードはControlとして線の上に配置し、キーボード・マウス双方で選べるようにする。
	for node_id in _node_positions:
		var button := Button.new()
		# マスのアイコンと道を隠さないよう、行き先名は小さな札に分けて下へ置く。
		# 列間隔150pxより短くして札同士の重なりを防ぎ、別レーンの選択肢と見分けやすくする。
		button.custom_minimum_size = Vector2(140, 30)
		button.add_theme_font_size_override("font_size", 15)
		var node_plate := StyleBoxFlat.new()
		node_plate.bg_color = Color(0.055, 0.075, 0.07, 0.86)
		node_plate.border_color = Color(0.72, 0.67, 0.47, 0.7)
		node_plate.set_border_width_all(1)
		node_plate.set_corner_radius_all(5)
		node_plate.content_margin_left = 4
		node_plate.content_margin_right = 4
		button.add_theme_stylebox_override("normal", node_plate)
		button.add_theme_stylebox_override("hover", node_plate)
		button.add_theme_stylebox_override("pressed", node_plate)
		button.pressed.connect(_on_node_pressed.bind(node_id))
		if initial_route_selection and node_id.begins_with("start_"):
			button.tooltip_text = tr("JOURNEY_INITIAL_DESC_" + node_id.trim_prefix("start_").to_upper())
		_map.add_child(button)
		_buttons[node_id] = button
	_map_footer = Label.new()
	_map_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_map_footer)
	# 休憩所の強化も報酬画面と同じカード表示・選択Viewに任せる。
	_card_choice_view = CardChoiceView.new()
	_card_choice_view.card_scene = CARD_SCENE
	_card_choice_view.show_panel_background = false
	_card_choice_view.visible = false
	_card_choice_view.card_selected.connect(_on_upgrade_card_choice_selected)
	_build_upgrade_window(shade)
	_build_deck_overlay(shade)
	_dialog = VBoxContainer.new()
	_dialog.visible = false
	# CanvasLayer直下ではminimum sizeだけでは実サイズに反映されないため明示する。
	_dialog.size = Vector2(560, 260)
	_dialog.custom_minimum_size = _dialog.size
	_dialog.position = (get_viewport().get_visible_rect().size - _dialog.size) / 2.0
	_dialog.add_theme_constant_override("separation", 10)
	add_child(_dialog)
	_dialog_title = Label.new()
	_dialog_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialog_title.add_theme_font_size_override("font_size", 28)
	_dialog.add_child(_dialog_title)
	# イベントでは説明文より先に絵を見せ、場面の印象が残る順番にする。
	_event_illustration_frame = PanelContainer.new()
	_event_illustration_frame.visible = false
	_event_illustration_frame.custom_minimum_size = Vector2(720, 320)
	var illustration_frame := StyleBoxFlat.new()
	illustration_frame.bg_color = Color(0.025, 0.04, 0.06, 1.0)
	illustration_frame.border_color = Color(0.72, 0.66, 0.46, 1.0)
	illustration_frame.set_border_width_all(3)
	illustration_frame.set_corner_radius_all(8)
	_event_illustration_frame.add_theme_stylebox_override("panel", illustration_frame)
	_dialog.add_child(_event_illustration_frame)
	_event_illustration = TextureRect.new()
	_event_illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_event_illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_event_illustration.custom_minimum_size = Vector2(714, 314)
	_event_illustration_frame.add_child(_event_illustration)
	# 転職報酬では一枚だけ大きく見せる。カード詳細は通常のカード表示に任せる。
	_job_reward_card_view = CardChoiceView.new()
	_job_reward_card_view.card_scene = CARD_SCENE
	_job_reward_card_view.show_panel_background = false
	_job_reward_card_view.row_cell_size = Vector2(260, 340)
	_job_reward_card_view.row_card_scale = 1.25
	_job_reward_card_view.custom_minimum_size = Vector2(280, 350)
	_job_reward_card_view.visible = false
	_dialog.add_child(_job_reward_card_view)
	_dialog_body = Label.new()
	_dialog_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialog_body.add_theme_font_size_override("font_size", 18)
	_dialog.add_child(_dialog_body)

func set_event_illustration(event_type: String, texture: Texture2D) -> void:
	# 将来専用の一枚絵ができたら、イベント・野営地・宝箱の場面ごとに画面へ渡せる。
	if texture == null:
		_event_illustrations.erase(event_type)
	else:
		_event_illustrations[event_type] = texture

func _build_upgrade_window(parent: Control) -> void:
	# 画面全体をモーダルにし、見出し・カード枠・スキップを別々の領域に分ける。
	_upgrade_backdrop = ColorRect.new()
	_upgrade_backdrop.color = Color(0.01, 0.02, 0.035, 0.5)
	_upgrade_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_upgrade_backdrop.visible = false
	_upgrade_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(_upgrade_backdrop)
	# 見出しと説明もカード枠の外に置きつつ、独立したパネルで読みやすくする。
	_upgrade_header_panel = PanelContainer.new()
	var header_frame := StyleBoxFlat.new()
	header_frame.bg_color = Color(0.045, 0.065, 0.095, 0.99)
	header_frame.border_color = Color(0.62, 0.72, 0.78, 0.95)
	header_frame.set_border_width_all(2)
	header_frame.set_corner_radius_all(12)
	header_frame.content_margin_left = 16
	header_frame.content_margin_right = 16
	_upgrade_header_panel.add_theme_stylebox_override("panel", header_frame)
	_upgrade_backdrop.add_child(_upgrade_header_panel)
	var header_content := VBoxContainer.new()
	header_content.add_theme_constant_override("separation", 2)
	_upgrade_header_panel.add_child(header_content)
	_upgrade_title = Label.new()
	_upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upgrade_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_upgrade_title.add_theme_font_size_override("font_size", 26)
	header_content.add_child(_upgrade_title)
	_upgrade_body = Label.new()
	_upgrade_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upgrade_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_upgrade_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_content.add_child(_upgrade_body)
	_upgrade_window = PanelContainer.new()
	_upgrade_window.visible = false
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.045, 0.065, 0.095, 0.99)
	frame.border_color = Color(0.62, 0.72, 0.78, 0.95)
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(12)
	frame.content_margin_left = 18
	frame.content_margin_top = 14
	frame.content_margin_right = 18
	frame.content_margin_bottom = 14
	_upgrade_window.add_theme_stylebox_override("panel", frame)
	_upgrade_backdrop.add_child(_upgrade_window)
	_card_choice_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_choice_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_card_choice_view.custom_minimum_size = Vector2(0, 360)
	_upgrade_window.add_child(_card_choice_view)
	_upgrade_skip = Button.new()
	_upgrade_skip.text = tr("JOURNEY_UPGRADE_SKIP")
	_upgrade_skip.custom_minimum_size = Vector2(240, 44)
	_upgrade_skip.pressed.connect(_on_upgrade_skip_pressed)
	_upgrade_backdrop.add_child(_upgrade_skip)

func _layout_upgrade_window(show_cards: bool) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var panel_width: float = minf(1120.0, viewport_size.x - 48.0)
	var panel_height: float = maxf(120.0, viewport_size.y - 190.0)
	_upgrade_header_panel.position = Vector2((viewport_size.x - panel_width) / 2.0, 12.0)
	_upgrade_header_panel.size = Vector2(panel_width, 78.0)
	_upgrade_title.custom_minimum_size = Vector2(0.0, 34.0)
	_upgrade_body.custom_minimum_size = Vector2(0.0, 32.0)
	_upgrade_window.position = Vector2((viewport_size.x - panel_width) / 2.0, 100.0)
	_upgrade_window.size = Vector2(panel_width, panel_height)
	_upgrade_window.visible = show_cards
	_upgrade_skip.position = Vector2((viewport_size.x - _upgrade_skip.custom_minimum_size.x) / 2.0, viewport_size.y - 58.0)

func _build_deck_overlay(parent: Control) -> void:
	# マップの上に独立した閲覧レイヤーを置き、ルート選択状態を保ったままデッキを確認する。
	_deck_overlay = ColorRect.new()
	_deck_overlay.color = Color(0.015, 0.025, 0.04, 0.88)
	_deck_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_deck_overlay.visible = false
	_deck_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_deck_overlay.gui_input.connect(_on_deck_overlay_input)
	parent.add_child(_deck_overlay)
	var panel := PanelContainer.new()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	panel.size = Vector2(minf(1120.0, viewport_size.x - 48.0), minf(620.0, viewport_size.y - 48.0))
	panel.position = (viewport_size - panel.size) / 2.0
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.055, 0.075, 0.11, 0.99)
	frame.border_color = Color(0.62, 0.72, 0.78, 0.95)
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(12)
	frame.content_margin_left = 16
	frame.content_margin_top = 12
	frame.content_margin_right = 16
	frame.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", frame)
	_deck_overlay.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)
	var heading := HBoxContainer.new()
	layout.add_child(heading)
	_deck_title = Label.new()
	_deck_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_deck_title.add_theme_font_size_override("font_size", 24)
	heading.add_child(_deck_title)
	var close_button := Button.new()
	close_button.text = tr("JOURNEY_DECK_CLOSE")
	close_button.pressed.connect(_close_deck)
	heading.add_child(close_button)
	_deck_choice_view = CardChoiceView.new()
	_deck_choice_view.card_scene = CARD_SCENE
	_deck_choice_view.show_panel_background = false
	_deck_choice_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_choice_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_deck_choice_view)

func _show_deck() -> void:
	# RunDataのデッキ全体を閲覧専用グリッドへ渡し、表示件数も見出しに含める。
	var deck: Array[CardData] = RunData.get_deck()
	_deck_title.text = tr("JOURNEY_DECK_TITLE") % deck.size()
	_deck_choice_view.set_cards(deck, false, true)
	_deck_overlay.visible = true

func _close_deck() -> void:
	if is_instance_valid(_deck_overlay):
		_deck_overlay.visible = false

func _on_deck_overlay_input(event: InputEvent) -> void:
	# 枠外をクリックした時も、閉じるボタンと同じ操作で一覧を閉じる。
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_deck()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and _deck_overlay.visible:
		_close_deck()
		get_viewport().set_input_as_handled()

func _refresh_map() -> void:
	# 現在地から道を上向き・横向きにたどり、道がつながっている行き先を調べる。
	_card_choice_view.clear_cards()
	_upgrade_backdrop.visible = false
	_upgrade_window.visible = false
	_deck_overlay.visible = false
	_upgrade_deck_indices.clear()
	_upgrade_targets.clear()
	_upgrade_gold_cost = 0
	_upgrade_skip.text = tr("JOURNEY_UPGRADE_SKIP")
	_reset_dialog_geometry()
	_reachable.clear()
	_reachable_paths.clear()
	var current: String = RunData.current_route_node_id
	_visible_route_nodes.clear()
	# 開始地点を決めた後も全体像は残し、どのレーンを選んだかだけを強調する。
	for node_id in _node_data:
		_visible_route_nodes[node_id] = true
	if initial_route_selection and current == "new_run":
		# 初回はプレイヤーがまだマップ上にいないため、全ての開始地点を選べる。
		for start_id in RunData.STARTING_POSITION_IDS:
			_reachable["start_" + str(start_id)] = true
	elif _node_data.has(current):
		# 画面の道は複数の線が交差して接続して見えることがある。
		# ボタン判定も道の線そのものをたどることで、見た目と実際の移動を一致させる。
		_find_upward_route_paths(current)
	_gold_label.text = tr("JOURNEY_GOLD") % RunData.gold
	var job_name_key: String = "JOURNEY_JOB_MAGE" if RunData.current_job == "mage" else "JOURNEY_JOB_WARRIOR"
	var job_trait_key: String = "JOURNEY_JOB_MAGE_TRAIT" if RunData.current_job == "mage" else "JOURNEY_JOB_WARRIOR_TRAIT"
	_job_label.text = tr("JOURNEY_CURRENT_JOB") % tr(job_name_key)
	_job_label.tooltip_text = tr(job_trait_key)
	_progress_label.text = tr("JOURNEY_PROGRESS") % [RunData.completed_battles, RunData.get_normal_battle_count()]
	_deck_button.text = tr("JOURNEY_DECK_BUTTON") % RunData.get_deck().size()
	if initial_route_selection:
		_map_footer.text = tr("JOURNEY_INITIAL_MAP_NEXT") if current == "new_run" else tr("JOURNEY_INITIAL_MAP_CONTINUE")
	else:
		_map_footer.text = tr("JOURNEY_MAP_NEXT")
	for node_id in _node_positions:
		var button: Button = _buttons[node_id]
		button.visible = _visible_route_nodes.has(node_id)
		if not button.visible:
			continue
		var data: Dictionary = _node_data[node_id]
		button.text = _node_label(node_id, data)
		button.disabled = show_campaign_clear or not _reachable.has(node_id)
		button.position = _node_positions[node_id] - Vector2(button.custom_minimum_size.x / 2.0, -22.0)
		button.modulate = Color(0.72, 0.85, 1.0) if _reachable.has(node_id) else Color(0.62, 0.65, 0.72)
	_refresh_player_marker()
	_map.queue_redraw()
	# 長いマップでは現在地を中央付近に寄せ、次の分岐をすぐ選べる状態で開く。
	call_deferred("_center_current_node")

func _reset_dialog_geometry() -> void:
	# イベント用ダイアログを常に画面中央へ戻す。
	if not is_instance_valid(_dialog):
		return
	_dialog.size = Vector2(560, 260)
	_dialog.custom_minimum_size = _dialog.size
	_dialog.position = (get_viewport().get_visible_rect().size - _dialog.size) / 2.0

func _center_current_node() -> void:
	if not is_instance_valid(_scroll):
		return
	if initial_route_selection and RunData.current_route_node_id == "new_run":
		# 初回マップは全体を見せつつ、最下段の開始位置が見える位置で開く。
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
		return
	if not _node_positions.has(RunData.current_route_node_id):
		return
	var map_top: float = (_map_content_size.y - _map_rect.size.y) / 2.0
	var current_y: float = map_top + _node_positions[RunData.current_route_node_id].y
	_scroll.scroll_vertical = maxi(0, int(current_y - _scroll.size.y / 2.0))

func refresh_map() -> void:
	# BattleSceneから回復量・所持金を反映した直後に呼ばれる公開更新口。
	_dialog.visible = false
	_refresh_map()

func _node_label(node_id: String, data: Dictionary) -> String:
	if _node_data[node_id]["type"] == "start_position":
		return tr(data["label"])
	if data["type"] == "battle":
		return tr("JOURNEY_BATTLE_NODE")
	if data["type"] == "boss":
		return tr("JOURNEY_BOSS_NODE")
	return tr(data["label"])

func _draw_map() -> void:
	# 専用タイル画像がなくても、色と小さな草むらで地形のマス目を表現する。
	if map_background_texture:
		_map.draw_texture_rect(map_background_texture, _map_rect, false, Color(0.38, 0.48, 0.43, 0.72))
	else:
		_map.draw_rect(_map_rect, Color(0.16, 0.23, 0.17, 1.0))
		for tile_y in range(0, int(_map_rect.size.y), MAP_TILE_SIZE):
			for tile_x in range(0, int(_map_rect.size.x), MAP_TILE_SIZE):
				var tile_rect := Rect2(tile_x, tile_y, MAP_TILE_SIZE, MAP_TILE_SIZE)
				var tile_variant: int = (floori(float(tile_x) / MAP_TILE_SIZE) * 7 + floori(float(tile_y) / MAP_TILE_SIZE) * 11) % 5
				var grass_tone: float = 0.015 * float(tile_variant - 2)
				_map.draw_rect(tile_rect, Color(0.17 + grass_tone, 0.25 + grass_tone, 0.18 + grass_tone, 1.0))
				_map.draw_rect(tile_rect, Color(0.62, 0.72, 0.48, 0.07), false, 1.0)
				if tile_variant == 1 or tile_variant == 4:
					# 草の短い線をタイルごとに散らし、単色の格子に見えないようにする。
					var tuft := Vector2(tile_x + 18 + tile_variant * 5, tile_y + 31)
					var grass_color := Color(0.48, 0.59, 0.34, 0.34)
					_map.draw_line(tuft, tuft + Vector2(-3, -6), grass_color, 2.0)
					_map.draw_line(tuft, tuft + Vector2(3, -8), grass_color, 2.0)
	for node_id in _node_data:
		if not _visible_route_nodes.has(node_id):
			continue
		var start: Vector2 = _node_positions[node_id]
		for next_id in _node_data[node_id]["next"]:
			if not _visible_route_nodes.has(next_id):
				continue
			var end: Vector2 = _node_positions[next_id]
			var visited := _is_visited(node_id) and _is_visited(next_id)
			var next_step: bool = node_id == RunData.current_route_node_id and _reachable.has(next_id)
			var path_color := Color(0.98, 0.75, 0.32, 1.0) if visited or next_step else Color(0.38, 0.42, 0.39, 0.48)
			var edge_key: String = _route_edge_key(str(node_id), str(next_id))
			var channel_offset: float = float(_route_edge_channel_offsets.get(edge_key, 0.0))
			_draw_route_connection(start, end, path_color, channel_offset)
	# 直接のnext辺に限らず、今回たどれる道筋全体を金色で示す。
	for path_value in _reachable_paths.values():
		var reachable_path: Array = path_value
		_draw_route_path(reachable_path, Color(0.98, 0.75, 0.32, 1.0))
	for node_id in _node_positions:
		if not _visible_route_nodes.has(node_id):
			continue
		_draw_route_node(node_id)
	_draw_player_marker()

func _draw_route_connection(start: Vector2, end: Vector2, path_color: Color, channel_offset: float = 0.0) -> void:
	var points: Array[Vector2] = _route_connection_points(start, end, channel_offset)
	_draw_route_path(points, path_color)

func _draw_route_path(points: Array, path_color: Color) -> void:
	# グラフの辺にもBFSで見つけた経路にも同じ道幅・縁取りを使う。
	var highlighted := path_color.a >= 0.9
	var outline_alpha: float = 0.82 if highlighted else 0.38
	var road_width: float = 18.0 if highlighted else 12.0
	for point_index in range(points.size() - 1):
		var segment_start: Vector2 = Vector2(points[point_index])
		var segment_end: Vector2 = Vector2(points[point_index + 1])
		# 線分は水平か垂直だけにし、暗い縁取りと土色を重ねてタイル道に見せる。
		_map.draw_line(segment_start, segment_end, Color(0.11, 0.13, 0.09, outline_alpha), road_width + 7.0, false)
		_map.draw_line(segment_start, segment_end, path_color, road_width, false)
		var highlight_alpha: float = 0.28 if highlighted else 0.08
		_map.draw_line(segment_start, segment_end, Color(0.91, 0.81, 0.58, highlight_alpha), 2.0, false)
	# 直角の角にも道幅ぶんのマスを置き、線の端が角で欠けないようにする。
	for point_index in range(1, points.size() - 1):
		var corner: Vector2 = points[point_index]
		var border_size := (road_width + 7.0) / 2.0
		var road_size := road_width / 2.0
		_map.draw_rect(Rect2(corner - Vector2(border_size, border_size), Vector2(border_size * 2.0, border_size * 2.0)), Color(0.11, 0.13, 0.09, outline_alpha))
		_map.draw_rect(Rect2(corner - Vector2(road_size, road_size), Vector2(road_size * 2.0, road_size * 2.0)), path_color)

func _route_connection_points(start: Vector2, end: Vector2, channel_offset: float = 0.0) -> Array[Vector2]:
	# 描画と主人公の移動で同じ直角経路を使う。隣接する枝は専用の高さを通す。
	var points: Array[Vector2] = [start]
	if not is_equal_approx(start.x, end.x) and not is_equal_approx(start.y, end.y):
		var midpoint_y: float = (start.y + end.y) / 2.0 + channel_offset
		# 複数段を飛び越す辺は、途中の行き先を通ったように見えないよう曲がり位置をずらす。
		if absf(start.y - end.y) >= MAP_ROW_HEIGHT * 1.5:
			var toward_start: float = 1.0 if start.y > end.y else -1.0
			midpoint_y += toward_start * MAP_ROW_HEIGHT * 0.4
		points.append(Vector2(start.x, midpoint_y))
		points.append(Vector2(end.x, midpoint_y))
	points.append(end)
	return points

func _draw_route_node(node_id: String) -> void:
	var center: Vector2 = _node_positions[node_id]
	var node_type: String = _node_data[node_id]["type"]
	var tile_color := Color(0.19, 0.27, 0.24, 1.0)
	match node_type:
		"battle", "elite":
			tile_color = Color(0.42, 0.22, 0.18, 1.0) if node_type == "elite" else Color(0.34, 0.27, 0.2, 1.0)
		"boss":
			tile_color = Color(0.43, 0.15, 0.16, 1.0)
		"rest":
			tile_color = Color(0.19, 0.34, 0.23, 1.0)
		"treasure":
			tile_color = Color(0.39, 0.33, 0.15, 1.0)
		"upgrade":
			tile_color = Color(0.25, 0.25, 0.4, 1.0)
		"shop":
			tile_color = Color(0.37, 0.28, 0.17, 1.0)
		"job_change":
			tile_color = Color(0.22, 0.31, 0.4, 1.0)
		"start_position":
			tile_color = Color(0.16, 0.34, 0.36, 1.0)
		"event_herbalist", "event_shrine", "event_caravan", "event_forge", "event_job_change":
			tile_color = Color(0.18, 0.32, 0.31, 1.0)
	var tile := Rect2(center - Vector2(23, 20), Vector2(46, 40))
	_map.draw_rect(tile, tile_color)
	var border_color := Color(0.98, 0.8, 0.42, 1.0) if _is_visited(node_id) or _reachable.has(node_id) else Color(0.5, 0.57, 0.49, 0.92)
	_map.draw_rect(tile, border_color, false, 2.0)
	var icon_color := Color(0.96, 0.91, 0.72, 1.0)
	match node_type:
		"battle", "elite":
			# 交差した剣のシルエット。エリートは赤いマスで危険度を示す。
			_map.draw_line(center + Vector2(-9, 8), center + Vector2(7, -8), icon_color, 4.0, true)
			_map.draw_line(center + Vector2(9, 8), center + Vector2(-7, -8), icon_color, 4.0, true)
			_map.draw_line(center + Vector2(-12, 11), center + Vector2(-5, 11), icon_color, 3.0)
			_map.draw_line(center + Vector2(5, 11), center + Vector2(12, 11), icon_color, 3.0)
		"boss":
			_map.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -13), center + Vector2(12, 0), center + Vector2(0, 13), center + Vector2(-12, 0)]), Color(1.0, 0.77, 0.28))
		"rest":
			_map.draw_rect(Rect2(center + Vector2(-3, -12), Vector2(6, 24)), icon_color)
			_map.draw_rect(Rect2(center + Vector2(-12, -3), Vector2(24, 6)), icon_color)
		"treasure":
			_map.draw_rect(Rect2(center + Vector2(-12, -5), Vector2(24, 16)), Color(0.98, 0.75, 0.25))
			_map.draw_line(center + Vector2(-12, 1), center + Vector2(12, 1), Color(0.39, 0.28, 0.12), 3.0)
			_map.draw_rect(Rect2(center + Vector2(-2, 1), Vector2(4, 6)), Color(0.39, 0.28, 0.12))
		"upgrade":
			_map.draw_line(center + Vector2(0, 11), center + Vector2(0, -10), icon_color, 4.0, true)
			_map.draw_line(center + Vector2(-9, -2), center + Vector2(0, -11), icon_color, 4.0, true)
			_map.draw_line(center + Vector2(9, -2), center + Vector2(0, -11), icon_color, 4.0, true)
		"shop":
			_map.draw_circle(center, 10.0, Color(0.98, 0.77, 0.3))
			_map.draw_circle(center, 4.0, Color(0.48, 0.34, 0.12))
		"job_change":
			_map.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -12), center + Vector2(10, 0), center + Vector2(0, 12), center + Vector2(-10, 0)]), Color(0.68, 0.83, 1.0))
		"start_position":
			# 開始位置は戦闘ノードと見分けやすいよう、旗印を描く。
			_map.draw_line(center + Vector2(-8, 12), center + Vector2(-8, -12), icon_color, 3.0)
			_map.draw_colored_polygon(PackedVector2Array([center + Vector2(-7, -11), center + Vector2(10, -7), center + Vector2(-7, -2)]), Color(0.98, 0.78, 0.32))
		_:
			_map.draw_circle(center, 8.0, Color(0.63, 0.9, 0.77))
			_map.draw_circle(center, 3.0, Color(0.12, 0.28, 0.25))

func _draw_player_marker() -> void:
	if _displayed_player_node_id.is_empty():
		return
	# 小さな冒険者を現在地の少し上に描き、道しるべの名前を隠さないようにする。
	var hero := _player_marker_position + Vector2(0, -31)
	_map.draw_circle(hero + Vector2(0, 7), 11.0, Color(0.05, 0.07, 0.06, 0.7))
	_map.draw_circle(hero, 13.0, Color(0.98, 0.83, 0.43, 0.95))
	_map.draw_circle(hero, 10.0, Color(0.1, 0.16, 0.22, 1.0))
	_map.draw_colored_polygon(PackedVector2Array([hero + Vector2(-7, 3), hero + Vector2(6, 3), hero + Vector2(8, 13), hero + Vector2(-8, 13)]), Color(0.56, 0.23, 0.2))
	_map.draw_rect(Rect2(hero + Vector2(-5, -1), Vector2(10, 12)), Color(0.8, 0.83, 0.78))
	_map.draw_circle(hero + Vector2(0, -7), 6.0, Color(0.94, 0.76, 0.56))
	_map.draw_rect(Rect2(hero + Vector2(-7, -12), Vector2(14, 4)), Color(0.83, 0.68, 0.31))
	_map.draw_line(hero + Vector2(7, 3), hero + Vector2(12, -7), Color(0.85, 0.9, 0.95), 2.0)

func _refresh_player_marker() -> void:
	if not _node_positions.has(RunData.current_route_node_id):
		return
	var target_id: String = RunData.current_route_node_id
	if _displayed_player_node_id.is_empty():
		_displayed_player_node_id = target_id
		_player_marker_position = _node_positions[target_id]
		return
	if target_id != _displayed_player_node_id:
		_displayed_player_node_id = target_id
		_animate_player_marker_to(target_id, 0.42)

func _animate_player_marker_to(node_id: String, duration: float) -> Tween:
	if not _node_positions.has(node_id):
		return null
	if is_instance_valid(_player_marker_tween) and _player_marker_tween.is_running():
		_player_marker_tween.kill()
	_player_marker_tween = create_tween()
	_player_marker_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var points: Array[Vector2] = []
	if _reachable_paths.has(node_id):
		points.assign(_reachable_paths[node_id])
		if points.is_empty() or points[0].distance_to(_player_marker_position) > 1.0:
			points.push_front(_player_marker_position)
		if points[-1].distance_to(_node_positions[node_id]) > 1.0:
			points.append(_node_positions[node_id])
	else:
		var marker_channel_offset: float = float(_route_edge_channel_offsets.get(_route_edge_key(_displayed_player_node_id, node_id), 0.0))
		points = _route_connection_points(_player_marker_position, _node_positions[node_id], marker_channel_offset)
	var total_distance := 0.0
	for point_index in range(points.size() - 1):
		total_distance += points[point_index].distance_to(points[point_index + 1])
	for point_index in range(points.size() - 1):
		var segment_start: Vector2 = points[point_index]
		var segment_end: Vector2 = points[point_index + 1]
		var segment_duration: float = duration * segment_start.distance_to(segment_end) / total_distance
		_player_marker_tween.tween_method(_set_player_marker_position, segment_start, segment_end, segment_duration)
	return _player_marker_tween

func _find_upward_route_paths(start_id: String) -> void:
	# 道の中心線を小さなグリッドに置き換え、左右と上だけに進める探索を行う。
	# これにより、道が交差して見える地点も実際の接続として扱える。
	const ROAD_GRID_SIZE: float = 4.0
	var road_cells: Dictionary = {}
	var node_ids_by_cell: Dictionary = {}
	for node_id_value in _node_positions:
		var node_id: String = str(node_id_value)
		var cell: Vector2i = _road_cell(_node_positions[node_id], ROAD_GRID_SIZE)
		if not node_ids_by_cell.has(cell):
			node_ids_by_cell[cell] = []
		node_ids_by_cell[cell].append(node_id)
	for source_value in _node_data:
		var source_id: String = str(source_value)
		for target_value in _node_data[source_id]["next"]:
			var target_id: String = str(target_value)
			if not _node_positions.has(target_id):
				continue
			var edge_key: String = _route_edge_key(source_id, target_id)
			var offset: float = float(_route_edge_channel_offsets.get(edge_key, 0.0))
			var points: Array[Vector2] = _route_connection_points(_node_positions[source_id], _node_positions[target_id], offset)
			for point_index in range(points.size() - 1):
				_mark_road_segment(road_cells, points[point_index], points[point_index + 1], ROAD_GRID_SIZE)
	var start_cell: Vector2i = _road_cell(_node_positions[start_id], ROAD_GRID_SIZE)
	var pending: Array[Vector2i] = [start_cell]
	var parent_by_cell: Dictionary = {start_cell: start_cell}
	var cursor: int = 0
	var start_row: int = int(_node_data[start_id]["row"])
	while cursor < pending.size():
		var cell: Vector2i = pending[cursor]
		cursor += 1
		if node_ids_by_cell.has(cell):
			var reached_destination := false
			for reached_id_value in node_ids_by_cell[cell]:
				var reached_id: String = str(reached_id_value)
				if reached_id == start_id:
					continue
				if int(_node_data[reached_id]["row"]) >= start_row and not _is_visited(reached_id):
					_reachable[reached_id] = true
					_reachable_paths[reached_id] = _restore_road_path(cell, start_cell, parent_by_cell, ROAD_GRID_SIZE, _node_positions[start_id], _node_positions[reached_id])
					reached_destination = true
			# 未訪問の行き先に着いたらそこで止め、先のマスは到着後に選ばせる。
			if reached_destination:
				continue
		# 水平方向は左右に移動できる。縦方向は画面上側（進行方向）だけを許可する。
		for neighbor in [cell + Vector2i.LEFT, cell + Vector2i.RIGHT, cell + Vector2i.UP]:
			if not road_cells.has(neighbor) or parent_by_cell.has(neighbor):
				continue
			if node_ids_by_cell.has(neighbor):
				var blocked_by_visited_node := false
				for node_at_neighbor_value in node_ids_by_cell[neighbor]:
					var node_at_neighbor: String = str(node_at_neighbor_value)
					if node_at_neighbor != start_id and _is_visited(node_at_neighbor):
						blocked_by_visited_node = true
						break
				if blocked_by_visited_node:
					continue
			parent_by_cell[neighbor] = cell
			pending.append(neighbor)

func _road_cell(position: Vector2, grid_size: float) -> Vector2i:
	return Vector2i(roundi(position.x / grid_size), roundi(position.y / grid_size))

func _mark_road_segment(road_cells: Dictionary, start: Vector2, finish: Vector2, grid_size: float) -> void:
	# 道は水平・垂直なので、端点を含むセルをすべて埋めれば交差判定もできる。
	var start_cell: Vector2i = _road_cell(start, grid_size)
	var finish_cell: Vector2i = _road_cell(finish, grid_size)
	if start_cell.x == finish_cell.x:
		for y in range(mini(start_cell.y, finish_cell.y), maxi(start_cell.y, finish_cell.y) + 1):
			road_cells[Vector2i(start_cell.x, y)] = true
	else:
		for x in range(mini(start_cell.x, finish_cell.x), maxi(start_cell.x, finish_cell.x) + 1):
			road_cells[Vector2i(x, start_cell.y)] = true

func _restore_road_path(end_cell: Vector2i, start_cell: Vector2i, parent_by_cell: Dictionary, grid_size: float, start_position: Vector2, end_position: Vector2) -> Array[Vector2]:
	# BFSの親情報から道筋を戻し、一直線のセル群を角だけの滑らかな経路にまとめる。
	var reversed_cells: Array[Vector2i] = [end_cell]
	var cell: Vector2i = end_cell
	while cell != start_cell:
		cell = parent_by_cell[cell]
		reversed_cells.append(cell)
	reversed_cells.reverse()
	var path: Array[Vector2] = [start_position]
	var previous_direction := Vector2i.ZERO
	for index in range(1, reversed_cells.size()):
		var direction: Vector2i = reversed_cells[index] - reversed_cells[index - 1]
		if previous_direction != Vector2i.ZERO and direction != previous_direction:
			path.append(Vector2(reversed_cells[index - 1]) * grid_size)
		previous_direction = direction
	path.append(end_position)
	return path

func _set_player_marker_position(position: Vector2) -> void:
	_player_marker_position = position
	_map.queue_redraw()

func _is_visited(node_id: String) -> bool:
	return RunData.route_history.has(node_id)

func _on_node_pressed(node_id: String) -> void:
	if not _reachable.has(node_id):
		return
	var node_type: String = _node_data[node_id]["type"]
	# 行き先を決めたらまずマップ上を歩かせ、到着するまで次のマスを選べないようにする。
	for button_value in _buttons.values():
		var node_button: Button = button_value
		node_button.disabled = true
	var movement: Tween = null
	if initial_route_selection and RunData.current_route_node_id == "new_run" and node_type == "start_position":
		# まだマップ上の現在地がない最初の選択は、移動元なしで選んだ開始位置に立たせる。
		_player_marker_position = _node_positions[node_id]
	else:
		movement = _animate_player_marker_to(node_id, 0.42)
	if movement != null:
		await movement.finished
	# 到着後にだけ現在地・通過ルートを更新し、その地点のイベントや報酬を処理する。
	RunData.move_to_route_node(node_id)
	_displayed_player_node_id = node_id
	_map.queue_redraw()
	_center_current_node()
	RunData.trigger_relic_hook(RunData.RelicHook.ROUTE_NODE_SELECTED, {"node_id": node_id, "node_type": node_type})
	match node_type:
		"shop":
			_show_shop(node_id)
		"event_herbalist", "event_shrine", "event_caravan", "event_forge":
			_show_event(node_id)
		"event_job_change":
			_show_job_change(node_id, true)
		"upgrade":
			_show_upgrade(node_id)
		"rest":
			_show_camp_choice(node_id)
		"treasure":
			_show_relic_offer(node_id)
		"job_change":
			_show_job_change(node_id)
		"battle", "elite", "boss":
			route_selected.emit(node_id, node_type, 0)
		"start_position":
			if initial_route_selection:
				# まず開始地点を確定。接続先の初戦ノードを選ぶまで冒険ルートに留まる。
				RunData.choose_starting_position(node_id.trim_prefix("start_"))
				refresh_map()

func _show_job_change(node_id: String, is_event_offer: bool = false) -> void:
	# 現職と反対の職業を提示する。転職を断っても、この地点から先へ進める。
	var target_job: String = "mage" if RunData.current_job == "warrior" else "warrior"
	var target_is_mage: bool = target_job == "mage"
	_dialog.size = Vector2(780, 620)
	_dialog.custom_minimum_size = _dialog.size
	_dialog.position = (get_viewport().get_visible_rect().size - _dialog.size) / 2.0
	_dialog_title.text = tr("JOURNEY_EVENT_JOB_CHANGE_TITLE") if is_event_offer else tr("JOURNEY_JOB_CHANGE_TITLE")
	if is_event_offer:
		_dialog_body.text = tr("JOURNEY_EVENT_JOB_CHANGE_BODY_MAGE" if target_is_mage else "JOURNEY_EVENT_JOB_CHANGE_BODY_WARRIOR")
	else:
		_dialog_body.text = tr("JOURNEY_JOB_CHANGE_BODY" if target_is_mage else "JOURNEY_JOB_CHANGE_BODY_WARRIOR")
	_clear_dialog_buttons()
	_event_illustration.texture = EVENT_IMAGE_PLACEHOLDER
	_event_illustration_frame.visible = true
	var accept_key: String = "JOURNEY_JOB_CHANGE_ACCEPT" if target_is_mage else "JOURNEY_JOB_CHANGE_ACCEPT_WARRIOR"
	var stay_key: String = "JOURNEY_JOB_CHANGE_DECLINE" if RunData.current_job == "warrior" else "JOURNEY_JOB_CHANGE_STAY_MAGE"
	_dialog_button(tr(accept_key)).pressed.connect(_show_job_change_reward.bind(node_id, target_job))
	_dialog_button(tr(stay_key)).pressed.connect(func(): route_selected.emit(node_id, "job_change", 0))
	_dialog.visible = true

func _show_camp_choice(node_id: String) -> void:
	# 野営地では回復と強化のどちらか一方を選び、同じマスで両方の恩恵は得られない。
	_prepare_illustrated_dialog("JOURNEY_CAMP_TITLE", "JOURNEY_CAMP_BODY", "camp")
	var rest_button := _dialog_button(tr("JOURNEY_CAMP_REST"))
	rest_button.pressed.connect(func(): route_selected.emit(node_id, "rest", 30))
	var upgrade_button := _dialog_button(tr("JOURNEY_CAMP_UPGRADE"))
	upgrade_button.disabled = not _has_upgradeable_card()
	if upgrade_button.disabled:
		upgrade_button.tooltip_text = tr("JOURNEY_CAMP_UPGRADE_UNAVAILABLE")
	upgrade_button.pressed.connect(_show_upgrade.bind(node_id, 0, "JOURNEY_CAMP_UPGRADE_TITLE", "JOURNEY_CAMP_UPGRADE_BODY", "rest"))
	_dialog.visible = true

func _show_job_change_reward(node_id: String, target_job: String) -> void:
	# 転職報酬は受け取りを強制せず、カードの内容を見てから獲得か見送りを選べる。
	var reward_guid: String = RunData.get_job_change_reward_guid(target_job)
	var database := DataBase.new()
	database.load_cards()
	var reward_card: CardData = database.get_card(reward_guid) if not reward_guid.is_empty() else null
	if reward_card == null:
		job_change_selected.emit(node_id, target_job, null)
		return
	_dialog.size = Vector2(780, 620)
	_dialog.custom_minimum_size = _dialog.size
	_dialog.position = (get_viewport().get_visible_rect().size - _dialog.size) / 2.0
	_dialog_title.text = tr("JOURNEY_JOB_REWARD_TITLE")
	_dialog_body.text = tr("JOURNEY_JOB_REWARD_BODY")
	_clear_dialog_buttons()
	var reward_cards: Array[CardData] = [reward_card]
	_job_reward_card_view.set_cards(reward_cards, false)
	_job_reward_card_view.visible = true
	_dialog_button(tr("JOURNEY_JOB_REWARD_CLAIM")).pressed.connect(_finish_job_change.bind(node_id, target_job, reward_card))
	_dialog_button(tr("JOURNEY_JOB_REWARD_SKIP")).pressed.connect(_finish_job_change.bind(node_id, target_job, null))
	_dialog.visible = true

func _finish_job_change(node_id: String, target_job: String, reward_card: CardData) -> void:
	# 受け取るかどうかを含めてBattleSceneへ渡し、転職と現在地を一度に確定する。
	job_change_selected.emit(node_id, target_job, reward_card)

func _show_shop(node_id: String) -> void:
	# 同じ店に戻った時は現在の在庫を描き直し、購入状態も維持する。
	if _active_shop_id != node_id:
		_generate_shop_stock(node_id)
	_dialog.size = Vector2(720, 500)
	_dialog.position = (get_viewport().get_visible_rect().size - _dialog.size) / 2.0
	_dialog_title.text = tr("JOURNEY_SHOP_TITLE")
	_dialog_body.text = tr("JOURNEY_SHOP_BODY")
	_gold_label.text = tr("JOURNEY_GOLD") % RunData.gold
	_clear_dialog_buttons()
	for index in range(_shop_card_stock.size()):
		var card: CardData = _shop_card_stock[index]
		var price := 40 + card.rarity * 15
		var card_button := _dialog_button(tr("JOURNEY_SHOP_CARD") % [card.name, price])
		card_button.disabled = _shop_card_sold[index] or RunData.gold < price
		card_button.pressed.connect(_buy_shop_card.bind(index, price))
	if _shop_item_stock != null:
		var item_price := 45
		var item_button := _dialog_button(tr("JOURNEY_SHOP_ITEM") % [_shop_item_stock.name, item_price])
		item_button.disabled = _shop_item_sold or RunData.gold < item_price or RunData.items.size() >= RunData.ITEM_CAPACITY
		item_button.pressed.connect(_buy_shop_item.bind(item_price))
	if _shop_relic_stock != null:
		var relic_price := 100
		var relic_description := Label.new()
		relic_description.text = _shop_relic_stock.description
		relic_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_dialog.add_child(relic_description)
		var relic_button := _dialog_button(tr("JOURNEY_SHOP_RELIC") % [_shop_relic_stock.name, relic_price])
		relic_button.disabled = _shop_relic_sold or RunData.gold < relic_price or RunData.has_relic(_shop_relic_stock.guid)
		relic_button.pressed.connect(_buy_shop_relic.bind(relic_price))
	var remove_button := _dialog_button(tr("JOURNEY_SHOP_REMOVE") % 60)
	remove_button.disabled = _shop_card_removal_used or RunData.gold < 60 or RunData.deck.size() <= 1
	remove_button.pressed.connect(_show_shop_card_removal)
	_dialog_button(tr("JOURNEY_SHOP_LEAVE")).pressed.connect(func(): route_selected.emit(node_id, "shop", 0))
	_dialog.visible = true

func _generate_shop_stock(node_id: String) -> void:
	# 店ごとの専用シードで在庫を固定し、戦闘や他の抽選の乱数列から独立させる。
	var shop_rng := RandomNumberGenerator.new()
	shop_rng.seed = absi((str(RunData.run_seed) + ":" + node_id).hash())
	var database := DataBase.new()
	var cards := database.load_cards_for_job(RunData.current_job)
	for index in range(cards.size() - 1, 0, -1):
		var swap_index := shop_rng.randi_range(0, index)
		var card_to_swap: CardData = cards[index]
		cards[index] = cards[swap_index]
		cards[swap_index] = card_to_swap
	_shop_card_stock.clear()
	_shop_card_sold.clear()
	for index in range(mini(3, cards.size())):
		_shop_card_stock.append(cards[index])
		_shop_card_sold.append(false)
	var items := database.load_items()
	_shop_item_stock = items[shop_rng.randi_range(0, items.size() - 1)] if not items.is_empty() else null
	_shop_item_sold = false
	var available_relics: Array[RelicData] = []
	for relic in database.load_relics():
		if not RunData.has_relic(relic.guid):
			available_relics.append(relic)
	for index in range(available_relics.size() - 1, 0, -1):
		var swap_index := shop_rng.randi_range(0, index)
		var relic_to_swap: RelicData = available_relics[index]
		available_relics[index] = available_relics[swap_index]
		available_relics[swap_index] = relic_to_swap
	_shop_relic_stock = available_relics[0] if not available_relics.is_empty() else null
	_shop_relic_sold = false
	_shop_card_removal_used = false
	_active_shop_id = node_id

func _buy_shop_card(stock_index: int, price: int) -> void:
	# 残高の再確認後に支払いとデッキ追加を行い、購入状態を保存する。
	if stock_index < 0 or stock_index >= _shop_card_stock.size() or _shop_card_sold[stock_index] or RunData.gold < price:
		return
	if not RunData.spend_gold(price):
		return
	RunData.add_card(_shop_card_stock[stock_index])
	_shop_card_sold[stock_index] = true
	_show_shop(_active_shop_id)

func _buy_shop_item(price: int) -> void:
	# 所持枠を先に確認し、アイテムを保持できる場合だけ支払いを受け付ける。
	if _shop_item_stock == null or _shop_item_sold or RunData.items.size() >= RunData.ITEM_CAPACITY or RunData.gold < price:
		return
	if not RunData.spend_gold(price) or not RunData.add_item(_shop_item_stock):
		return
	_shop_item_sold = true
	_show_shop(_active_shop_id)

func _buy_shop_relic(price: int) -> void:
	# 所持済みかどうかを再確認し、購入時にレリック効果とHUD表示へ反映する。
	if _shop_relic_stock == null or _shop_relic_sold or RunData.has_relic(_shop_relic_stock.guid) or RunData.gold < price:
		return
	if not RunData.spend_gold(price):
		return
	if not RunData.add_relic(_shop_relic_stock):
		RunData.add_gold(price)
		return
	_shop_relic_sold = true
	shop_relic_purchased.emit(_shop_relic_stock)
	_show_shop(_active_shop_id)

func _show_shop_card_removal() -> void:
	if _shop_card_removal_used or RunData.gold < 60 or RunData.deck.size() <= 1:
		return
	_dialog_title.text = tr("JOURNEY_SHOP_REMOVE_TITLE")
	_dialog_body.text = tr("JOURNEY_SHOP_REMOVE_BODY")
	_clear_dialog_buttons()
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialog.add_child(scroll)
	var card_list := VBoxContainer.new()
	card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(card_list)
	for index in range(RunData.deck.size()):
		var card: CardData = RunData.deck[index]
		var card_button := _dialog_button(card.name, card_list)
		card_button.pressed.connect(_remove_shop_card.bind(index))
	_dialog_button(tr("JOURNEY_SHOP_BACK")).pressed.connect(func(): _show_shop(_active_shop_id))

func _remove_shop_card(index: int) -> void:
	# 60ゴールドを支払い、最後の1枚を残して選択カードをデッキから外す。
	if _shop_card_removal_used or RunData.gold < 60 or RunData.deck.size() <= 1:
		return
	if not RunData.spend_gold(60):
		return
	if not RunData.remove_card(index):
		RunData.add_gold(60)
		return
	_shop_card_removal_used = true
	_gold_label.text = tr("JOURNEY_GOLD") % RunData.gold
	_show_shop(_active_shop_id)

func _show_event(node_id: String) -> void:
	var event_type: String = _node_data[node_id]["type"]
	var prefix: String = event_type.trim_prefix("event_").to_upper()
	_prepare_illustrated_dialog("JOURNEY_EVENT_" + prefix + "_TITLE", "JOURNEY_EVENT_" + prefix + "_BODY", event_type)
	if prefix == "FORGE":
		# 強化するカードがない・支払いができない時は、イベントを開始できない。
		var forge_cost: int = 30
		var forge_button := _dialog_button(tr("JOURNEY_EVENT_FORGE_UPGRADE") % forge_cost)
		forge_button.disabled = RunData.gold < forge_cost or not _has_upgradeable_card()
		forge_button.pressed.connect(_show_forge_upgrade.bind(node_id, forge_cost))
		_dialog_button(tr("JOURNEY_EVENT_LEAVE")).pressed.connect(func(): route_selected.emit(node_id, "event_forge", 0))
		_dialog.visible = true
		return
	var heal_button := _dialog_button(tr("JOURNEY_EVENT_" + prefix + "_HEAL"))
	var gold_button := _dialog_button(tr("JOURNEY_EVENT_" + prefix + "_GOLD"))
	heal_button.custom_minimum_size = Vector2(0, 48)
	gold_button.custom_minimum_size = Vector2(0, 48)
	heal_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gold_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cost := 10 if prefix == "HERBALIST" else (20 if prefix == "CARAVAN" else 0)
	heal_button.disabled = RunData.gold < cost
	heal_button.pressed.connect(func(): event_selected.emit(node_id, 25 if prefix == "HERBALIST" else 30, -cost))
	gold_button.pressed.connect(func(): event_selected.emit(node_id, 0, 20 if prefix == "HERBALIST" else (30 if prefix == "SHRINE" else 35)))
	_dialog.visible = true

func _has_upgradeable_card() -> bool:
	# 入口で強化可否を知らせ、支払い後に強化候補がない状況を避ける。
	var database := DataBase.new()
	database.load_cards()
	for card in RunData.get_deck():
		if not card.upgrade_guid.is_empty() and database.get_card(card.upgrade_guid) != null:
			return true
	return false

func _show_forge_upgrade(node_id: String, gold_cost: int) -> void:
	# 冒険中に使い込んだ技を鍛える場面。支払いはカード決定時まで確定しない。
	_show_upgrade(node_id, gold_cost, "JOURNEY_EVENT_FORGE_PICK_TITLE", "JOURNEY_EVENT_FORGE_PICK_BODY")

func _show_upgrade(node_id: String, gold_cost: int = 0, title_key: String = "JOURNEY_UPGRADE_TITLE", body_key: String = "JOURNEY_UPGRADE_PROMPT", route_node_type: String = "upgrade") -> void:
	_dialog.visible = false
	_upgrade_node_id = node_id
	_upgrade_gold_cost = gold_cost
	_upgrade_route_node_type = route_node_type
	_upgrade_skip.text = tr("JOURNEY_UPGRADE_SKIP") if gold_cost <= 0 else tr("JOURNEY_EVENT_FORGE_SKIP")
	_upgrade_title.text = tr(title_key)
	_upgrade_body.text = tr(body_key)
	_card_choice_view.visible = true
	var database := DataBase.new()
	database.load_cards()
	var deck: Array[CardData] = RunData.get_deck()
	var upgrade_choices: Array[CardData] = []
	for index in range(deck.size()):
		var card: CardData = deck[index]
		if card.upgrade_guid.is_empty():
			continue
		var upgraded: CardData = database.get_card(card.upgrade_guid)
		if upgraded == null:
			continue
		upgrade_choices.append(card)
		_upgrade_deck_indices.append(index)
		_upgrade_targets.append(upgraded)
	if upgrade_choices.is_empty():
		_upgrade_body.text = tr("JOURNEY_UPGRADE_NONE")
		_card_choice_view.clear_cards()
		_layout_upgrade_window(false)
	else:
		# 強化候補は数が少なくても同じ一覧UIを使う。大量時は枠内で確実にスクロールできる。
		_card_choice_view.set_cards(upgrade_choices, true, true)
		_card_choice_view.present_cards()
		_layout_upgrade_window(true)
	_upgrade_backdrop.visible = true

func _on_upgrade_skip_pressed() -> void:
	# 強化を見送ってマップへ戻る時も、選択中の地点を通過済みにする。
	var node_type: String = "event_forge" if _upgrade_gold_cost > 0 else _upgrade_route_node_type
	route_selected.emit(_upgrade_node_id, node_type, 0)

func _show_relic_offer(node_id: String) -> void:
	# 通常はレリック1つだけ提示し、所持中の羅針盤の効果で候補数を増やす。
	RunData.trigger_relic_hook(RunData.RelicHook.TREASURE_OPENED, {"node_id": node_id})
	_prepare_illustrated_dialog("JOURNEY_RELIC_TITLE", "JOURNEY_RELIC_BODY", "treasure")
	var database := DataBase.new()
	var available: Array[RelicData] = []
	for relic in database.load_relics():
		if not RunData.has_relic(relic.guid):
			available.append(relic)
	Random.get_instance().shuffle_array(available)
	var offer_count: int = mini(RunData.get_treasure_choice_count(), available.size())
	if offer_count == 0:
		_dialog_body.text = tr("JOURNEY_RELIC_NONE")
		_dialog_button(tr("JOURNEY_NODE_CONTINUE")).pressed.connect(func(): route_selected.emit(node_id, "treasure", 0))
	else:
		for index in range(offer_count):
			var relic: RelicData = available[index]
			var button := _dialog_button("%s — %s" % [relic.name, relic.description])
			button.pressed.connect(_on_relic_selected.bind(node_id, relic))
		# 合わないレリックを無理に取らず、何も得ずに宝箱の前を通り過ぎられる。
		_dialog_button(tr("JOURNEY_RELIC_SKIP")).pressed.connect(func(): route_selected.emit(node_id, "treasure", 0))
	_dialog.visible = true

func _prepare_illustrated_dialog(title_key: String, body_key: String, illustration_key: String) -> void:
	# イベント・野営地・宝箱で、タイトル→一枚絵→説明→選択肢の順番と寸法を共有する。
	_dialog.size = Vector2(780, 620)
	_dialog.custom_minimum_size = _dialog.size
	_dialog.position = (get_viewport().get_visible_rect().size - _dialog.size) / 2.0
	_dialog_title.text = tr(title_key)
	_dialog_body.text = tr(body_key)
	_clear_dialog_buttons()
	_event_illustration.texture = _event_illustrations.get(illustration_key, EVENT_IMAGE_PLACEHOLDER) as Texture2D
	_event_illustration_frame.visible = true

func _on_relic_selected(node_id: String, relic: RelicData) -> void:
	# 報酬獲得とマップの現在地更新を続けて行い、次の行き先を開く。
	relic_selected.emit(node_id, relic)
	route_selected.emit(node_id, "treasure", 0)

func _on_upgrade_card_choice_selected(_card: CardData, choice_index: int) -> void:
	# 表示上の選択番号から、デッキ内の実カード位置と強化後定義を引き当てる。
	if choice_index < 0 or choice_index >= _upgrade_deck_indices.size() or choice_index >= _upgrade_targets.size():
		return
	# 強化カードを決めた時だけ支払うため、見送りでゴールドを失わない。
	if _upgrade_gold_cost > 0 and not RunData.spend_gold(_upgrade_gold_cost):
		return
	card_upgrade_requested.emit(_upgrade_deck_indices[choice_index], _upgrade_targets[choice_index])
	var node_type: String = "event_forge" if _upgrade_gold_cost > 0 else _upgrade_route_node_type
	route_selected.emit(_upgrade_node_id, node_type, 0)

func _dialog_button(text_value: String, parent: Node = null) -> Button:
	var button := Button.new()
	button.text = text_value
	if parent == null:
		_dialog.add_child(button)
	else:
		parent.add_child(button)
	return button

func _clear_dialog_buttons() -> void:
	# 絵枠とカード枠は使い回し、他の画面では非表示にして配置から外す。
	_event_illustration_frame.visible = false
	_job_reward_card_view.visible = false
	_job_reward_card_view.clear_cards()
	for child in _dialog.get_children():
		if child != _dialog_title and child != _dialog_body and child != _event_illustration_frame and child != _job_reward_card_view:
			child.queue_free()

func _show_clear_dialog() -> void:
	_dialog_title.text = tr("JOURNEY_CLEAR_TITLE")
	_dialog_body.text = tr("JOURNEY_CLEAR_BODY")
	_clear_dialog_buttons()
	_dialog_button(tr("JOURNEY_NEW_RUN")).pressed.connect(func(): new_run_requested.emit())
	_dialog.visible = true
