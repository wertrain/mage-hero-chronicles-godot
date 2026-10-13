class_name CheckVictoryOrDefeat
extends State

var isMessageShown: bool
var _result: String

func enter():
	var root: BattleScene = get_tree().current_scene
	isMessageShown = false
	# 1体でも生存していれば戦闘続行。全員倒れた場合だけ勝利報酬へ進む。
	var has_living_enemy := false
	for enemy in root.get_enemies():
		if not enemy.is_dead():
			has_living_enemy = true
			break
	_result = "BATTLE_VICTORY" if not has_living_enemy else ""
	if not _result.is_empty():
		# ここで進行度を更新するので、報酬後に開くJourneyScreenが次の行き先を表示できる。
		RunData.record_battle_victory()
		await root.get_sequence_message().show_message(tr(_result))
		var reward_scene: PackedScene = preload("res://scene/scene/battle/ui/battle_reward_popup.tscn")
		var reward: BattleRewardPopup = reward_scene.instantiate()
		reward.reward_completed.connect(root.finish_reward_selection)
		root.add_child(reward)
	else:
		isMessageShown = true
	isMessageShown = true

func update(_delta: float):
	if isMessageShown and _result.is_empty():
		transitioned.emit("ActionSelection")
