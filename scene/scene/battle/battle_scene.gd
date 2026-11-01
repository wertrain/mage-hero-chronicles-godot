class_name BattleScene
extends SceneBase

const CARD_SCENE: PackedScene = preload("res://scene/card/card.tscn")
const BATTLE_SCENE_PATH := "res://scene/scene/battle/battle_scene.tscn"
const DEFAULT_ROAD_BATTLE_BACKGROUND: Texture2D = preload("res://art/background/battleback_meadow_cc0.png")
const DEFAULT_FOREST_BATTLE_BACKGROUND: Texture2D = preload("res://art/background/battleback_forest_cc0.png")
const DEFAULT_RUINS_BATTLE_BACKGROUND: Texture2D = preload("res://art/background/battleback_cave_cc0.png")
const DEFAULT_ELITE_BATTLE_BACKGROUND: Texture2D = preload("res://art/background/battleback_dungeon_cc0.png")
const DEFAULT_BOSS_BATTLE_BACKGROUND: Texture2D = preload("res://art/background/battleback_cave_cc0.png")

## 通常戦の編成。ルート設定で戦闘数を増やしても、この表を循環して編成を変える。
const NORMAL_ENCOUNTER_CYCLE := [
	# 各組み合わせの役割を分け、旅の途中でも違う対処が必要になるようにする。
	[0, 0], [1, 4], [6, 0], [3, 4], [12, 30],
	[2, 18], [1, 6], [5, 12], [30, 18], [0, 6, 4],
	# 追加した敵は単体・混成の両方へ置き、行動の違いを戦闘中に試せるようにする。
	[10, 0], [13, 4], [19], [36, 6], [10, 13], [19, 2], [36, 30],
]

## 戦闘シーン
##
## 戦闘に関わるすべての要素はここでインスタンス化する
## シーケンス自体は StateMachine で管理する

@export var enemy_scene: PackedScene
@export var hands_scene: PackedScene
@export var action_message_window: PackedScene
@export var target_selection_arrow: PackedScene
## JourneyScreenの仮背景を置き換える画像。パス画面の線とボタンはこの上に描画する。
@export var journey_map_background: Texture2D
## エリアと戦闘種別ごとの背景。ボス戦だけ差し替える場合もここで設定できる。
@export_group("Battle backgrounds")
@export var road_battle_background: Texture2D = DEFAULT_ROAD_BATTLE_BACKGROUND
@export var forest_battle_background: Texture2D = DEFAULT_FOREST_BATTLE_BACKGROUND
@export var ruins_battle_background: Texture2D = DEFAULT_RUINS_BATTLE_BACKGROUND
@export var elite_battle_background: Texture2D = DEFAULT_ELITE_BATTLE_BACKGROUND
@export var boss_battle_background: Texture2D = DEFAULT_BOSS_BATTLE_BACKGROUND

var _battle_info: BattleInfo
var _enemy: BattleEnemy
var _enemies: Array[BattleEnemy] = []
var _card_pile: Array[CardData]  = []
var _discard_pile: Array[CardData]  = []
var _hands: Hands
var _player: BattlePlayerStatus
var _camera: Camera2D
var _target_selection_arrow: BezierArrow
var _debug_force_victory_requested := false
var _item_panel: PanelContainer
var _item_list: VBoxContainer
var _item_toggle: Button
var _relic_row: HBoxContainer
var _relic_icons: Dictionary = {}
var _pile_inspector_layer: CanvasLayer
var _pile_inspector_title: Label
var _pile_inspector_view: CardChoiceView
var _deck_pile_button: Button
var _discard_pile_button: Button
var _battle_log_layer: CanvasLayer
var _battle_log_label: Label
var _battle_log_turns: int = 0
var _battle_log_cards_played: int = 0
var _battle_log_last_health: int = 0
var _battle_log_damage_taken: int = 0
var _battle_log_recorded: bool = false
var _battle_log_encounter_names: Array[String] = []

func get_battle_info() -> BattleInfo:
	return _battle_info

func get_enemy() -> BattleEnemy:
	return _enemy

func get_enemies() -> Array[BattleEnemy]:
	return _enemies

func get_player() -> BattlePlayerStatus:
	return _player

func get_card_pile() -> Array[CardData]:
	return _card_pile

func get_discard_pile() -> Array[CardData]:
	return _discard_pile
	
func get_hands() -> Hands:
	return _hands

func set_end_turn_enabled(enabled: bool) -> void:
	# 行動選択中だけ終了ボタンを受け付け、ターン進行中の二重入力を防ぐ。
	$HUD/Button_EndTurn.disabled = not enabled

func get_camera() -> Camera2D:
	return _camera
	
func get_sequence_message() -> SequenceMessage:
	return $SequenceMessage

func get_effect_spawner() -> EffectSpawner:
	return $EffectSpawner

func get_target_selection_arrow() -> BezierArrow:
	return _target_selection_arrow

