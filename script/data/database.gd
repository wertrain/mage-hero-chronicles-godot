# Json をパースして各データクラスとして取得
class_name DataBase
extends Node

var _cards: Array[CardData]
var _card_dictionary: Dictionary
var _enemys: Array[EnemyData]
var _enemy_dictionary: Dictionary

func _load_data(file_path):
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		return data
	push_error("not found: %s" % file_path)
	return null

func load_cards() -> Array[CardData]:
	var card_data = _load_data("res://data/card.json") as Dictionary
	if card_data != null:
		for c in card_data["lines"]:
			var card:CardData = CardData.new()
			card.id = int(c["id"])
			card.guid = c["guid"]
			card.job = str(c.get("job", "warrior"))
			# 元カードと強化カードは別定義。GUIDを使って強化先を引けるようにする。
			card.upgrade_guid = str(c.get("upgrade_guid", ""))
			card.name = tr(c["name"])
			card.description = tr(c["description"])
			card.detail_description = tr(c["detail_description"])
			card.cost = int(c["cost"])
			card.rarity = int(c["rarity"])
			for a in c["actions"]:
				var action:BattleAciton = BattleAciton.new()
				action.set_action_type(a["type"])
				action.set_target_type(a["target"])
				action._value = BattleAcitonValue.new(a["value"])
				action._turns = int(a["turns"])
				action.set_status_type(str(a.get("status_type", "poisoned")))
				action.set_effect_type(a["effect_type"])
				action._effect_index = int(a["effect_index"])
				card.actions.append(action)
			_card_dictionary[c["guid"]] = card
			_cards.append(card)
		return _cards
	return []

func load_cards_for_job(job: String) -> Array[CardData]:
	# 全カード定義は強化参照用にロードし、現在の職業に合うカードだけ報酬候補にする。
	var matching_cards: Array[CardData] = []
	for card in load_cards():
		if card.job == job:
			matching_cards.append(card)
	return matching_cards

func load_deck(job: String = "warrior") -> Array[CardData]:
	var deck_data = _load_data("res://data/deck.json") as Dictionary
	if deck_data != null:
		var deck: Array[CardData] = []
		for l in deck_data["lines"]:
			# 職業ごとの初期デッキを選択する。job未指定の古いデータは戦士として扱う。
			if str(l.get("job", "warrior")) != job:
				continue
			for c in l["cards"]:
				var card: CardData = _card_dictionary.get(c["card"]) as CardData
				if card != null:
					deck.append(card)
			if not deck.is_empty():
				return deck
		return deck
	return []

func get_card(guid: String) -> CardData:
	# load_cards() 後に使う。休憩所が参照する upgrade_guid から強化版を引く。
	return _card_dictionary.get(guid) as CardData

func load_enemy() -> Array:
	var enemy_data = _load_data("res://data/enemy.json") as Dictionary
	if enemy_data != null:
		for e in enemy_data["lines"]:
			var enemy: EnemyData = EnemyData.new()
			enemy.id = int(e["id"])
			enemy.name = tr(e["name"])
			enemy.health = int(e["health"])
			enemy.attack = e["attack"]
			var image_file: String = str(e.get("image", "")).replace("\\", "/").get_file()
			enemy.image_path = "res://art/enemy/" + image_file if not image_file.is_empty() else ""
			enemy.gold = e["gold"]
			for a in e["actions"]:
				var action:EnemyBattleAciton = EnemyBattleAciton.new()
				action._name = tr(a["name"])
				action.set_action_type(a["type"])
				action.set_target_type(a["target"])
				action._value = BattleAcitonValue.new(a["value"])
				action._frequency = float(a["frequency"])
				action.set_priority(int(a["priority"]))
				action.set_turns(int(a.get("turns", 0)))
				if false == a["conditions"].is_empty():
					for c in a["conditions"]:
						var condition = EnemyBattleAcitonCondition.new()
						condition.set_condition_type(c["type"])
						condition._expression = c["expression"]
						action._conditions.append(condition)
				if false == a["steps"].is_empty():
					for s in a["steps"]:
						var step = EnemyBattleAcitonStep.new()
						step._name = tr(s["name"])
						step.set_action_type(s["type"])
						step.set_target_type(s["target"])
						step._value = BattleAcitonValue.new(s["value"])
						step.set_priority(int(s["priority"]))
						step.set_turns(int(s.get("turns", 0)))
						action._steps.append(step)
				enemy.actions.append(action)
			_enemy_dictionary[enemy.name] = enemy
			_enemys.append(enemy)
		return _enemys
	return []

func load_items() -> Array[ItemData]:
	var item_data = _load_data("res://data/item.json") as Dictionary
	if item_data != null:
		var items: Array[ItemData] = []
		for i in item_data["lines"]:
			var item:ItemData = ItemData.new()
			item.id = int(i["id"])
			item.name = tr(i["name"])
			item.description = tr(i["description"])
			item.detail_description = tr(i["detail_description"])
			item.cost = int(i.get("cost", 0))
			item.rarity = int(i["rarity"])
			for a in i.get("actions", []):
				var action: BattleAciton = BattleAciton.new()
				action.set_action_type(a["type"])
				action.set_target_type(a["target"])
				action._value = BattleAcitonValue.new(a["value"])
				action._turns = int(a.get("turns", 0))
				action.set_effect_type(a.get("effect_type", "impact_a"))
				action._effect_index = int(a.get("effect_index", 0))
				item.actions.append(action)
			items.append(item)
		return items
	return []

func load_relics() -> Array[RelicData]:
	# レリック定義はJSONで管理し、効果値を追加してもロジックを散らさない。
	var relic_data := _load_data("res://data/relic.json") as Dictionary
	if relic_data == null:
		return []
	var relics: Array[RelicData] = []
	for entry in relic_data.get("lines", []):
		var relic := RelicData.new()
		relic.id = int(entry.get("id", 0))
		relic.guid = str(entry.get("guid", ""))
		relic.name = tr(str(entry.get("name", "")))
		relic.description = tr(str(entry.get("description", "")))
		relic.detail_description = tr(str(entry.get("detail_description", "")))
		relic.battle_start_shield = int(entry.get("battle_start_shield", 0))
		relic.battle_victory_gold = int(entry.get("battle_victory_gold", 0))
		relic.treasure_choice_bonus = int(entry.get("treasure_choice_bonus", 0))
		for effect in entry.get("hook_effects", []):
			relic.hook_effects.append(effect.duplicate(true))
		relics.append(relic)
	return relics
