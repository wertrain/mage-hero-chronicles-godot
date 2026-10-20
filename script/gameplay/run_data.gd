extends Node

## イベントの流れを確認するための一時プリセット。
## 通常の戦闘密度へ戻す時はfalseにする。シード抽選と地図の再現性はどちらでも保つ。
const EVENT_HEAVY_ROUTE_OPTIONS := [
	[["event_herbalist"], ["event_caravan", "event_forge"], ["event_shrine", "event_herbalist"]],
	[["event_shrine"], ["event_caravan", "event_forge"], ["event_herbalist", "event_caravan"]],
	[["event_forge"], ["event_shrine", "event_caravan"], ["event_herbalist", "event_shrine"]],
]
## 開始エリアの雰囲気を残しながら、イベント中心の入口ルートを抽選する。
const EVENT_HEAVY_STARTING_VARIANTS := {
	"road": [["event_caravan", "event_herbalist"], ["event_forge", "event_caravan"], ["event_shrine", "event_caravan"]],
	"forest": [["event_herbalist", "event_forge"], ["event_herbalist", "event_caravan"], ["event_caravan", "event_herbalist"]],
	"ruins": [["event_shrine", "event_forge"], ["event_shrine", "event_caravan"], ["event_forge", "event_shrine"]],
}
const EVENT_HEAVY_EVENT_TYPES := ["event_herbalist", "event_shrine", "event_caravan", "event_forge"]
## 初回マップに並べる入口。候補の種類に難易度差は付けず、入口ごとに道筋を抽選する。
const STARTING_POSITION_IDS := ["far_left", "left", "right", "far_right"]