func show_action_message(message: String, seconds: float, position: Vector2) -> void:
	var action_message = action_message_window.instantiate()
	action_message.position = position
	add_child(action_message)
	await action_message.show_message(message, seconds)
	action_message.queue_free()
	
func set_monsters(monster_data_ids: Array[int]) -> void:
	# encounter list のIDごとに敵を生成する。IDを複数渡せば同じ戦闘に並んで出る。
	# モンスター間の間隔（スペース）
	const spacing: float = 48.0
	# モンスターを生成して追加
	var total_width: float = 0.0
	# 余白分を考慮して画像サイズを半分で計算
	const width_scale: float = 0.5
	for _index in range(monster_data_ids.size()):
		var enemy: BattleEnemy = enemy_scene.instantiate()
		var enemy_width: float = enemy.get_sprite_rect().size.x * width_scale
		total_width += enemy_width
		_enemies.append(enemy)
	# モンスター間の間隔を合計幅に加算
	total_width += spacing * (_enemies.size() - 1)
	# 画面サイズの取得
	var viewport_rect: Vector2 = get_viewport().size
	# モンスター群の幅を画面中央に配置
	var start_x: float = (viewport_rect.x - total_width) / 2.0
	var current_x: float = start_x
	# 各モンスターを配置
	for enemy in _enemies:
		var enemy_width: float = enemy.get_sprite_rect().size.x * width_scale
		var enemy_height: float = enemy.get_sprite_rect().size.y
		# モンスターの中心を基準として配置
		enemy.position.x = current_x + enemy_width / 2  # 左側から中央基準に調整
		enemy.position.y = viewport_rect.y / 2.0 - enemy_height / 2.0
		current_x += enemy_width + spacing
		$Background.add_sibling(enemy)
	_enemy = _enemies[0]

func _layout_monsters() -> void:
	# set_data 後に画像サイズが変わるため、実際のスプライト寸法で並びを再計算する。
	var total_width: float = 0.0
	for enemy in _enemies:
		total_width += enemy.get_sprite_rect().size.x * 0.5
	const spacing: float = 48.0
	if _enemies.size() > 1:
		total_width += spacing * (_enemies.size() - 1)
	var current_x: float = (get_viewport().size.x - total_width) / 2.0
	for enemy in _enemies:
		var sprite_size: Vector2 = enemy.get_sprite_rect().size
		var width: float = sprite_size.x * 0.5
		enemy.position = Vector2(current_x + width / 2.0, get_viewport().size.y / 2.0 - sprite_size.y / 2.0)
		current_x += width + spacing

