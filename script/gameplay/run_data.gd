extends Node

# シーンをまたぐラン中だけの状態を保持する Autoload。
# 戦闘シーンを再読み込みしても、HP・デッキ・進行度はここに残る。
var deck: Array[CardData] = []
var _starter_deck: Array[CardData] = []
var gold: int = 0
var current_health: int = 100
var completed_battles: int = 0
var next_battle_is_boss: bool = false
var current_battle_is_boss: bool = false
var boss_defeated: bool = false
var _initialized: bool = false

func initialize(starter_deck: Array[CardData]) -> void:
	# BattleScene は戦闘のたびに作り直されるため、初回だけ初期デッキを取り込む。
	if _initialized:
		return
	_starter_deck = starter_deck.duplicate()
	deck = starter_deck.duplicate()
	current_health = 100
	gold = 0
	completed_battles = 0
	next_battle_is_boss = false
	current_battle_is_boss = false
	boss_defeated = false
	_initialized = true

func get_deck() -> Array[CardData]:
	# 配列自体を複製し、呼び出し元がデッキの並びを直接変えないようにする。
	return deck.duplicate()

func add_card(card: CardData) -> void:
	if card != null:
		deck.append(card)

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

func set_health(value: int, max_health: int = 100) -> void:
	current_health = clampi(value, 0, max_health)

func heal(amount: int, max_health: int = 100) -> void:
	set_health(current_health + maxi(0, amount), max_health)

func record_battle_victory() -> void:
	# 通常戦の数とボス撃破は別に記録し、ルート選択とクリア画面に使う。
	if current_battle_is_boss:
		boss_defeated = true
	else:
		completed_battles += 1

func reset_run() -> void:
	# 新しい旅・敗北後は、カード報酬や強化を含まない初期デッキに戻す。
	deck = _starter_deck.duplicate()
	gold = 0
	current_health = 100
	completed_battles = 0
	next_battle_is_boss = false
	current_battle_is_boss = false
	boss_defeated = false
