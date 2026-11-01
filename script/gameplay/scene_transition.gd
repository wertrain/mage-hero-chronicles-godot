extends CanvasLayer

## シーンをまたいでも残る、共通の画面遷移演出。
## 戦闘種別ごとの初期スタイルを持ちつつ、後から個別の色や時間を上書きできる。

## effect に指定できる遷移パターン。新しい演出を追加するときは
## _play_cover_effect() と _play_reveal_effect() に処理を追加する。
const EFFECT_FADE := "fade"
const EFFECT_CROSS_QUADRANT := "cross_quadrant"
const EFFECT_WINDMILL_QUADRANT := "windmill_quadrant"
const WINDMILL_WIPE_SHADER: Shader = preload("res://scene/common/scene_transition_windmill.gdshader")
const WINDMILL_FULL_PROGRESS := 1.02

const BATTLE_STYLES := {
	"battle": {
		"title_key": "BATTLE_TRANSITION_NORMAL_TITLE",
		"effect": EFFECT_CROSS_QUADRANT,
		"background_color": Color("#101a29"),
		"accent_color": Color("#9fc9ff"),
	},
	"elite": {
		"title_key": "BATTLE_TRANSITION_ELITE_TITLE",
		"effect": EFFECT_CROSS_QUADRANT,
		"background_color": Color("#29151b"),
		"accent_color": Color("#ff927c"),
	},
	"boss": {
		"title_key": "BATTLE_TRANSITION_BOSS_TITLE",
		"effect": EFFECT_CROSS_QUADRANT,
		"background_color": Color("#21172c"),
		"accent_color": Color("#ffd47f"),
	},
}

const DEFAULT_FADE_OUT_DURATION := 0.25
const DEFAULT_HOLD_DURATION := 0.35
const DEFAULT_FADE_IN_DURATION := 0.28
const DEFAULT_CROSS_DURATION := 0.24
const DEFAULT_QUADRANT_DURATION := 0.34
const CROSS_THICKNESS := 18.0

var _is_transitioning := false
var _transition_overlay: Control
var _backdrop: ColorRect
var _title_label: Label
var _accent_bar: ColorRect
var _cross_horizontal: ColorRect
var _cross_vertical: ColorRect
var _quadrant_panels: Array[ColorRect] = []
var _windmill_wipe: ColorRect
var _windmill_material: ShaderMaterial

func _ready() -> void:
	# シーンを切り替えている間も、演出側のTweenとタイマーを止めない。
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

func transition_to_battle(scene_path: String, battle_type: String = "battle", style_overrides: Dictionary = {}) -> void:
	# 通常戦・エリート・ボスで色とタイトルを分け、個別設定でさらに調整できるようにする。
	var style: Dictionary = BATTLE_STYLES.get(battle_type, BATTLE_STYLES["battle"]).duplicate(true)
	style.merge(style_overrides, true)
	var title_key: String = str(style.get("title_key", BATTLE_STYLES["battle"]["title_key"]))
	await transition_to_scene(
		scene_path,
		tr(title_key),
		style
	)