## 区間ごとのイベントルート候補。ランシードから候補を選び、ラン中はその結果を保持する。
## 各候補は順番に通るノードで、戦闘ルートとは別の道としてJourneyScreenに配置する。
const ROUTE_SEGMENT_OPTIONS := [
	[["event_herbalist"], ["event_herbalist", "upgrade"], ["rest", "treasure"], ["event_shrine", "upgrade", "treasure"]],
	[["treasure"], ["event_shrine", "treasure"], ["event_caravan", "upgrade"], ["rest", "shop", "upgrade"], ["event_forge"]],
	[["rest"], ["rest", "event_caravan"], ["upgrade", "rest"], ["event_shrine", "shop", "event_caravan"], ["event_forge", "rest"]],
]
## マップの難しさと寄り道量を調整する設定。
## ボス前ノード数は0にもでき、0なら最後の通常戦からそのままボスへ進む。
const ROUTE_GENERATION_CONFIG := {
	"event_heavy_mode": false,
	"normal_route_segment_count": 3,
	# 各合流区間を縦に何段の選択肢で構成するか。段を増やすほど冒険が長くなる。
	"route_rows_per_segment": 4,
	# 各段のマス数2〜5の重み。横長マップの空白を減らすため、通常は4〜5個にする。
	"route_node_count_weights": [0, 0, 1, 4],
	# 1段ごとに作る横方向の寄り道数。増やすと選択肢が増えるが道も混み合う。
	"route_lateral_branch_min_count": 1,
	"route_lateral_branch_max_count": 2,
	# 区間末に枝をまとめる確率。0ならボスまで枝を保ち、1なら従来どおり必ず合流する。
	"route_segment_merge_chance": 0.45,
	# 合流を行う時に作る合流地点数の重み。配列は2、3、4地点の順。
	# 2地点への急な縮小を避け、合流後も広い選択肢を保つ。
	"route_merge_group_count_weights": [0, 1, 4],
	# 柔軟な区間の非戦闘レーン候補。種類を絞ると報酬や回復の密度を調整できる。
	"flexible_safe_route_types": ["rest", "treasure", "upgrade", "shop"],
	# 休憩地点は回復と強化を選べるため、以前より控えめに出して他の安全ルートも残す。
	"flexible_safe_route_weights": [1, 2, 2, 1],
	# 通常イベントの一部を、旅の途中で転職を申し出る稀なイベントに置き換える。
	"rare_job_change_event_chance": 0.05,
	# 下のweights配列は、各候補の出やすさを上から順に指定する。
	# 候補を足したときは対応する重みも足す。重みは相対値なので合計は任意。
	"segment_option_weights": [[3, 2, 2, 1], [3, 2, 2, 1, 1], [3, 2, 2, 1, 1]],
	"event_heavy_segment_option_weights": [[3, 2, 1], [3, 2, 2], [3, 2, 1]],
	"starting_route_variant_weights": {
		"road": [3, 2, 1, 1],
		"forest": [3, 2, 1, 1],
		"ruins": [3, 2, 1, 1, 1],
	},
	"event_heavy_starting_variant_weights": {
		"road": [3, 2, 1],
		"forest": [3, 2, 1],
		"ruins": [3, 2, 1],
	},
	"event_heavy_event_weights": [3, 3, 3, 1],
	# エリート戦は中盤以降の安全な分岐スロットに配置する。
	# min/maxを変えると難易度に応じて出現数を調整でき、0なら出現しない。
	"elite_min_count": 1,
	"elite_max_count": 2,
	"elite_candidate_segments": [1, 2],
	"boss_preparation_min": 2,
	"boss_preparation_max": 4,
	"boss_preparation_types": ["rest", "treasure", "event_caravan", "upgrade", "shop"],
	"boss_preparation_weights": [2, 2, 2, 1, 1],
}
## ポーションの所持枠。ここを変えると戦闘UIと報酬側の上限表示も追従する。
const ITEM_CAPACITY := 3
## 職業特性の調整値。実際の戦闘処理は下の取得関数を通して参照する。
const DEFAULT_MAX_ENERGY := 3
const MAGE_MAX_ENERGY_BONUS := 1
const WARRIOR_BATTLE_VICTORY_HEAL := 5
## 冒険開始時に選べる入口。各入口は初戦後に見える最初のイベント区間の傾向を決める。
const STARTING_ROUTE_SEGMENTS := {
	"road": ["rest", "treasure"],
	"forest": ["event_herbalist", "upgrade"],
	"ruins": ["event_shrine", "upgrade", "treasure"],
}
## 開始エリアごとの特色を残しつつ、同じエリアでも複数の構成からシードで選ぶ。
## 各エリアの候補数や内容を変えると、探索の傾向をバランス調整できる。
const STARTING_ROUTE_VARIANTS := {
	"road": [["rest", "treasure"], ["rest", "event_caravan"], ["treasure", "rest"], ["shop", "rest"]],
	"forest": [["event_herbalist", "upgrade"], ["event_herbalist", "rest"], ["upgrade", "event_caravan"], ["job_change", "event_herbalist"]],
	"ruins": [["event_shrine", "upgrade", "treasure"], ["treasure", "event_shrine"], ["upgrade", "treasure", "event_caravan"], ["shop", "event_shrine"], ["job_change", "upgrade"]],
}
## 転職前後の組み合わせごとに報酬カードを割り当てる。将来の上級職もここへ追加できる。
const JOB_CHANGE_REWARD_GUIDS := {
	"warrior>mage": "2b1d2638-2d9c-5b34-bb46-3673c087c524",
}
## レリックの効果判定が起きる場面。効果本体から分けて、イベントの入口をここへ集約する。
enum RelicHook {
	BATTLE_START_AFTER_DRAW,
	PLAYER_TURN_START,
	CARD_PLAYED,
	ENEMY_DEFEATED,
	BATTLE_VICTORY,
	BATTLE_DEFEAT,
	TREASURE_OPENED,
	ROUTE_NODE_SELECTED,
}

