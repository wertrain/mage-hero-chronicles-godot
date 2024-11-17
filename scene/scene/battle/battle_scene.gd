class_name BattleScene
extends SceneBase

## 戦闘シーン
##
## 戦闘に関わるすべての要素はここでインスタンス化する
## シーケンス自体は StateMachine で管理する

@export var enemy_scene: PackedScene
@export var hands_scene: PackedScene
@export var action_message_window: PackedScene
@export var target_selection_arrow: PackedScene

var _battle_info: BattleInfo
var _enemy: BattleEnemy
var _enemies: Array[BattleEnemy] = []
var _card_pile: Array[CardData]  = []
var _discard_pile: Array[CardData]  = []
var _hands: Hands
var _player: BattlePlayerStatus
var _camera: Camera2D
var _target_selection_arrow: BezierArrow

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
	
func set_monsters() -> void:
	# モンスター間の間隔（スペース）
	const spacing = 0.0  # 任意の間隔、必要に応じて調整
	# モンスターを生成して追加
	var total_width = 0.0
	# 余白分を考慮して画像サイズを半分で計算
	const width_scale = 0.5
	# モンスターを3体（または複数）生成
	for i in range(3):  # ここでは3体のモンスターを例にします
		var enemy = enemy_scene.instantiate()
		var enemy_width = enemy.get_sprite_rect().size.x * width_scale
		total_width += enemy_width
		_enemies.append(enemy)
	# モンスター間の間隔を合計幅に加算
	total_width += spacing * (_enemies.size() - 1)
	# 画面サイズの取得
	var viewport_rect = get_viewport().size
	# モンスター群の幅を画面中央に配置
	var start_x = (viewport_rect.x - total_width) / 2  # 中央から開始位置を計算
	var current_x = start_x
	# 各モンスターを配置
	for enemy in _enemies:
		var enemy_width = enemy.get_sprite_rect().size.x * width_scale
		var enemy_height = enemy.get_sprite_rect().size.y		
		# モンスターの中心を基準として配置
		enemy.position.x = current_x + enemy_width / 2  # 左側から中央基準に調整
		enemy.position.y = viewport_rect.y / 2.0 - enemy_height / 2.0
		current_x += enemy_width + spacing
		$Background.add_sibling(enemy)
	_enemy = _enemies[0]

func _ready() -> void:
	var my_seed = "Godot Rocks"	
	Random.get_instance().set_seed(my_seed.hash())
	$DebugDraw.current_seed = my_seed.hash()
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_camera)
	#_enemy = enemy_scene.instantiate()
	#var viewport_rect = get_viewport().size
	#_enemy.position.x = viewport_rect.x / 2.0
	#_enemy.position.y = viewport_rect.y / 2.0 - _enemy.get_sprite_rect().size.y / 2.0
	#_enemies.append(_enemy)
	set_monsters()
	# カードのロードとデッキ作成
	var database = DataBase.new()
	var _cards_origin = database.load_cards()
	_card_pile = database.load_deck()
	var enemies_data = database.load_enemy()
	for enemy in _enemies:
		enemy.set_data(enemies_data[0])
	Random.get_instance().shuffle_array(_card_pile)
	# プレイヤーの作成
	_player = BattlePlayerStatus.new()
	_player.energy_changed.connect(_on_energy_changed)
	_player.health_changed.connect(_on_player_health_changed)
	_player.shield_changed.connect(_on_player_shield_changed)
	_player.status_effects_changed.connect(_on_player_status_effects_changed)
	_player.shield_reset.connect(_on_player_shield_reset)
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
	_hands.card_returned_to_deck.connect(_on_card_returned_to_deck)
	$Background.add_sibling(_hands)
	$HUD/Button_EndTurn.pressed.connect(_on_endturn_button_down)
	#$BattlePlayerStatus.setup(_player)
	_update_card_pile_num()
	_update_discard_pile_num()
	_target_selection_arrow = target_selection_arrow.instantiate()
	add_child(_target_selection_arrow)
	$StateMachine.current_state.transitioned.emit("BattleStart")
	_battle_info = BattleInfo.new()
	_battle_info._enemies = _enemies
	_battle_info._player = _player

func _on_endturn_button_down():
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
	pass
	
func _on_card_discarded(_card_data: CardData):
	_update_discard_pile_num()
	
func _on_card_returned_to_deck(_card_data: CardData):
	_update_card_pile_num()

func _on_player_health_changed(health: int, max_health: int):
	$HealthBar.set_health(health, max_health)

func _on_player_shield_changed(shield: int):
	$HealthBar.set_shield(shield)

func _on_player_status_effects_changed(status_effects: Array[BattleStatusEffect]):
	$HealthBar.set_shield(status_effects)

func _on_player_shield_reset():
	$HealthBar.set_shield(0)

func _on_energy_changed(energy: int, max_energy:int):
	$HUD.update_energy(energy, max_energy)
	ScreenEffect.play_pulse($HUD/Node2D_Energy)

func _process(_delta: float) -> void:
	pass

func _update_card_pile_num():
	$HUD/Sprite2D_Card/Label_CardNum.text = str(_card_pile.size())
	
func _update_discard_pile_num():
	$HUD/Sprite2D_Discard/Label_CardNum.text = str(_discard_pile.size())
