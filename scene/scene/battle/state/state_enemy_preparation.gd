class_name EnemyPreparation
extends State

var _action_counters: Dictionary = {}
var _battle_info: BattleInfo

var _icon_table: Dictionary = {
	EnemyBattleAciton.ActionType.ATTACK: AttackWarningIcon.Icons.ATTACK,
	EnemyBattleAciton.ActionType.SHIELD: AttackWarningIcon.Icons.SHIELD,
	EnemyBattleAciton.ActionType.BUFF: AttackWarningIcon.Icons.SPECIAL,
	EnemyBattleAciton.ActionType.DEBUFF: AttackWarningIcon.Icons.SPECIAL,
	EnemyBattleAciton.ActionType.MULTI_TURN_ACTION: AttackWarningIcon.Icons.CRITICAL,
	EnemyBattleAciton.ActionType.ATTACK_UP: AttackWarningIcon.Icons.ITEM,
	EnemyBattleAciton.ActionType.ATTACK_DOWN: AttackWarningIcon.Icons.BOOK,
	EnemyBattleAciton.ActionType.UNDEFINED: AttackWarningIcon.Icons.CRITICAL,
}

func enter():
	var root: BattleScene = get_tree().current_scene
	var enemies = root.get_enemies()
	_battle_info = root.get_battle_info()
	for enemy in enemies:
		var data: EnemyData = enemy.get_data()
		execute_enemy_action(enemy, data, _battle_info)
		var first_action: EnemyBattleAcitonBase = enemy._action_queue.front()
		enemy.show_warning_icon(_icon_table[first_action._type], first_action._value.execute_battle_action(enemy.get_status()))

func update(_delta: float):
	transitioned.emit("ActionSelection")

# 敵の行動を処理する関数
func execute_enemy_action(enemy: BattleEnemy, enemy_data: EnemyData, battle_info: BattleInfo):
	var actions = enemy_data.actions
	Random.get_instance().shuffle_array(actions)
	for index in range(actions.size()):
		var action = actions[index]
		# すでに limit に達している場合はスキップ
		if action._limit > 0 and _action_counters[action] >= action._limit:
			continue
		var probability = Random.get_instance().randi_range(0, 100) # ランダムな値（0-100）を生成
		# 確率をすり抜けて、すべてのアクションが実行されない場合、最後のアクションを実行するようにしておく
		# @todo この判定については検討の余地があるので、のちに変更したい
		# 例えば、actions を _frequency でソートしたうえで一番確率の高いアクションを実行する
		# または、action の定義に default かどうかを持たせて、それを選択するようにする
		if probability <= action._frequency or actions.size() - 1 == index:
			if not action._conditions.is_empty():
				if not _check_condition(action._conditions, enemy, battle_info):
					continue  # 条件を満たしていない場合はスキップ
			# 実行すべきアクションが決まった
			# まだアクションが残っている場合、プライオリティをチェックして
			# 今回のアクションのプライオリティのほうが上ならば現在のキューは捨てる
			if not enemy.get_action_queue().is_empty():
				if action.get_priority() > enemy.get_action_queue().front().get_priority():
					enemy.get_action_queue().clear()
				else:
					# 優先度は高くないので、既に積まれているアクションを使用する
					var next_action = enemy.get_action_queue().front()
					_debug_dump_action(next_action)
					# アクションの実行回数をカウントする
					if not _action_counters.has(next_action):
						_action_counters[next_action] = 0
					_action_counters[next_action] += 1
					return
			# アクションを保存
			# 複数ターンのアクションであればステップすべてを登録してしまう
			if action.get_action_type() == EnemyBattleAciton.ActionType.MULTI_TURN_ACTION:
				enemy.get_action_queue().append_array(action._steps)
			else:
				enemy.get_action_queue().push_back(action)
			_debug_dump_action(action)
			# アクションの実行回数をカウントする
			if not _action_counters.has(action):
				_action_counters[action] = 0
			_action_counters[action] += 1
			break  # 一度アクションが実行されたらループを終了

# 条件をチェックする関数
func _check_condition(conditions: Array[EnemyBattleAcitonCondition], enemy: BattleEnemy, battle_info: BattleInfo) -> bool:
	if conditions.is_empty():
		return true
	# 条件が複数設定されている場合は AND で判定
	for condition in conditions:
		var value = _evaluate_expression(condition._expression)
		match condition._type:
			EnemyBattleAcitonCondition.ConditionType.HP_BELOW:
				if (float(enemy.get_status().get_health()) / float(enemy.get_status().get_max_health())) * 100.0 < value:
					return false
			EnemyBattleAcitonCondition.ConditionType.TURN_NUMBER:
				if not (battle_info.get_turn_number() == value):
					return false
	return true

# 数式を評価する関数
func _evaluate_expression(expression: String) -> float:
	var expr = Expression.new()
	var error = expr.parse(expression, [])
	if error != OK:
		push_error("Failed: evaluate expression")
		return 0.0
	var result = expr.execute([], null)
	return result if result != null else 0.0

# 特定の enum 値を文字列で取得
func get_enum_name(value: int, enum_dict: Dictionary) -> String:
	for key in enum_dict.keys():
		if enum_dict[key] == value:
			return key
	return "UNKNOWN"

func _debug_dump_action(action: EnemyBattleAcitonBase):
	print("<DUMP> Enemy action")
	print("       Name: %s" % action._name)
	print("     Target: %s" % get_enum_name(action._target, EnemyBattleAciton.ActionTarget))
	print("       Type: %s" % get_enum_name(action._type, EnemyBattleAciton.ActionType))
	print("      Value: [%s] %s" % [get_enum_name(action._value._type, BattleAcitonValue.ValueType), action._value._expression])
