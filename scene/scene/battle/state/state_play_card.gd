class_name PlayCard
extends State

func enter_with_params(params: Dictionary):
	var card: Card = params["card"]
	var card_data:CardData = card.get_data()
	var root: BattleScene = get_tree().current_scene
	var player_status: BattlePlayerStatus = root.get_player()
	var enemy: BattleEnemy = params["enemy"]
	var hands: Hands = root.get_hands()
	# ここでカードを使用する
	# 条件判定によって失敗する可能性のある実装なので強制的にカードを使わせたほうがよいかも
	hands.use_active_card()
	for a in card_data.actions:
		var action: BattleAciton = a
		if action.get_type() == BattleAciton.ActionType.DAMAGE:
			if false == enemy.damage(action.get_value().execute_battle_action(player_status)):
				enemy.get_status().add_status_effects(BattleStatusEffect.new(BattleStatusEffect.StatusEffectType.DEAD, 0))
				ScreenEffect.play_fadeout(enemy)
			# Play Effect
			root.get_effect_spawner().spawn(action._effect_type, action._effect_index, enemy.position)
			enemy.shake()
			ScreenEffect.play_flash(enemy, Color.RED)
		if action.get_type() == BattleAciton.ActionType.SHIELD:
			player_status.add_shield(action.get_value().execute_battle_action(player_status))
	await get_tree().create_timer(1).timeout
	transitioned.emit("CheckVictoryOrDefeat")