func _ready() -> void:
	if not RunData.relic_hook_triggered.is_connected(_on_relic_hook_triggered):
		RunData.relic_hook_triggered.connect(_on_relic_hook_triggered)
	# 次戦フラグを先に確定する。敵編成を選んだ後ではボス判定が間に合わない。
	RunData.current_battle_is_boss = RunData.next_battle_is_boss
	RunData.next_battle_is_boss = false
	RunData.current_battle_is_elite = RunData.next_battle_is_elite
	RunData.next_battle_is_elite = false
	var battle_background := _get_battle_background()
	$Background.visible = battle_background != null
	if battle_background != null:
		$Background.set_battle_background(battle_background)
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_camera)
	#_enemy = enemy_scene.instantiate()
	#var viewport_rect = get_viewport().size
	#_enemy.position.x = viewport_rect.x / 2.0
	#_enemy.position.y = viewport_rect.y / 2.0 - _enemy.get_sprite_rect().size.y / 2.0
	#_enemies.append(_enemy)
	var enemy_data_ids: Array[int]
	# 各通常戦は複数敵の編成、最終戦はボス単独の編成にする。
	if RunData.current_battle_is_boss:
		enemy_data_ids = [35]
	elif RunData.current_battle_is_elite:
		# エリートは通常戦より耐久力と攻撃力を上げた2体編成にする。
		enemy_data_ids = [1, 3]
	else:
		# 編成表を循環させるため、ルート設定で戦闘数を変更しても敵データが尽きない。
		var encounter_index: int = RunData.completed_battles % NORMAL_ENCOUNTER_CYCLE.size()
		for enemy_id in NORMAL_ENCOUNTER_CYCLE[encounter_index]:
			enemy_data_ids.append(int(enemy_id))
	set_monsters(enemy_data_ids)
	# カードのロードとデッキ作成
	var database = DataBase.new()
	var _cards_origin = database.load_cards()
	# エディタからこの戦闘シーンを直接実行した場合も、既定の戦士デッキで動作する。
	var starter_deck = database.load_deck(RunData.requested_start_job)
	# 初回だけ初期デッキを登録する。シーン再読込時は報酬・強化済みのデッキを維持する。
	RunData.initialize(starter_deck)
	# ランのシードを表示する。戦闘シーンを作り直すたびに乱数列を巻き戻さない。
	$DebugDraw.current_seed = RunData.run_seed
	_card_pile = RunData.get_deck()
	var enemies_data = database.load_enemy()
	# encounter list と同じ順番で敵データを割り当てる。
	for index in range(_enemies.size()):
		_enemies[index].set_data(enemies_data[enemy_data_ids[index]])
		_battle_log_encounter_names.append(_enemies[index].get_data().name)
		if RunData.current_battle_is_elite:
			_enemies[index].promote_to_elite()
		if not RunData.current_battle_is_boss:
			# 通常戦とエリート戦は、突破数に応じて少しずつ耐久・攻撃が上がる。
			# RunDataの設定値を変えると、序盤の手触りを保ったまま成長速度を調整できる。
			var scaling: Dictionary = RunData.ENCOUNTER_BALANCE_CONFIG
			var battles_per_step: int = maxi(1, int(scaling["battles_per_step"]))
			var depth_steps: int = mini(int(scaling["max_steps"]), floori(float(RunData.completed_battles) / float(battles_per_step)))
			_enemies[index].scale_for_depth(depth_steps, float(scaling["health_growth_per_step"]), int(scaling["attack_growth_per_step"]))
	_layout_monsters()
	Random.get_instance().shuffle_array(_card_pile)
	# プレイヤーの作成
	_player = BattlePlayerStatus.new()
	_player.set_max_energy(RunData.get_max_energy())
	_player.energy_changed.connect(_on_energy_changed)
	_player.health_changed.connect(_on_player_health_changed)
	_player.shield_changed.connect(_on_player_shield_changed)
	_player.status_effects_changed.connect(_on_player_status_effects_changed)
	_player.shield_reset.connect(_on_player_shield_reset)
	_player.set_health(RunData.current_health, _player.get_max_health())
	_battle_log_last_health = _player.get_health()
	$HealthBar.set_health(_player.get_health(), _player.get_max_health())
	$HUD.update_energy(_player.get_energy(), _player.get_max_energy())
	# 手札を作成
	_hands = hands_scene.instantiate()
	_hands.set_field(_player, _card_pile, _discard_pile)
	_hands.card_drawn.connect(_on_card_drawn)
	_hands.active_card_changed.connect(_on_active_card_changed)
	_hands.deck_reshuffled.connect(_on_deck_reshuffled)
	_hands.card_used.connect(_on_card_used)
	_hands.card_discarded.connect(_on_card_discarded)
	$Background.add_sibling(_hands)
	$HUD/Button_EndTurn.pressed.connect(_on_endturn_button_down)
	_build_item_ui()
	_build_relic_row()
	#$BattlePlayerStatus.setup(_player)
	_update_card_pile_num()
	_update_discard_pile_num()
	_build_card_pile_inspector()
	_build_battle_log_ui()
	_target_selection_arrow = target_selection_arrow.instantiate()
	add_child(_target_selection_arrow)
	$StateMachine.current_state.transitioned.emit("BattleStart")
	_battle_info = BattleInfo.new()
	_battle_info._enemies = _enemies
	_battle_info._player = _player

func _get_battle_background() -> Texture2D:
	if RunData.current_battle_is_boss:
		return boss_battle_background
	if RunData.current_battle_is_elite:
		return elite_battle_background
	match RunData.starting_route_id:
		"forest":
			return forest_battle_background
		"ruins":
			return ruins_battle_background
		_:
			return road_battle_background

func _on_endturn_button_down():
	# Tween演出中などに連打されても、行動選択状態からの1回だけ受け付ける。
	if $StateMachine.current_state.name != "ActionSelection":
		return
	set_end_turn_enabled(false)
	$StateMachine.current_state.transitioned.emit("PlayerTurnEnd")
	#$StateMachine.current_state.transitioned.emit("EnemyTurnStart")
	#get_sequence_message().show_message("Enemy's Turn")
	#ScreenEffect.play_shake(_camera)
	#ScreenEffect.play_flash(_enemy.get_sprite(), Color.RED)
	#ScreenEffect.play_flash_screen(self, Color.WHITE, 0.05, 2)
	#$EffectSpawner.spawn(EffectSpawner.EffectType.IMPACT_A, 0, _enemy.position)

func _on_card_drawn(_card_data: CardData):
	_update_card_pile_num()

func _on_active_card_changed(_card_data: CardData):
	pass

func _on_deck_reshuffled():
	_update_card_pile_num()
	_update_discard_pile_num()
	
func _on_card_used(_card_data: CardData):
	_battle_log_cards_played += 1
	_refresh_battle_log_text()
	
func _on_card_discarded(_card_data: CardData):
	_update_discard_pile_num()
	
func _on_player_health_changed(health: int, max_health: int):
	$HealthBar.set_health(health, max_health)
	# 回復を差し引かずに、戦闘中に実際に受けたHPダメージを積算する。
	if health < _battle_log_last_health:
		_battle_log_damage_taken += _battle_log_last_health - health
	_battle_log_last_health = health
	# 次の戦闘へ遷移する前にHPを保存し、シーン再読込後に引き継ぐ。
	RunData.set_health(health, max_health)
	_refresh_battle_log_text()