func transition_to_scene(scene_path: String, title: String, style: Dictionary = {}) -> void:
	# 汎用関数にして、将来はイベント・ボス登場・章移動にも同じ流れを使えるようにする。
	if _is_transitioning:
		return
	_is_transitioning = true
	var background_color: Color = style.get("background_color", Color("#101820"))
	var accent_color: Color = style.get("accent_color", Color("#f4d58d"))
	var fade_out_duration: float = float(style.get("fade_out_duration", DEFAULT_FADE_OUT_DURATION))
	var hold_duration: float = float(style.get("hold_duration", DEFAULT_HOLD_DURATION))
	var fade_in_duration: float = float(style.get("fade_in_duration", DEFAULT_FADE_IN_DURATION))
	var cross_duration: float = float(style.get("cross_duration", DEFAULT_CROSS_DURATION))
	var quadrant_duration: float = float(style.get("quadrant_duration", DEFAULT_QUADRANT_DURATION))
	var effect: String = str(style.get("effect", EFFECT_CROSS_QUADRANT))
	_create_overlay(title, background_color, accent_color, style)

	# スタイルの effect 名で、戦闘ごとに使う覆い方を切り替える。
	await _play_cover_effect(effect, style, fade_out_duration, cross_duration, quadrant_duration)
	var title_tween := create_tween()
	title_tween.set_parallel(true)
	title_tween.tween_property(_title_label, "modulate:a", 1.0, fade_out_duration)
	title_tween.tween_property(_accent_bar, "modulate:a", 1.0, fade_out_duration)
	await title_tween.finished
	await get_tree().create_timer(hold_duration).timeout

	var change_error: int = get_tree().change_scene_to_file(scene_path)
	if change_error != OK:
		push_error("Could not change scene to: %s (error %d)" % [scene_path, change_error])
		await _play_reveal_effect(effect, fade_in_duration)
		_clear_overlay()
		_is_transitioning = false
		return

	# SceneTransitionはAutoloadなので、画面を切り替えても黒幕を保ったまま次画面へ渡せる。
	await get_tree().process_frame
	await _play_reveal_effect(effect, fade_in_duration)
	_clear_overlay()
	_is_transitioning = false

func _create_overlay(title: String, background_color: Color, accent_color: Color, style: Dictionary) -> void:
	_transition_overlay = Control.new()
	_transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_transition_overlay)

	_backdrop = ColorRect.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(background_color.r, background_color.g, background_color.b, 0.0)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_transition_overlay.add_child(_backdrop)
	_backdrop.color.a = 0.0

	# 十字は中央から伸ばし、その後に四つの矩形で画面を覆う。
	var center_point := get_viewport().get_visible_rect().size * 0.5
	var cross_thickness := CROSS_THICKNESS
	_cross_horizontal = _make_panel(background_color)
	_cross_horizontal.position = Vector2(center_point.x, center_point.y - cross_thickness * 0.5)
	_cross_horizontal.size = Vector2(0.0, cross_thickness)
	_transition_overlay.add_child(_cross_horizontal)
	_cross_vertical = _make_panel(background_color)
	_cross_vertical.position = Vector2(center_point.x - cross_thickness * 0.5, center_point.y)
	_cross_vertical.size = Vector2(cross_thickness, 0.0)
	_transition_overlay.add_child(_cross_vertical)

	_quadrant_panels.clear()
	for index in range(4):
		var panel := _make_panel(background_color)
		panel.position = center_point
		panel.size = Vector2.ZERO
		_transition_overlay.add_child(panel)
		_quadrant_panels.append(panel)

	# 斜めの境界が回る別パターン用。矩形パターンでは透明のまま残る。
	_windmill_wipe = ColorRect.new()
	_windmill_wipe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_windmill_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_windmill_material = ShaderMaterial.new()
	_windmill_material.shader = WINDMILL_WIPE_SHADER
	_windmill_material.set_shader_parameter("progress", -0.02)
	_windmill_material.set_shader_parameter("rotation", 0.0)
	_windmill_material.set_shader_parameter("cover_color", background_color)
	# 16px刻みを初期値にし、0を指定すれば滑らかな境界にも切り替えられる。
	_windmill_material.set_shader_parameter("step_size_pixels", float(style.get("step_size_pixels", 16.0)))
	_windmill_wipe.material = _windmill_material
	_transition_overlay.add_child(_windmill_wipe)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_overlay.add_child(center)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(content)

	_title_label = Label.new()
	_title_label.text = title
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 42)
	_title_label.add_theme_color_override("font_color", Color("#fff4d7"))
	_title_label.modulate.a = 0.0
	content.add_child(_title_label)

	_accent_bar = ColorRect.new()
	_accent_bar.custom_minimum_size = Vector2(170, 4)
	_accent_bar.color = accent_color
	_accent_bar.modulate.a = 0.0
	_accent_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_accent_bar)

