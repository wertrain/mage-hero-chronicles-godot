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
	# 使用カードを手札から取り除いてから効果を解決し、追加ドロー時の配置競合を防ぐ。
	var card_was_consumed: bool = await hands.use_active_card()
	if not card_was_consumed:
		transitioned.emit("ActionSelection")
		return
	root.trigger_relic_hook(RunData.RelicHook.CARD_PLAYED, {"player": player_status, "card": card_data})
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
					var alive_for_damage: Array[BattleEnemy] = []
					for target in enemies:
						if not target.is_dead():
							alive_for_damage.append(target)
					if not alive_for_damage.is_empty():
						targets.append(Random.get_instance().pick_array_item(alive_for_damage))
				_:
					if not enemy.is_dead():
						targets.append(enemy)
			for target in targets:
				var damage: int = action.get_value().execute_battle_action(player_status)
				# 計算式攻撃はcurrent_attackで補正済みなので、固定ダメージにだけ強化／弱体を足す。
				if action.get_value()._type == BattleAcitonValue.ValueType.FIXED:
					damage += player_status.get_attack_bonus()
				# HPが尽きた敵には死亡状態と退場演出を付け、以後の対象選択から除外する。
				if false == target.damage(damage):
					target.get_status().add_status_effects(BattleStatusEffect.new(BattleStatusEffect.StatusEffectType.DEAD, 0))
					ScreenEffect.play_fadeout(target)
					root.trigger_relic_hook(RunData.RelicHook.ENEMY_DEFEATED, {"player": player_status, "enemy": target})
				root.get_effect_spawner().spawn(action._effect_type, action._effect_index, target.position)
				target.shake()
				ScreenEffect.play_flash(target, Color.RED)
		if action.get_type() == BattleAciton.ActionType.SHIELD:
			player_status.add_shield(action.get_value().execute_battle_action(player_status))
		if action.get_type() == BattleAciton.ActionType.HEAL:
			player_status.heal(action.get_value().execute_battle_action(player_status))
		if action.get_type() == BattleAciton.ActionType.DRAW:
			# ドロー枚数はカード定義の値を使い、山札が尽きた場合は捨て札から補充する。
			var draw_count: int = action.get_value().execute_battle_action(player_status)
			await hands.draw_cards(draw_count)
		if action.get_type() == BattleAciton.ActionType.POISON:
			# 毒カードは選択敵・全体・ランダムの指定に沿って、敵のターン開始時に働く効果を付ける。
			var poison_targets: Array[BattleStatus] = []
			match action.get_target():
				BattleAciton.ActionTarget.ALL_ENEMIES:
					for target in enemies:
						if not target.is_dead():
							poison_targets.append(target.get_status())
				BattleAciton.ActionTarget.RANDOM_ENEMY:
					var alive_for_poison: Array[BattleEnemy] = []
					for target in enemies:
						if not target.is_dead():
							alive_for_poison.append(target)
					if not alive_for_poison.is_empty():
						var random_target: BattleEnemy = Random.get_instance().pick_array_item(alive_for_poison) as BattleEnemy
						poison_targets.append(random_target.get_status())
				BattleAciton.ActionTarget.SELF, BattleAciton.ActionTarget.ALL_ALLIES:
					poison_targets.append(player_status)
				_:
					if is_instance_valid(enemy) and not enemy.is_dead():
						poison_targets.append(enemy.get_status())
			var poison_amount: int = action.get_value().execute_battle_action(player_status)
			for target_status in poison_targets:
				target_status.add_timed_status_effect(BattleStatusEffect.StatusEffectType.POISONED, poison_amount, action.get_turns())
		if action.get_type() == BattleAciton.ActionType.STATUS:
			# 状態効果もカードの対象指定に従い、単体・全体・ランダム・自分へ付与する。
			var status_targets: Array[BattleStatus] = []
			match action.get_target():
				BattleAciton.ActionTarget.SELF, BattleAciton.ActionTarget.ALL_ALLIES:
					status_targets.append(player_status)
				BattleAciton.ActionTarget.ALL_ENEMIES:
					for target in enemies:
						if not target.is_dead():
							status_targets.append(target.get_status())
				BattleAciton.ActionTarget.RANDOM_ENEMY:
					var living_targets: Array[BattleEnemy] = []
					for target in enemies:
						if not target.is_dead():
							living_targets.append(target)
					if not living_targets.is_empty():
						var random_target: BattleEnemy = Random.get_instance().pick_array_item(living_targets) as BattleEnemy
						status_targets.append(random_target.get_status())
				_:
					if is_instance_valid(enemy) and not enemy.is_dead():
						status_targets.append(enemy.get_status())
			var status_value: int = action.get_value().execute_battle_action(player_status)
			for target_status in status_targets:
				target_status.add_timed_status_effect(action.get_status_type(), status_value, action.get_turns())
	await get_tree().create_timer(1).timeout
	transitioned.emit("CheckVictoryOrDefeat")