func _on_player_shield_changed(shield: int):
	$HealthBar.set_shield(shield)

func _on_player_status_effects_changed(status_effects: Array[BattleStatusEffect]):
	$HealthBar.set_status_effect_icons(status_effects)

func _on_player_shield_reset():
	$HealthBar.set_shield(0)

func _on_energy_changed(energy: int, max_energy:int):
	$HUD.update_energy(energy, max_energy)
	ScreenEffect.play_pulse($HUD/Node2D_Energy)

func _process(_delta: float) -> void:
	# 敵ターン中は誤使用できないよう、現在の戦闘フェーズに合わせて操作可否を更新する。
	if is_instance_valid(_item_toggle):
		var player_turn: bool = $StateMachine.current_state.name == "ActionSelection"
		_item_toggle.disabled = not player_turn or RunData.items.is_empty()
		if not player_turn:
			_item_panel.visible = false

func _build_item_ui() -> void:
	# 既存HUDの配置を崩さず、ターン終了ボタンの上に所持品メニューを追加する。
	_item_toggle = Button.new()
	_item_toggle.position = Vector2(968, 480)
	_item_toggle.size = Vector2(243, 42)
	_item_toggle.pressed.connect(_toggle_item_panel)
	$HUD.add_child(_item_toggle)
	_item_panel = PanelContainer.new()
	_item_panel.position = Vector2(868, 300)
	_item_panel.size = Vector2(343, 170)
	_item_panel.visible = false
	$HUD.add_child(_item_panel)
	_item_list = VBoxContainer.new()
	_item_list.add_theme_constant_override("separation", 8)
	_item_panel.add_child(_item_list)
	_refresh_item_ui()

func _build_relic_row() -> void:
	# 画面上端の左側にレリックを並べる。名前と効果はツールチップで確認できる。
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 12)
	scroll.size = Vector2(760, 58)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	$HUD.add_child(scroll)
	_relic_row = HBoxContainer.new()
	_relic_row.add_theme_constant_override("separation", 6)
	scroll.add_child(_relic_row)
	_refresh_relic_row()

func _refresh_relic_row() -> void:
	if not is_instance_valid(_relic_row):
		return
	_relic_icons.clear()
	for child in _relic_row.get_children():
		child.queue_free()
	for relic in RunData.relics:
		var icon := PanelContainer.new()
		icon.custom_minimum_size = Vector2(48, 48)
		icon.tooltip_text = "%s\n%s" % [relic.name, relic.description]
		var mark := Label.new()
		mark.text = relic.name.substr(0, 1)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.add_child(mark)
		_relic_row.add_child(icon)
		_relic_icons[relic.guid] = icon

func _on_relic_hook_triggered(hook, context: Dictionary) -> void:
	# 各タイミングで、所持レリックのデータに登録された効果だけを適用する。
	var hook_id: int = int(hook)
	var target_player: BattlePlayerStatus = context.get("player", _player) as BattlePlayerStatus
	var hook_name: String = RunData.get_relic_hook_name(hook_id)
	var did_activate: Array[RelicData] = []
	# プレイヤーのターン開始フックはレリックの有無に関係なく来るので、ターン数計測にも使う。
	if hook_id == RunData.RelicHook.PLAYER_TURN_START:
		_battle_log_turns += 1
		_refresh_battle_log_text()
	# 開幕シールドは既存フィールドを使い、初回ドロー後という新しい発動時点に集約する。
	if hook_id == RunData.RelicHook.BATTLE_START_AFTER_DRAW:
		var shield_amount: int = RunData.get_battle_start_shield()
		if target_player != null and shield_amount > 0:
			target_player.add_shield(shield_amount)
			for relic in RunData.relics:
				if relic.battle_start_shield > 0:
					did_activate.append(relic)
	for relic in RunData.relics:
		for effect: Dictionary in relic.hook_effects:
			if str(effect.get("trigger", "")) != hook_name:
				continue
			# 条件を指定した効果は、その条件に合うイベントの時だけ発動する。
			var required_node_type: String = str(effect.get("node_type", ""))
			if not required_node_type.is_empty() and str(context.get("node_type", "")) != required_node_type:
				continue
			var amount: int = int(effect.get("amount", 0))
			var applied := false
			match str(effect.get("type", "")):
				"shield":
					if target_player != null:
						target_player.add_shield(amount)
						applied = amount > 0
				"heal":
					if target_player != null:
						target_player.heal(amount)
						applied = amount > 0
				"gold":
					RunData.add_gold(amount)
					applied = amount > 0
				"bonus_gold", "extra_relic_choice":
					# 報酬金額や候補数は専用の集計関数が反映し、ここでは発動演出だけ行う。
					applied = amount > 0
				"draw":
					# レリックのドロー効果も通常の山札処理を使い、捨て札再循環や配置を崩さない。
					if is_instance_valid(_hands):
						for _draw_index in range(maxi(0, amount)):
							_hands._draw_card()
						applied = amount > 0
			if applied:
				did_activate.append(relic)
	for relic in RunData.relics:
		if not did_activate.has(relic):
			continue
		var icon: Control = _relic_icons.get(relic.guid)
		if not is_instance_valid(icon):
			continue
		_play_relic_activation(icon)

