class_name ScreenEffect
extends Object

static var _active_fadeout_twists: Dictionary = {}
static var _active_pulse_twists: Dictionary = {}
static var _active_shake_twists: Dictionary = {}
static var _active_flash_twists: Dictionary = {}

static func play_fadeout(target: Node2D, duration: float = 0.5):
	if (_active_fadeout_twists.has(target)):
		return;
	var tween: Tween = target.get_tree().create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(target, "modulate:a", 0, duration)
	_active_fadeout_twists[target] = tween
	await tween.finished
	_active_fadeout_twists.erase(target)

static func play_pulse(target: Node2D):
	if (_active_pulse_twists.has(target)):
		return;
	var tween: Tween = target.get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	var default_scale = target.scale
	var animation_time = 0.1
	tween.tween_property(target, "scale", default_scale * 1.3, animation_time)
	tween.tween_property(target, "scale", default_scale * 0.8, animation_time)
	tween.tween_property(target, "scale", default_scale * 1.0, animation_time)
	tween.play()
	_active_pulse_twists[target] = tween
	await tween.finished
	_active_pulse_twists.erase(target)
	
static func play_shake(target: Node2D, duration: float = 0.5, magnitude: float = 10.0):
	if (_active_shake_twists.has(target)):
		return;
	var tween: Tween = target.get_tree().create_tween()
	var original_position: Vector2 = target.position
	var shake_time = 0.05  # シェイクの頻度
	var shake_count = int(duration / shake_time)
	_active_shake_twists[target] = tween
	for i in range(shake_count):
		# ランダムなオフセットを生成
		var random_offset = Vector2(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude)
		)
		# 位置をランダムにシェイク
		tween.tween_property(target, "position", original_position + random_offset, shake_time)
	# 最後に元の位置に戻す
	tween.tween_property(target, "position", original_position, shake_time)
	await tween.finished
	_active_shake_twists.erase(target)

# フラッシュを実行する関数
static func play_flash(target: Node2D, color: Color, duration: float = 0.2):
	if (_active_flash_twists.has(target)):
		return;
	var tween: Tween = target.get_tree().create_tween()
	var default_color: Color
	var property_name: String
	# プロパティ名を判断し、デフォルトの色を取得
	if "modulate" in target:
		property_name = "modulate"
		default_color = target.modulate
		target.modulate = color  # フラッシュカラーを設定
	elif "color" in target:
		property_name = "color"
		default_color = target.color
		target.color = color  # フラッシュカラーを設定
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(target, property_name, color, duration)
	tween.tween_property(target, property_name, default_color, duration)
	await tween.finished
	_active_flash_twists.erase(target)

# フラッシュを実行する関数
static func play_flash_screen(
	scene: Node, color: Color, duration: float = 0.1, 
	count: int = 1, min_interval:float = 0.05, max_interval: float = 0.15):
	if (_active_flash_twists.has(scene)):
		return;		
	var flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = color
	flash_rect.modulate.a = 0  # 最初は透明
	scene.get_tree().current_scene.add_child(flash_rect)
	var max_a: float = 0.7
	var tween: Tween = scene.get_tree().create_tween()
	for i in range(count):
		var delay_time = randf_range(min_interval, max_interval) * i
		tween.tween_property(flash_rect, "modulate:a", max_a, duration).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(flash_rect, "modulate:a",     0, duration).set_trans(Tween.TRANS_LINEAR).set_delay(delay_time)
	await tween.finished	
	_active_flash_twists.erase(scene)
	scene.get_tree().current_scene.remove_child(flash_rect)
	flash_rect.queue_free()
