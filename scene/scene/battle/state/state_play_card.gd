class_name PlayCard
extends State

func enter_with_params(params: Dictionary):
	var card: Card = params["card"]
	var card_data:CardData = card.get_data()
	var root: BattleScene = get_tree().current_scene
	var enemy = root.get_enemy()
	enemy.shake()
	ScreenEffect.play_flash(enemy, Color.RED)
	for a in card_data.actions:
		var action: BattleAciton = a
		if action._type == BattleAciton.ActionType.DAMAGE:
			enemy.damage(action._value)
		root.get_effect_spawner().spawn(action._effect_type, action._effect_index, enemy.position)
	await get_tree().create_timer(1).timeout
	transitioned.emit("ActionSelection")
