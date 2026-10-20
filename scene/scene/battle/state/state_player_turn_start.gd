class_name PlayerTurnStart
extends State

var _can_continue_turn: bool = true
var _turn_blocked: bool = false

func enter():
	_can_continue_turn = true
	_turn_blocked = false
	var root: BattleScene = get_tree().current_scene
	root.get_sequence_message().show_message("Player's Turn")
	var player_status: BattlePlayerStatus = root.get_player()
	# 毒・火傷をプレイヤーターン開始時に処理し、倒れた場合はドローへ進めない。
	player_status.begin_turn()
	player_status.reset_shield()
	RunData.trigger_relic_hook(RunData.RelicHook.PLAYER_TURN_START, {"player": player_status})
	_can_continue_turn = player_status.apply_turn_start_effects()
	if _can_continue_turn:
		player_status.reset_energy()
		_turn_blocked = player_status.consume_turn_blocker()

func update(_delta):
	if _can_continue_turn:
		if _turn_blocked:
			# 行動不能でもターン終了処理を通し、手札と持続効果を通常どおり進める。
			transitioned.emit("PlayerTurnEnd")
		else:
			transitioned.emit("DrawPhase")
	else:
		transitioned.emit("GameOver")