func _make_panel(color: Color) -> ColorRect:
	var panel := ColorRect.new()
	panel.color = color
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

func _play_cross_wipe(cross_duration: float, quadrant_duration: float) -> void:
	await _play_cross_bars(cross_duration)

	# 四つの斜めの前線を同時に回転させながら、画面を覆う。
	var view_size := get_viewport().get_visible_rect().size
	var center_point: Vector2 = view_size * 0.5
	var half_thickness: float = CROSS_THICKNESS * 0.5
	var quadrant_tween := create_tween()
	quadrant_tween.set_parallel(true)
	var targets: Array[Dictionary] = [
		{"position": Vector2.ZERO, "size": center_point - Vector2(half_thickness, half_thickness)},
		{"position": Vector2(center_point.x + half_thickness, 0.0), "size": Vector2(view_size.x - center_point.x - half_thickness, center_point.y - half_thickness)},
		{"position": Vector2(0.0, center_point.y + half_thickness), "size": Vector2(center_point.x - half_thickness, view_size.y - center_point.y - half_thickness)},
		{"position": center_point + Vector2(half_thickness, half_thickness), "size": view_size - center_point - Vector2(half_thickness, half_thickness)},
	]
	for index in range(_quadrant_panels.size()):
		quadrant_tween.tween_property(_quadrant_panels[index], "position", targets[index]["position"], quadrant_duration)
		quadrant_tween.tween_property(_quadrant_panels[index], "size", targets[index]["size"], quadrant_duration)
	await quadrant_tween.finished

func _play_cover_effect(effect: String, style: Dictionary, fade_duration: float, cross_duration: float, quadrant_duration: float) -> void:
	match effect:
		EFFECT_FADE:
			# 旧来の暗転も残し、スタイルの effect を変えるだけで選べるようにする。
			var fade_tween := create_tween()
			fade_tween.tween_property(_backdrop, "color:a", float(style.get("cover_alpha", 0.94)), fade_duration)
			await fade_tween.finished
		EFFECT_CROSS_QUADRANT:
			# 中央の十字を伸ばしてから、四領域を矩形で覆う。
			await _play_cross_wipe(cross_duration, quadrant_duration)
		EFFECT_WINDMILL_QUADRANT:
			# 中央の十字の後、斜めの四つの境界を回しながら覆う。
			await _play_windmill_cover(cross_duration, quadrant_duration)
		_:
			push_warning("Unknown scene transition effect '%s'; using cross_quadrant." % effect)
			await _play_cross_wipe(cross_duration, quadrant_duration)

func _play_reveal_effect(effect: String, duration: float) -> void:
	match effect:
		EFFECT_FADE:
			_title_label.modulate.a = 0.0
			_accent_bar.modulate.a = 0.0
			var fade_tween := create_tween()
			fade_tween.tween_property(_backdrop, "color:a", 0.0, duration)
			await fade_tween.finished
		EFFECT_CROSS_QUADRANT:
			await _reveal_cross_wipe(duration)
		EFFECT_WINDMILL_QUADRANT:
			await _reveal_windmill_wipe(duration)
		_:
			await _reveal_cross_wipe(duration)

func _reveal_cross_wipe(duration: float) -> void:
	_title_label.modulate.a = 0.0
	_accent_bar.modulate.a = 0.0
	# 四区画を同時に中央へ戻し、その後十字を縮めて現在のシーンを見せる。
	var quadrant_tween := create_tween()
	quadrant_tween.set_parallel(true)
	var center_point := get_viewport().get_visible_rect().size * 0.5
	for panel in _quadrant_panels:
		quadrant_tween.tween_property(panel, "position", center_point, duration)
		quadrant_tween.tween_property(panel, "size", Vector2.ZERO, duration)
	await quadrant_tween.finished

	var view_size := get_viewport().get_visible_rect().size
	var half_thickness := CROSS_THICKNESS * 0.5
	var cross_tween := create_tween()
	cross_tween.set_parallel(true)
	cross_tween.tween_property(_cross_horizontal, "position", Vector2(center_point.x, center_point.y - half_thickness), duration * 0.65)
	cross_tween.tween_property(_cross_horizontal, "size", Vector2.ZERO, duration * 0.65)
	cross_tween.tween_property(_cross_vertical, "position", Vector2(center_point.x - half_thickness, center_point.y), duration * 0.65)
	cross_tween.tween_property(_cross_vertical, "size", Vector2.ZERO, duration * 0.65)
	await cross_tween.finished

