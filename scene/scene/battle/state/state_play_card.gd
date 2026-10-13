class_name PlayCard
extends State

func enter_with_params(params: Dictionary):
	var card: Card = params["card"]
	var card_data:CardData = card.get_data()
	var root: BattleScene = get_tree().current_scene
	var player_status: BattlePlayerStatus = root.get_player()
	var enemy: BattleEnemy = params["enemy"]
	var enemies: Array[BattleEnemy] = root.get_enemies()
	var hands: Hands = root.get_hands()
	# カードを先に手札から消費し、その後に定義された効果を順番に解決する。
	# 条件判定によって失敗する可能性のある実装なので強制的にカードを使わせたほうがよいかも
	hands.use_active_card()
	for a in card_data.actions:
		var action: BattleAciton = a
		if action.get_type() == BattleAciton.ActionType.DAMAGE:
			var targets: Array[BattleEnemy] = []
			# 単体攻撃は選択対象、全体攻撃は生存中の全員、ランダム攻撃は生存者から選ぶ。
			match action.get_target():
				BattleAciton.ActionTarget.ALL_ENEMIES:
					for target in enemies:
						if not target.is_dead():
							targets.append(target)
				BattleAciton.ActionTarget.RANDOM_ENEMY:
					var alive: Array[BattleEnemy] = []
					for target in enemies:
						if not target.is_dead():
							alive.append(target)
					if not alive.is_empty():
						targets.append(alive.pick_random())
				_:
					if not enemy.is_dead():
						targets.append(enemy)
			for target in targets:
				# HPが尽きた敵には死亡状態と退場演出を付け、以後の対象選択から除外する。
				if false == target.damage(action.get_value().execute_battle_action(player_status)):
					target.get_status().add_status_effects(BattleStatusEffect.new(BattleStatusEffect.StatusEffectType.DEAD, 0))
					ScreenEffect.play_fadeout(target)
				root.get_effect_spawner().spawn(action._effect_type, action._effect_index, target.position)
				target.shake()
				ScreenEffect.play_flash(target, Color.RED)
		if action.get_type() == BattleAciton.ActionType.SHIELD:
			player_status.add_shield(action.get_value().execute_battle_action(player_status))
		if action.get_type() == BattleAciton.ActionType.HEAL:
			player_status.heal(action.get_value().execute_battle_action(player_status))
	await get_tree().create_timer(1).timeout
	transitioned.emit("CheckVictoryOrDefeat")