signal relic_hook_triggered(hook: RelicHook, context: Dictionary)
# シーンをまたぐラン中だけの状態を保持する Autoload。
# 戦闘シーンを再読み込みしても、HP・デッキ・進行度はここに残る。
var deck: Array[CardData] = []
## ItemDataをラン中に保持し、戦闘シーンを読み直しても所持品を引き継ぐ。
var items: Array[ItemData] = []
## ラン中のパッシブ効果を保持するレリック。戦闘シーンを越えて維持する。
var relics: Array[RelicData] = []
var _starter_deck: Array[CardData] = []
var gold: int = 0
## 職業は報酬カードの抽選先を決める。転職後も所持デッキのカードはそのまま残す。
var current_job: String = "warrior"
## 開始画面で選んだ職業。BattleSceneを直接起動した場合は既定の戦士になる。
var requested_start_job: String = "warrior"
## 開始画面で選んだ冒険エリア。初戦後の最初のルート区間に反映する。
var starting_route_id: String = "road"
## 全体マップ上で選んだ開始レーン。初戦後もマップの開始位置として使う。
var starting_position_id: String = "left"
var current_health: int = 100
var completed_battles: int = 0
var next_battle_is_boss: bool = false
var current_battle_is_boss: bool = false
var next_battle_is_elite: bool = false
var current_battle_is_elite: bool = false
var boss_defeated: bool = false
## 全体マップ上の現在地と通過した道。シーンを読み直してもルート選択を維持する。
var current_route_node_id: String = "new_run"
var route_history: Array[String] = ["new_run"]
## ラン固有のシード。マップの再現とデバッグ表示に使う。
var run_seed: int = 0
## シードから生成したイベントルート。シーン再読込では再生成せず同じマップを表示する。
var route_segments: Array = []
## 初回の各開始レーンに置くマス。イベント多めプリセットではイベントに置き換える。
var starting_lane_encounter_types: Array[String] = []
## 中盤以降の各区間にエリート戦を置くか。選ばれたマスは任意の戦闘分岐になる。
var route_segment_has_elite: Array[bool] = []
## ボス直前の準備マスだけは、種類と個数を専用設定からシード抽選する。
var boss_preparation_types: Array[String] = []
var _initialized: bool = false
var _seed_override_enabled: bool = false

func trigger_relic_hook(hook: RelicHook, context: Dictionary = {}) -> void:
	# 呼び出し元は「何が起きたか」だけを通知し、効果処理とイベント時点を分離する。
	relic_hook_triggered.emit(hook, context)

func get_relic_hook_name(hook: int) -> String:
	# JSONに書いた小文字のタイミング名を、列挙値から共通の形式で取得する。
	return RelicHook.keys()[hook].to_lower()

func get_normal_battle_count() -> int:
	# 分岐の戦闘マスをすべて通った場合の最大値を進行表示に出す。
	var event_heavy_mode: bool = bool(ROUTE_GENERATION_CONFIG["event_heavy_mode"])
	var route_options: Array = EVENT_HEAVY_ROUTE_OPTIONS if event_heavy_mode else ROUTE_SEGMENT_OPTIONS
	var segment_count: int = clampi(int(ROUTE_GENERATION_CONFIG["normal_route_segment_count"]), 1, route_options.size())
	var row_count: int = clampi(int(ROUTE_GENERATION_CONFIG["route_rows_per_segment"]), 2, 8)
	var flexible_battle_count: int = maxi(0, segment_count - 1) * row_count
	# 通常設定では開始地点直後の戦闘道も最大1戦ぶん加える。イベント多め設定ではそこもイベント。
	return segment_count + 2 + flexible_battle_count if event_heavy_mode else segment_count + 4 + flexible_battle_count

func _generate_run_seed() -> int:
	var seed_rng := RandomNumberGenerator.new()
	seed_rng.randomize()
	return seed_rng.randi()

func _pick_weighted_index(map_rng: RandomNumberGenerator, weights: Array) -> int:
	# 重み付き抽選を共通化し、出現率の調整を設定値だけで行えるようにする。
	if weights.is_empty():
		return 0
	var total_weight := 0
	for weight in weights:
		total_weight += maxi(0, int(weight))
	if total_weight <= 0:
		return map_rng.randi_range(0, weights.size() - 1)
	var ticket: int = map_rng.randi_range(1, total_weight)
	for index in range(weights.size()):
		ticket -= maxi(0, int(weights[index]))
		if ticket <= 0:
			return index
	return weights.size() - 1

func _pick_event_heavy_type(map_rng: RandomNumberGenerator) -> String:
	# イベント枠の中身もマップ専用乱数から決め、同一シードで同じ物語に出会えるようにする。
	var weights: Array = ROUTE_GENERATION_CONFIG["event_heavy_event_weights"]
	var event_index: int = _pick_weighted_index(map_rng, weights)
	return str(EVENT_HEAVY_EVENT_TYPES[mini(event_index, EVENT_HEAVY_EVENT_TYPES.size() - 1)])