func trigger_relic_hook(hook, context: Dictionary = {}) -> void:
	RunData.trigger_relic_hook(hook, context)

func _build_battle_log_ui() -> void:
	# HUDの隅にログを開く入口を置き、戦闘を止めずに現在値を見られるようにする。
	var button := Button.new()
	button.text = tr("BATTLE_LOG_BUTTON")
	button.position = Vector2(1050, 18)
	button.size = Vector2(210, 38)
	button.pressed.connect(_toggle_battle_log)
	$HUD.add_child(button)
	_battle_log_layer = CanvasLayer.new()
	_battle_log_layer.layer = 40
	_battle_log_layer.visible = false
	add_child(_battle_log_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.04, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_battle_log_layer.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(270, 72)
	panel.size = Vector2(740, 570)
	_battle_log_layer.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = tr("BATTLE_LOG_TITLE")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = tr("BATTLE_LOG_CLOSE")
	close_button.pressed.connect(_toggle_battle_log)
	header.add_child(close_button)
	var history_scroll := ScrollContainer.new()
	history_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(history_scroll)
	_battle_log_label = Label.new()
	_battle_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_battle_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_battle_log_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_battle_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	history_scroll.add_child(_battle_log_label)
	_refresh_battle_log_text()

func _toggle_battle_log() -> void:
	_battle_log_layer.visible = not _battle_log_layer.visible
	_refresh_battle_log_text()

func _refresh_battle_log_text() -> void:
	if not is_instance_valid(_battle_log_label):
		return
	var encounter_text: String = ", ".join(PackedStringArray(_battle_log_encounter_names))
	var current_text: String = tr("BATTLE_LOG_CURRENT") % [encounter_text, _battle_log_turns, _battle_log_cards_played, _battle_log_damage_taken]
	var history_text := ""
	var limit: int = mini(10, RunData.battle_balance_logs.size())
	for index in range(limit):
		var entry: Dictionary = RunData.battle_balance_logs[index]
		var relic_names: Array[String] = []
		for relic_name in entry.get("relics", []):
			relic_names.append(str(relic_name))
		var encounter_kind: String = "BATTLE_LOG_BOSS" if bool(entry.get("boss", false)) else "BATTLE_LOG_ELITE" if bool(entry.get("elite", false)) else "BATTLE_LOG_NORMAL"
		history_text += tr("BATTLE_LOG_HISTORY_ROW") % [int(entry.get("battle_number", 0)), tr(encounter_kind), str(entry.get("result", "?")), str(entry.get("encounter", "?")), int(entry.get("turns", 0)), int(entry.get("cards_played", 0)), int(entry.get("damage_taken", 0)), ", ".join(PackedStringArray(relic_names)), str(entry.get("seed", "?"))]
	if history_text.is_empty():
		history_text = tr("BATTLE_LOG_HISTORY_EMPTY")
	_battle_log_label.text = current_text + "\n\n" + tr("BATTLE_LOG_HISTORY_HEADER") + "\n" + history_text

func record_battle_balance_result(result: String) -> void:
	# 勝敗が確定した瞬間の値を保存する。報酬処理の再入場でも二重記録しない。
	if _battle_log_recorded:
		return
	_battle_log_recorded = true
	var encounter_text: String = ", ".join(PackedStringArray(_battle_log_encounter_names))
	var relic_names: Array[String] = []
	for relic in RunData.relics:
		relic_names.append(relic.name)
	var entry := {
		"result": result,
		"encounter": encounter_text,
		"turns": _battle_log_turns,
		"cards_played": _battle_log_cards_played,
		"damage_taken": _battle_log_damage_taken,
		"seed": RunData.run_seed,
		"battle_number": RunData.completed_battles + (1 if not RunData.current_battle_is_boss else 0),
		"elite": RunData.current_battle_is_elite,
		"boss": RunData.current_battle_is_boss,
		"relics": relic_names,
	}
	RunData.record_battle_balance_log(entry)
	_refresh_battle_log_text()

func _play_relic_activation(icon: Control) -> void:
	# 効果発動時の短い点滅を共通化し、他のレリック効果でも使えるようにする。
	var tween := create_tween()
	tween.tween_property(icon, "modulate", Color(1.0, 0.82, 0.35), 0.12)
	tween.tween_property(icon, "modulate", Color.WHITE, 0.12)
	tween.tween_property(icon, "modulate", Color(1.0, 0.82, 0.35), 0.12)
	tween.tween_property(icon, "modulate", Color.WHITE, 0.18)

func _refresh_item_ui() -> void:
	if not is_instance_valid(_item_toggle):
		return
	_item_toggle.text = tr("BATTLE_ITEMS") % [RunData.items.size(), RunData.ITEM_CAPACITY]
	for child in _item_list.get_children():
		child.queue_free()
	var items: Array[ItemData] = RunData.get_items()
	for index in range(items.size()):
		var item: ItemData = items[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(320, 48)
		button.text = "%s — %s" % [item.name, item.description]
		button.pressed.connect(_use_item.bind(index))
		_item_list.add_child(button)
	if items.is_empty():
		var empty_label := Label.new()
		empty_label.text = tr("BATTLE_ITEMS_EMPTY")
		_item_list.add_child(empty_label)

func _toggle_item_panel() -> void:
	if $StateMachine.current_state.name != "ActionSelection":
		return
	_item_panel.visible = not _item_panel.visible

func _use_item(index: int) -> void:
	# 選択中にターンが切り替わった場合や二重押しでも消費しないよう、使用直前に再確認する。
	if $StateMachine.current_state.name != "ActionSelection":
		return
	var items: Array[ItemData] = RunData.get_items()
	if index < 0 or index >= items.size():
		return
	var item: ItemData = items[index]
	for action in item.actions:
		_apply_item_action(action)
	RunData.consume_item(index)
	_item_panel.visible = false
	_refresh_item_ui()
	# 爆弾などで最後の敵を倒した場合も、カード使用後と同じ勝利判定へ進める。
	$StateMachine.current_state.transitioned.emit("CheckVictoryOrDefeat")

func _apply_item_action(action: BattleAciton) -> void:
	var amount: int = action.get_value().execute_battle_action(_player)
	match action.get_type():
		BattleAciton.ActionType.HEAL:
			_player.heal(amount)
		BattleAciton.ActionType.SHIELD:
			_player.add_shield(amount)
		BattleAciton.ActionType.DRAW:
			for _draw_index in range(maxi(0, amount)):
				_hands._draw_card()
		BattleAciton.ActionType.POISON:
			# アイテムの毒効果もカードと同じターン処理に乗せる。
			var poison_targets: Array[BattleStatus] = []
			match action.get_target():
				BattleAciton.ActionTarget.ALL_ENEMIES:
					for enemy in _enemies:
						if not enemy.is_dead():
							poison_targets.append(enemy.get_status())
				BattleAciton.ActionTarget.RANDOM_ENEMY:
					var alive_for_poison: Array[BattleEnemy] = []
					for enemy in _enemies:
						if not enemy.is_dead():
							alive_for_poison.append(enemy)
					if not alive_for_poison.is_empty():
						var random_target: BattleEnemy = Random.get_instance().pick_array_item(alive_for_poison) as BattleEnemy
						poison_targets.append(random_target.get_status())
				BattleAciton.ActionTarget.SELF, BattleAciton.ActionTarget.ALL_ALLIES:
					poison_targets.append(_player)
				_:
					for enemy in _enemies:
						if not enemy.is_dead():
							poison_targets.append(enemy.get_status())
			for target_status in poison_targets:
				target_status.add_timed_status_effect(BattleStatusEffect.StatusEffectType.POISONED, amount, action.get_turns())
		BattleAciton.ActionType.DAMAGE:
			var damage_amount: int = amount
			if action.get_value()._type == BattleAcitonValue.ValueType.FIXED:
				damage_amount += _player.get_attack_bonus()
			var damage_targets: Array[BattleEnemy] = []
			match action.get_target():
				BattleAciton.ActionTarget.ALL_ENEMIES:
					for enemy in _enemies:
						if not enemy.is_dead():
							damage_targets.append(enemy)
				BattleAciton.ActionTarget.RANDOM_ENEMY:
					var alive: Array[BattleEnemy] = []
					for enemy in _enemies:
						if not enemy.is_dead():
							alive.append(enemy)
					if not alive.is_empty():
						damage_targets.append(Random.get_instance().pick_array_item(alive))
				_:
					for enemy in _enemies:
						if not enemy.is_dead():
							damage_targets.append(enemy)
			for enemy in damage_targets:
				if not enemy.damage(damage_amount):
					enemy.get_status().add_status_effects(BattleStatusEffect.new(BattleStatusEffect.StatusEffectType.DEAD, 0))
					ScreenEffect.play_fadeout(enemy)
				enemy.shake()
				ScreenEffect.play_flash(enemy, Color.RED)

func _unhandled_key_input(event: InputEvent) -> void:
	# 山札確認中のEscapeは一覧だけを閉じ、戦闘の入力へ流さない。
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and is_instance_valid(_pile_inspector_layer) and _pile_inspector_layer.visible:
		_close_pile_inspector()
		get_viewport().set_input_as_handled()
		return
	# Ctrl+Shift+K はエディタ標準ショートカットと重ならない戦闘テスト用コマンド。
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode != KEY_K or not event.ctrl_pressed or not event.shift_pressed or event.alt_pressed or event.meta_pressed or _debug_force_victory_requested:
		return
	if get_node_or_null("JourneyScreen") != null:
		return
	for child in get_children():
		if child is BattleRewardPopup:
			return
	_debug_force_victory_requested = true
	for enemy in _enemies:
		if not enemy.is_dead():
			# HPを0にするだけでは敵の死亡フラグが付かないため、通常攻撃と同じ状態効果を付ける。
			enemy.get_status().apply_damage(enemy.get_status().get_max_health() + enemy.get_status().get_shield() + 1)
			enemy.get_status().add_status_effects(BattleStatusEffect.new(BattleStatusEffect.StatusEffectType.DEAD, 0))
	# 勝利判定・勝利メッセージ・報酬表示は通常のFSM経路を通し、進行度を一度だけ更新する。
	$StateMachine.current_state.transitioned.emit("CheckVictoryOrDefeat")
	get_viewport().set_input_as_handled()

func _update_card_pile_num():
	$HUD/Sprite2D_Card/Label_CardNum.text = str(_card_pile.size())
	if is_instance_valid(_deck_pile_button):
		_deck_pile_button.tooltip_text = tr("BATTLE_DRAW_PILE_LABEL") % _card_pile.size()
	
func _update_discard_pile_num():
	$HUD/Sprite2D_Discard/Label_CardNum.text = str(_discard_pile.size())
	if is_instance_valid(_discard_pile_button):
		_discard_pile_button.tooltip_text = tr("BATTLE_DISCARD_PILE_LABEL") % _discard_pile.size()

func _build_card_pile_inspector() -> void:
	# 既存の山札・捨て札アイコン自体をクリックできるよう、透明な当たり判定を重ねる。
	_deck_pile_button = _make_pile_button(Control.PRESET_BOTTOM_LEFT, Vector2(0, -128), Vector2(96, -4))
	_deck_pile_button.tooltip_text = tr("BATTLE_DRAW_PILE_LABEL") % _card_pile.size()
	_deck_pile_button.pressed.connect(_show_draw_pile)
	$HUD.add_child(_deck_pile_button)
	_discard_pile_button = _make_pile_button(Control.PRESET_BOTTOM_RIGHT, Vector2(-96, -128), Vector2(0, -4))
	_discard_pile_button.tooltip_text = tr("BATTLE_DISCARD_PILE_LABEL") % _discard_pile.size()
	_discard_pile_button.pressed.connect(_show_discard_pile)
	$HUD.add_child(_discard_pile_button)

	# 戦闘HUDより手前に暗幕と一覧を重ね、一覧の外を押しても閉じられるようにする。
	_pile_inspector_layer = CanvasLayer.new()
	_pile_inspector_layer.layer = 30
	_pile_inspector_layer.visible = false
	add_child(_pile_inspector_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.04, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.gui_input.connect(_on_pile_inspector_shade_input)
	_pile_inspector_layer.add_child(shade)
	var panel := PanelContainer.new()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	panel.size = Vector2(minf(1080.0, viewport_size.x - 48.0), minf(620.0, viewport_size.y - 48.0))
	panel.position = (viewport_size - panel.size) / 2.0
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.055, 0.075, 0.11, 0.99)
	frame.border_color = Color(0.62, 0.72, 0.78, 0.95)
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(12)
	frame.content_margin_left = 18
	frame.content_margin_top = 14
	frame.content_margin_right = 18
	frame.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", frame)
	shade.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)
	var heading := HBoxContainer.new()
	layout.add_child(heading)
	_pile_inspector_title = Label.new()
	_pile_inspector_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pile_inspector_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pile_inspector_title.add_theme_font_size_override("font_size", 24)
	heading.add_child(_pile_inspector_title)
	var close_button := Button.new()
	close_button.text = tr("BATTLE_PILE_CLOSE")
	close_button.pressed.connect(_close_pile_inspector)
	heading.add_child(close_button)
	_pile_inspector_view = CardChoiceView.new()
	_pile_inspector_view.card_scene = CARD_SCENE
	_pile_inspector_view.show_panel_background = false
	_pile_inspector_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pile_inspector_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_pile_inspector_view)

