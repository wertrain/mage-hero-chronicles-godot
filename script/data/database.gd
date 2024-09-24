class_name DataBase
extends Node

var _cards: Array
var _card_dictionary: Dictionary
var _enemys: Array
var _enemy_dictionary: Dictionary

func _load_data(file_path):
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		return data
	push_error("not found: %s" % file_path)
	return null

func load_cards() -> Array:
	var card_data = _load_data("res://data/cards.json") as Dictionary
	if card_data != null:
		for c in card_data["lines"]:
			var card:CardData = CardData.new()
			card.id = int(c["id"])
			card.name = c["name"]
			card.description = c["description"]
			card.detail_description = c["description"]
			card.cost = int(c["cost"])
			for a in c["actions"]:
				var action:BattleAciton = BattleAciton.new()
				action.set_action_type(a["type"])
				action.set_target_type(a["target"])
				action._value = int(a["value"])
				action._turns = int(a["turns"])
				action.set_effect_type(a["effect_type"])
				action._effect_index = int(a["effect_index"])
				card.actions.append(action)
			_card_dictionary[c["guid"]] = card
			_cards.append(card)
		return _cards
	return Array()

func load_deck() -> Array:
	var deck_data = _load_data("res://data/deck.json") as Dictionary
	if deck_data != null:
		var deck = Array()
		for c in deck_data["cards"]:
			deck.append(_card_dictionary[c["card"]])
		return deck
	return Array()

func load_enemy() -> Array:
	var enemy_data = _load_data("res://data/enemy.json") as Dictionary
	if enemy_data != null:
		for e in enemy_data["lines"]:
			var enemy: EnemyData = EnemyData.new()
			enemy.id = int(e["id"])
			enemy.name = e["name"]
			enemy.health = int(e["health"])
			enemy.attack = e["attack"]
			_enemy_dictionary[enemy.name] = enemy
			_enemys.append(enemy)
		return _enemys
	return Array()