func _generate_route_segments() -> void:
	# マップ専用の乱数器を使い、戦闘中に乱数を何回使っても地図が変わらないようにする。
	var map_rng := RandomNumberGenerator.new()
	map_rng.seed = run_seed
	var event_heavy_mode: bool = bool(ROUTE_GENERATION_CONFIG["event_heavy_mode"])
	var route_options: Array = EVENT_HEAVY_ROUTE_OPTIONS if event_heavy_mode else ROUTE_SEGMENT_OPTIONS
	route_segments.clear()
	var segment_count: int = clampi(int(ROUTE_GENERATION_CONFIG["normal_route_segment_count"]), 1, route_options.size())
	for segment_index in range(segment_count):
		var options: Array = route_options[segment_index]
		var weights_key: String = "event_heavy_segment_option_weights" if event_heavy_mode else "segment_option_weights"
		var segment_weights: Array = ROUTE_GENERATION_CONFIG[weights_key][segment_index]
		var option_index: int = _pick_weighted_index(map_rng, segment_weights)
		route_segments.append(options[option_index].duplicate())
	# 選んだエリアの特色を保ちながら、同じエリアにも複数の道筋を用意する。
	var starting_variants_by_area: Dictionary = EVENT_HEAVY_STARTING_VARIANTS if event_heavy_mode else STARTING_ROUTE_VARIANTS
	var starting_variants: Array = starting_variants_by_area.get(starting_route_id, [])
	if not route_segments.is_empty() and not starting_variants.is_empty():
		var starting_weights_key: String = "event_heavy_starting_variant_weights" if event_heavy_mode else "starting_route_variant_weights"
		var starting_weights: Array = ROUTE_GENERATION_CONFIG[starting_weights_key].get(starting_route_id, [])
		# 開始エリアの特色は候補内容に反映し、行の数・配置・接続は全区間で共通にする。
		var starting_variant_index: int = _pick_weighted_index(map_rng, starting_weights)
		route_segments[0] = starting_variants[starting_variant_index].duplicate()
	# 固定戦闘枠をイベントに置き換えるプリセットでは、全入口と後続区間にイベント内容を割り当てる。
	starting_lane_encounter_types.clear()
	for _lane_index in range(STARTING_POSITION_IDS.size()):
		starting_lane_encounter_types.append(_pick_event_heavy_type(map_rng) if event_heavy_mode else "battle")
	# エリート候補区間をシードで並べ替え、設定範囲の数だけ重複なしで採用する。
	# マスの列や道の接続は固定レイアウトを使うため、抽選しても道同士は干渉しない。
	route_segment_has_elite.clear()
	for _segment_index in range(segment_count):
		route_segment_has_elite.append(false)
	var elite_candidates: Array[int] = []
	for candidate_value in ROUTE_GENERATION_CONFIG["elite_candidate_segments"]:
		var candidate_index: int = int(candidate_value)
		if candidate_index > 0 and candidate_index < segment_count and not elite_candidates.has(candidate_index):
			elite_candidates.append(candidate_index)
	for index in range(elite_candidates.size() - 1, 0, -1):
		var swap_index: int = map_rng.randi_range(0, index)
		var temporary_index: int = elite_candidates[index]
		elite_candidates[index] = elite_candidates[swap_index]
		elite_candidates[swap_index] = temporary_index
	var min_elite_count: int = 0 if event_heavy_mode else clampi(int(ROUTE_GENERATION_CONFIG["elite_min_count"]), 0, elite_candidates.size())
	var max_elite_count: int = 0 if event_heavy_mode else clampi(int(ROUTE_GENERATION_CONFIG["elite_max_count"]), min_elite_count, elite_candidates.size())
	var elite_count: int = map_rng.randi_range(min_elite_count, max_elite_count)
	for index in range(elite_count):
		route_segment_has_elite[elite_candidates[index]] = true
	# ボス前は毎回5択に固定せず、設定範囲内の数と候補をシードで決める。
	boss_preparation_types.clear()
	var available_boss_types: Array = ROUTE_GENERATION_CONFIG["boss_preparation_types"].duplicate()
	var min_boss_nodes: int = mini(int(ROUTE_GENERATION_CONFIG["boss_preparation_min"]), available_boss_types.size())
	var max_boss_nodes: int = mini(int(ROUTE_GENERATION_CONFIG["boss_preparation_max"]), available_boss_types.size())
	var boss_node_count: int = map_rng.randi_range(min_boss_nodes, maxi(min_boss_nodes, max_boss_nodes))
	var available_boss_weights: Array = ROUTE_GENERATION_CONFIG["boss_preparation_weights"].duplicate()
	# 候補から重複なしで引き、同じシードなら候補の種類と順番も一致させる。
	for _index in range(boss_node_count):
		var choice_index: int = _pick_weighted_index(map_rng, available_boss_weights)
		boss_preparation_types.append(str(available_boss_types[choice_index]))
		available_boss_types.remove_at(choice_index)
		available_boss_weights.remove_at(choice_index)