func _make_pile_button(preset: int, top_left: Vector2, bottom_right: Vector2) -> Button:
	var button := Button.new()
	button.set_anchors_and_offsets_preset(preset)
	button.offset_left = top_left.x
	button.offset_top = top_left.y
	button.offset_right = bottom_right.x
	button.offset_bottom = bottom_right.y
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = ""
	# 透明の当たり判定にして既存アイコンと枚数表示の見た目を変えない。
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	return button

func _show_draw_pile() -> void:
	_show_pile_inspector(_card_pile, "BATTLE_DRAW_PILE_LABEL")

func _show_discard_pile() -> void:
	_show_pile_inspector(_discard_pile, "BATTLE_DISCARD_PILE_LABEL")

func _show_pile_inspector(cards: Array[CardData], title_key: String) -> void:
	_pile_inspector_title.text = tr(title_key) % cards.size()
	_pile_inspector_view.set_cards(cards, false, true)
	_pile_inspector_layer.visible = true

func _close_pile_inspector() -> void:
	if is_instance_valid(_pile_inspector_layer):
		_pile_inspector_layer.visible = false

func _on_pile_inspector_shade_input(event: InputEvent) -> void:
	# 枠外クリックで閉じる。枠内のクリックは子コントロールが受け取る。
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_pile_inspector()

