class_name DrawPhase
extends State

var await_draw: bool 

func enter():
	var root: BattleScene = get_tree().current_scene
	var hands: Hands = root.get_hands()
	hands.set_input_enabled(false)
	await_draw = true
	await hands._first_draw(5)
	# 戦闘開始時効果は最初の手札を見せた直後に発動し、通常のターン開始処理から分離する。
	if root.get_player().get_turn_serial() == 1:
		root.trigger_relic_hook(RunData.RelicHook.BATTLE_START_AFTER_DRAW, {"player": root.get_player()})
	hands.set_input_enabled(true)
	await_draw = false

func update(_delta):
	if (not await_draw):
		transitioned.emit("EnemyPreparation")
