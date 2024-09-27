class_name PlayCard
extends State

func enter_with_params(params: Dictionary):
	var card: Card = params["card"]
	var card_data:CardData = card.get_data()
	var root: BattleScene = get_tree().current_scene
	var enemy = root.get_enemy()
	enemy.shake()
	ScreenEffect.play_flash(enemy, Color.RED)
	print(evaluate_expression("5 + 5"))
	for a in card_data.actions:
		var action: BattleAciton = a
		if action._type == BattleAciton.ActionType.DAMAGE:
			if false == enemy.damage(execute_card_action(action._value)):
				ScreenEffect.play_fadeout(enemy)
		root.get_effect_spawner().spawn(action._effect_type, action._effect_index, enemy.position)
	await get_tree().create_timer(1).timeout
	transitioned.emit("ActionSelection")

# カードアクションを処理する関数
func execute_card_action(battle_action_value: BattleAcitonValue) -> int:
	var result = 0
	if battle_action_value._type == BattleAcitonValue.ValueType.FIXED:
		result = float(battle_action_value._expression)
	elif battle_action_value._type == BattleAcitonValue.ValueType.CALCULATION:
		var expression = battle_action_value._expression
		# ステータスを数式に置換
		expression = expression.replace("current_shield", str(5))
		result = evaluate_expression(expression)
	return result

# 数式を評価する関数
func evaluate_expression(expression: String) -> float:
	var expr = Expression.new()
	var error = expr.parse(expression, [])
	if error != OK:
		push_error("Failed: evaluate expression")
		return 0.0
	var result = expr.execute([], null)
	return result if result != null else 0.0
	
