class_name PlayCard
extends State

func enter_with_params(_params: Dictionary):
	#var card: Card = params["card"]
	#var card_data:CardData = card.get_data()
	var root: BattleScene = get_tree().current_scene
	var enemy = root.get_enemy()
	enemy.shake()
	ScreenEffect.play_flash(enemy, Color.RED)
	enemy.damage(5)
	await get_tree().create_timer(1).timeout
	transitioned.emit("ActionSelection")
