class_name BattleScene
extends SceneBase
@export var monster_scene: PackedScene
@export var hands_scene: PackedScene

var _monster: Monster
var _card_pile = Array()
var _discard_pile = Array()
var _hands: Hands

func get_monster():
	return _monster

func get_card_pile():
	return _card_pile

func get_discard_pile():
	return _discard_pile
	
func get_hands():
	return _hands

func _ready() -> void:
	var my_seed = "Godot Rocks"	
	Random.get_instance().set_seed(my_seed.hash())
	$DebugDraw.current_seed = my_seed.hash()
	
	_monster = monster_scene.instantiate()
	var viewport_rect = get_viewport().size
	_monster.position.x = viewport_rect.x / 2 - _monster.get_texture_rect().size.x
	_monster.position.y = viewport_rect.y / 2 - _monster.get_texture_rect().size.y
	# カードのロードとデッキ作成
	var card_database = CardDataBase.new()
	var cards_origin = card_database.load_cards()
	_card_pile = card_database.load_deck()
	Random.get_instance().shuffle_array(_card_pile)
	$Background.add_sibling(_monster)
	# 手札を作成
	_hands = hands_scene.instantiate()
	_hands.set_pile(_card_pile, _discard_pile)
	_hands.card_drawn.connect(_on_card_drawn)
	_hands.active_card_changed.connect(_on_active_card_changed)
	_hands.deck_reshuffled.connect(_on_deck_reshuffled)
	_hands.card_used.connect(_on_card_used)
	_hands.card_discarded.connect(_on_card_discarded)
	_hands.card_returned_to_deck.connect(_on_card_returned_to_deck)
	$Background.add_sibling(_hands)
	$StateMachine.current_state.transitioned.emit("InitialDrawPhase")
	_update_card_pile_num()
	_update_discard_pile_num()

func _on_card_drawn(_card_data: CardData):
	_update_card_pile_num()
	pass

func _on_active_card_changed(_card_data: CardData):
	pass

func _on_deck_reshuffled():
	_update_card_pile_num()
	_update_discard_pile_num()
	
func _on_card_used(_card_data: CardData):
	pass
	
func _on_card_discarded(_card_data: CardData):
	_update_discard_pile_num()
	
func _on_card_returned_to_deck(_card_data: CardData):
	_update_card_pile_num()
	
func _process(_delta: float) -> void:
	pass

func _update_card_pile_num():
	$HUD/Sprite2D_Card/Label_CardNum.text = str(_card_pile.size())
	
func _update_discard_pile_num():
	$HUD/Sprite2D_Discard/Label_CardNum.text = str(_discard_pile.size())