func prepare_new_run(job: String, route_id: String) -> void:
	# 新規ラン開始画面から呼ぶ。戦闘シーン側の初期化で選択内容を取り込む。
	requested_start_job = job if job in ["warrior", "mage"] else "warrior"
	starting_route_id = route_id if STARTING_ROUTE_SEGMENTS.has(route_id) else "road"
	starting_position_id = "left"
	_initialized = false
	_seed_override_enabled = false

func choose_starting_position(position_id: String) -> void:
	# 初戦前マップで選んだ左右・中央の位置を記録し、以降の分岐にも反映する。
	if position_id not in STARTING_POSITION_IDS:
		return
	starting_position_id = position_id

func set_run_seed(seed_value: int) -> void:
	# 固定値を指定するとマップと戦闘乱数を含むラン全体を再現できる。
	_seed_override_enabled = true
	_apply_run_seed(seed_value)

func _apply_run_seed(seed_value: int) -> void:
	run_seed = seed_value
	_generate_route_segments()
	Random.get_instance().set_seed(run_seed)
	ScreenEffect.set_seed(run_seed)

func initialize(starter_deck: Array[CardData]) -> void:
	# BattleScene は戦闘のたびに作り直されるため、初回だけ初期デッキを取り込む。
	if _initialized:
		return
	_starter_deck = starter_deck.duplicate()
	if not _seed_override_enabled:
		_apply_run_seed(_generate_run_seed())
	deck = starter_deck.duplicate()
	items.clear()
	relics.clear()
	current_health = 100
	gold = 0
	current_job = requested_start_job
	completed_battles = 0
	next_battle_is_boss = false
	current_battle_is_boss = false
	next_battle_is_elite = false
	current_battle_is_elite = false
	boss_defeated = false
	current_route_node_id = "new_run"
	route_history = ["new_run"]
	_initialized = true

func move_to_route_node(node_id: String) -> void:
	# マップ側で到達可能性を確認済みのノードだけ呼ぶ。履歴は線の強調表示に使う。
	current_route_node_id = node_id
	if route_history.is_empty() or route_history.back() != node_id:
		route_history.append(node_id)

func get_deck() -> Array[CardData]:
	# 配列自体を複製し、呼び出し元がデッキの並びを直接変えないようにする。
	return deck.duplicate()

func add_card(card: CardData) -> void:
	if card != null:
		deck.append(card)

func change_job(job: String) -> bool:
	# カードが登録されている職業だけを許可し、職業追加時に判定コードを増やさずに済むようにする。
	if job.is_empty() or job == current_job:
		return false
	var database := DataBase.new()
	if database.load_cards_for_job(job).is_empty():
		return false
	current_job = job
	return true

func get_job_change_reward_guid(target_job: String) -> String:
	# 現在の職業から転職先へ移る組み合わせに紐づく報酬カードを返す。
	return str(JOB_CHANGE_REWARD_GUIDS.get("%s>%s" % [current_job, target_job], ""))

func get_max_energy() -> int:
	# 魔法使いは職業特性で毎ターン使える最大エナジーが1増える。
	return DEFAULT_MAX_ENERGY + MAGE_MAX_ENERGY_BONUS if current_job == "mage" else DEFAULT_MAX_ENERGY

func get_job_victory_heal() -> int:
	# 戦士は戦闘に勝つたび少量回復し、長い冒険を粘り強く進められる。
	return WARRIOR_BATTLE_VICTORY_HEAL if current_job == "warrior" else 0

