class_name CardDataBase
extends Node

var _cards: Array
var _card_dictionary: Dictionary
var _deck: Array

func _load_card_data(file_path):
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		return data
	push_error("not found: %s" % file_path)
	return null

func load_cards():
	var card_data = _load_card_data("res://data/cards.json") as Dictionary
	if card_data != null:
		for c in card_data["lines"]:
			var card:CardData = CardData.new()
			card.id = int(c["id"])
			card.name = c["name"]
			card.description = c["description"]
			card.detail_description = c["description"]
			card.cost = int(c["cost"])
			_card_dictionary[c["guid"]] = card
			_cards.append(card)
		return _cards
	return null

func load_deck():
	var deck_data = _load_card_data("res://data/deck.json") as Dictionary
	if deck_data != null:
		for c in deck_data["cards"]:
			_deck.append(_card_dictionary[c["card"]])
		return _deck
	return null
