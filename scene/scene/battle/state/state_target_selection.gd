class_name TargetSelection
extends State

## ターゲット選択ステート

var _card: Card
var _target_index: int = 0
var _enemies: Array[BattleEnemy]
var _current_select_enemy: BattleEnemy
var _target_selection_arrow: BezierArrow
var _enabled_input: bool = false

func enter_with_params(params: Dictionary):
	var card: Card = params["card"]
	var card_data:CardData = card.get_data()
	var root: BattleScene = get_tree().current_scene
	var player_status: BattlePlayerStatus = root.get_player()
	_card = card
	_enemies = root.get_enemies()	
	_enabled_input = false
	# 敵の選択は省略できる？
	var action: BattleAciton = card.get_data().actions.front()
	if (_get_alive_enemy_num() == 1 or action.get_target() != BattleAciton.ActionTarget.ENEMY):
		_to_next_state(_get_next_target_index(0))
		return
	_enabled_input = true
	_target_selection_arrow = root.get_target_selection_arrow()	
	_target_selection_arrow.start(card.position)	
	_target_index = _get_next_target_index(0)
	_current_select_enemy = _enemies[_target_index]
	_target_selection_arrow.set_end_point(Vector2(_current_select_enemy.position.x, 
		(_current_select_enemy.position.y + _current_select_enemy.get_sprite_rect().size.y / 2)))
	_current_select_enemy.set_visible_outline(true)

func exit() -> void:
	if _target_selection_arrow:
		_target_selection_arrow.set_active(false)
	for enemy in _enemies:
		enemy.set_visible_outline(false)
	
func update(_delta):
	pass

func input(event):
	if (!_enabled_input):
		return
	# アクションタイプの入力判定
	if event.is_action_type() and event.is_pressed():
		if event.is_action("ui_left"):
			_target_index = _target_index - 1
			if _target_index < 0:
				_target_index = _enemies.size() - 1		    
			while _enemies[_target_index].is_dead():
				_target_index -= 1
				if _target_index < 0:
					_target_index = _enemies.size() - 1  # 最後の敵に戻る
			_select_enemy(_target_index)
		elif event.is_action("ui_right"):
			_target_index = _target_index + 1
			if _target_index > _enemies.size() - 1:
				_target_index = 0			
			while _enemies[_target_index].is_dead():
				_target_index += 1
				if _target_index > _enemies.size() - 1:
					_target_index = 0  # 最初の敵に戻る
			_select_enemy(_target_index)
		elif event.is_action("ui_accept"):
			_to_next_state(_target_index)
		elif event.is_action("ui_cancel"):
			transitioned.emit("ActionSelection")
	# マウスの入力判定
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			transitioned.emit("ActionSelection")
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			for index in range(_enemies.size()):
				var enemy_sprite = _enemies[index].get_sprite()
				if enemy_sprite.get_rect().has_point(enemy_sprite.to_local(event.position)) and _is_mouse_in_sprite_opaque(enemy_sprite, event.position):
					if (_target_index == index):
						_to_next_state(_target_index)
					else:
						_select_enemy(index)
					break

func _select_enemy(index: int):
	_target_index = index
	_current_select_enemy.set_visible_outline(false)
	_current_select_enemy = _enemies[index]
	_current_select_enemy.set_visible_outline(true)
	_target_selection_arrow.set_end_point(Vector2(_current_select_enemy.position.x, 
	(_current_select_enemy.position.y + _current_select_enemy.get_sprite_rect().size.y / 2)))

func _to_next_state(index: int):
	var params = {"card": _card, "index": index, "enemy": _enemies[index]}
	transitioned_with_param.emit("PlayCard", params)

## 不透明位置を判定
func _is_mouse_in_sprite_opaque(sprite: Sprite2D, mouse_position: Vector2):
	var transform_to_local = sprite.get_global_transform_with_canvas().affine_inverse()
	var sprite_local = transform_to_local * mouse_position
	return sprite.is_pixel_opaque(sprite_local)

func _get_next_target_index(start_index: int) -> int:
	for index in range(start_index, _enemies.size()):
		if (not _enemies[index].is_dead()):
			return index
	return -1

func _get_alive_enemy_num() -> int:
	var count = 0
	for enemy in _enemies:
		if (not enemy.is_dead()):
			count = count + 1
	return count