func remove_card(index: int) -> bool:
	# 最後の1枚を残し、デッキ切れで戦闘できなくなるのを防ぐ。
	if index < 0 or index >= deck.size() or deck.size() <= 1:
		return false
	deck.remove_at(index)
	return true

func add_item(item: ItemData) -> bool:
	# 所持枠に空きがあるときだけ報酬アイテムを受け取る。
	if item == null or items.size() >= ITEM_CAPACITY:
		return false
	items.append(item)
	return true

func get_items() -> Array[ItemData]:
	return items.duplicate()

func consume_item(index: int) -> ItemData:
	# 効果を適用したアイテムだけを消費する。
	if index < 0 or index >= items.size():
		return null
	var item: ItemData = items[index]
	items.remove_at(index)
	return item

func add_relic(relic: RelicData) -> bool:
	# GUIDで重複を防ぐ。レリックの効果は1個の所持につき1回だけ適用する。
	if relic == null or relic.guid.is_empty() or has_relic(relic.guid):
		return false
	relics.append(relic)
	return true

func has_relic(guid: String) -> bool:
	for relic in relics:
		if relic.guid == guid:
			return true
	return false

func get_treasure_choice_count() -> int:
	# 通常は候補1つ。探検家の羅針盤などの効果で候補数を増やす。
	var count := 1
	for relic in relics:
		count += relic.treasure_choice_bonus
		for effect: Dictionary in relic.hook_effects:
			if effect.get("trigger") == "treasure_opened" and effect.get("type") == "extra_relic_choice":
				count += int(effect.get("amount", 0))
	return count

func get_battle_start_shield() -> int:
	var amount := 0
	for relic in relics:
		amount += relic.battle_start_shield
	return amount

func get_battle_victory_gold() -> int:
	var amount := 0
	for relic in relics:
		amount += relic.battle_victory_gold
		for effect: Dictionary in relic.hook_effects:
			if effect.get("trigger") == "battle_victory" and effect.get("type") == "bonus_gold":
				amount += int(effect.get("amount", 0))
	return amount

func upgrade_card(index: int, upgraded_card: CardData) -> bool:
	# UIから渡された強化版が、このカードの登録済み強化先かを確認してから置換する。
	if index < 0 or index >= deck.size() or upgraded_card == null:
		return false
	if deck[index].upgrade_guid.is_empty() or deck[index].upgrade_guid != upgraded_card.guid:
		return false
	deck[index] = upgraded_card
	return true

func add_gold(amount: int) -> void:
	gold += maxi(0, amount)

func spend_gold(amount: int) -> bool:
	# 支払い不可のまま所持金が負数にならないよう、残高を確認してから差し引く。
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	return true

func set_health(value: int, max_health: int = 100) -> void:
	current_health = clampi(value, 0, max_health)

func heal(amount: int, max_health: int = 100) -> void:
	set_health(current_health + maxi(0, amount), max_health)

func record_battle_victory() -> void:
	# 通常戦の数とボス撃破は別に記録し、ルート選択とクリア画面に使う。
	if current_battle_is_boss:
		boss_defeated = true
	else:
		# BattleSceneを直接実行するデバッグ経路は、初回マップを通らず中央レーンから続ける。
		if completed_battles == 0 and current_route_node_id == "new_run":
			current_route_node_id = "battle_1_left"
			route_history = ["battle_1_left"]
		completed_battles += 1

func reset_run() -> void:
	# 新しい旅・敗北後は、カード報酬や強化を含まない初期デッキに戻す。
	deck = _starter_deck.duplicate()
	items.clear()
	relics.clear()
	gold = 0
	current_job = "warrior"
	requested_start_job = "warrior"
	starting_route_id = "road"
	starting_position_id = "left"
	current_health = 100
	completed_battles = 0
	next_battle_is_boss = false
	current_battle_is_boss = false
	next_battle_is_elite = false
	current_battle_is_elite = false
	boss_defeated = false
	current_route_node_id = "new_run"
	route_history = ["new_run"]
	_initialized = false
	if not _seed_override_enabled:
		_apply_run_seed(_generate_run_seed())
	else:
		_apply_run_seed(run_seed)