func finish_reward_selection() -> void:
	# 報酬を終えたら、次の進路／休憩／カード強化の選択へ移る。
	var journey_screen := JourneyScreen.new()
	journey_screen.name = "JourneyScreen"
	journey_screen.show_campaign_clear = RunData.boss_defeated
	if journey_map_background != null:
		journey_screen.map_background_texture = journey_map_background
	journey_screen.route_selected.connect(_on_journey_route_selected)
	journey_screen.event_selected.connect(_on_journey_event_selected)
	journey_screen.relic_selected.connect(_on_journey_relic_selected)
	journey_screen.shop_relic_purchased.connect(_on_shop_relic_purchased)
	journey_screen.job_change_selected.connect(_on_journey_job_change_selected)
	journey_screen.card_upgrade_requested.connect(_on_card_upgrade_requested)
	journey_screen.new_run_requested.connect(_on_new_run_requested)
	add_child(journey_screen)
	_refresh_relic_row()

func _on_card_upgrade_requested(index: int, upgraded_card: CardData) -> void:
	# RunDataが保持するデッキの該当1枚だけを差し替え、以降の戦闘にも反映させる。
	RunData.upgrade_card(index, upgraded_card)

func _on_journey_route_selected(node_id: String, node_type: String, amount: int) -> void:
	# 選択地点を履歴に記録。休憩・宝箱はマップに戻り、戦闘地点だけ戦闘を開始する。
	RunData.move_to_route_node(node_id)
	match node_type:
		"rest":
			RunData.heal(amount, _player.get_max_health())
			$JourneyScreen.refresh_map()
			return
		"treasure":
			# レリック選択画面からはamount=0で到達する。従来の宝箱ゴールドは廃止。
			$JourneyScreen.refresh_map()
			return
		"upgrade":
			$JourneyScreen.refresh_map()
			return
		"event_training":
			$JourneyScreen.refresh_map()
			return
		"event_forge":
			# 鍛冶イベントは選択後に結果を反映済み。マップへ戻って次の道を選べるようにする。
			$JourneyScreen.refresh_map()
			return
		"shop":
			$JourneyScreen.refresh_map()
			return
		"job_change":
			# 転職を断った場合もマスは通過し、職業とデッキはそのままにする。
			$JourneyScreen.refresh_map()
			return
		"battle", "elite", "boss":
			RunData.next_battle_is_boss = node_type == "boss"
			RunData.next_battle_is_elite = node_type == "elite"
			# Autoloadの遷移演出はシーン再読込後も残り、戦闘種別ごとのタイトルを表示する。
			SceneTransition.transition_to_battle(BATTLE_SCENE_PATH, node_type)

