class_name GameOver
extends State

func enter() -> void:
	var root: BattleScene = get_tree().current_scene
	root.trigger_relic_hook(RunData.RelicHook.BATTLE_DEFEAT, {"player": root.get_player()})
	# 敗北を知らせ、入力待ちの案内を画面上に残す。
	var retry_message := tr("BATTLE_DEFEAT_RETRY")
	await root.get_sequence_message().show_message(retry_message)
	var label := Label.new()
	label.text = retry_message
	label.position = Vector2(0, 310)
	label.size = Vector2(1280, 60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	root.add_child(label)

func input(event) -> void:
	if event.is_action_pressed("ui_accept"):
		# 現在のランは終了扱いにして、初期デッキから再挑戦する。
		RunData.reset_run()
		get_tree().reload_current_scene()