func _play_windmill_cover(cross_duration: float, wipe_duration: float) -> void:
	await _play_cross_bars(cross_duration)
	var wipe_tween := create_tween()
	wipe_tween.set_parallel(true)
	wipe_tween.tween_method(_set_windmill_progress, -0.02, WINDMILL_FULL_PROGRESS, wipe_duration)
	wipe_tween.tween_method(_set_windmill_rotation, 0.0, PI * 0.5, wipe_duration)
	await wipe_tween.finished

func _reveal_windmill_wipe(duration: float) -> void:
	_title_label.modulate.a = 0.0
	_accent_bar.modulate.a = 0.0
	var wipe_tween := create_tween()
	wipe_tween.set_parallel(true)
	wipe_tween.tween_method(_set_windmill_progress, WINDMILL_FULL_PROGRESS, -0.02, duration)
	wipe_tween.tween_method(_set_windmill_rotation, PI * 0.5, 0.0, duration)
	await wipe_tween.finished
	await _retract_cross_bars(duration * 0.65)

func _play_cross_bars(duration: float) -> void:
	var view_size := get_viewport().get_visible_rect().size
	var center_point := view_size * 0.5
	var half_thickness := CROSS_THICKNESS * 0.5
	var cross_tween := create_tween()
	cross_tween.set_parallel(true)
	cross_tween.tween_property(_cross_horizontal, "position", Vector2(0.0, center_point.y - half_thickness), duration)
	cross_tween.tween_property(_cross_horizontal, "size", Vector2(view_size.x, CROSS_THICKNESS), duration)
	cross_tween.tween_property(_cross_vertical, "position", Vector2(center_point.x - half_thickness, 0.0), duration)
	cross_tween.tween_property(_cross_vertical, "size", Vector2(CROSS_THICKNESS, view_size.y), duration)
	await cross_tween.finished

func _retract_cross_bars(duration: float) -> void:
	var center_point := get_viewport().get_visible_rect().size * 0.5
	var half_thickness := CROSS_THICKNESS * 0.5
	var cross_tween := create_tween()
	cross_tween.set_parallel(true)
	cross_tween.tween_property(_cross_horizontal, "position", Vector2(center_point.x, center_point.y - half_thickness), duration)
	cross_tween.tween_property(_cross_horizontal, "size", Vector2.ZERO, duration)
	cross_tween.tween_property(_cross_vertical, "position", Vector2(center_point.x - half_thickness, center_point.y), duration)
	cross_tween.tween_property(_cross_vertical, "size", Vector2.ZERO, duration)
	await cross_tween.finished

func _set_windmill_progress(value: float) -> void:
	if is_instance_valid(_windmill_material):
		_windmill_material.set_shader_parameter("progress", value)

func _set_windmill_rotation(value: float) -> void:
	if is_instance_valid(_windmill_material):
		_windmill_material.set_shader_parameter("rotation", value)

func _clear_overlay() -> void:
	if is_instance_valid(_transition_overlay):
		_transition_overlay.queue_free()
	_transition_overlay = null
	_backdrop = null
	_title_label = null
	_accent_bar = null
	_cross_horizontal = null
	_cross_vertical = null
	_quadrant_panels.clear()
	_windmill_wipe = null
	_windmill_material = null