func _on_journey_event_selected(node_id: String, health_delta: int, gold_delta: int) -> void:
	# 支払い可能性を再確認し、イベント効果と現在地を同時に確定する。
	if gold_delta < 0 and RunData.gold < -gold_delta:
		return
	RunData.move_to_route_node(node_id)
	# リスク型イベントではHPを失う選択肢もあるため、増減どちらも上限付きで反映する。
	RunData.set_health(RunData.current_health + health_delta, _player.get_max_health())
	if gold_delta < 0:
		RunData.spend_gold(-gold_delta)
	else:
		RunData.add_gold(gold_delta)
	$JourneyScreen.refresh_map()

func _on_journey_relic_selected(node_id: String, relic: RelicData) -> void:
	if RunData.add_relic(relic):
		RunData.move_to_route_node(node_id)
		_refresh_relic_row()

func _on_journey_job_change_selected(node_id: String, target_job: String, reward_card: CardData) -> void:
	# 転職できた場合だけ報酬を加え、受取をスキップした場合は職業変更だけを確定する。
	if not RunData.change_job(target_job):
		push_warning("Could not change job to: %s" % target_job)
		return
	RunData.move_to_route_node(node_id)
	if reward_card != null:
		RunData.add_card(reward_card)
	$JourneyScreen.refresh_map()

func _on_shop_relic_purchased(_relic: RelicData) -> void:
	# ショップ購入は現在地を動かさず、レリック欄だけをすぐ更新する。
	_refresh_relic_row()

func _on_new_run_requested() -> void:
	RunData.reset_run()
	# クリア後の新しい旅は開始画面へ戻し、職業と出発地点を選び直せるようにする。
	get_tree().change_scene_to_file("res://scene/scene/ui/run_start_screen.tscn")
