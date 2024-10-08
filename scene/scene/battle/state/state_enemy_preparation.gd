class_name EnemyPreparation
extends State

enum IconType {
	
}

var _action_counters: Dictionary = {}
var _battle_info: BattleInfo

func enter():
	var root: BattleScene = get_tree().current_scene
	var enemies = root.get_enemies()
	_battle_info = root.get_battle_info()
	for enemy in enemies:
		var data: EnemyData = enemy.get_data()
		execute_enemy_action(enemy, data, _battle_info)

func update(_delta: float):
	transitioned.emit("ActionSelection")

# 敵の行動を処理する関数
func execute_enemy_action(enemy: BattleEnemy, enemy_data: EnemyData, battle_info: BattleInfo):
	var actions = enemy_data.actions
	Random.get_instance().shuffle_array(actions)
	for action in actions:
		# アクションの実行回数をカウントする
		if not _action_counters.has(action):
			_action_counters[action] = 0
		# すでに limit に達している場合はスキップ
		if action._limit > 0 and _action_counters[action] >= action._limit:
			continue
		var probability = Random.get_instance().randi_range(0, 100) # ランダムな値（0-100）を生成
		if probability <= action._frequency:
			if not action._conditions.is_empty():
				if not _check_condition(action._conditions, enemy, battle_info):
					continue  # 条件を満たしていない場合はスキップ
			# アクションを保存
			_debug_dump_action(action)
			enemy._action_queue.push_back(action)
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

func _debug_dump_action(action: EnemyBattleAciton):
	print("<DUMP> Enemy action")
	print("       Name: %s" % action._name)
	print("     Target: %s" % action._target)
	print("       Type: %s" % action._type)
	print("      Value: %s" % action._value)
