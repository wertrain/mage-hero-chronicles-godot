class_name ScreenEffect
extends Object

static var _active_twists: Dictionary = {}

static func play_pulse(target: Node2D):
	if (_active_twists.has(target)):
		return;
	var tween: Tween = target.get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	var default_scale = target.scale
	var animation_time = 0.1
	tween.tween_property(target, "scale", default_scale * 1.3, animation_time)
	tween.tween_property(target, "scale", default_scale * 0.8, animation_time)
	tween.tween_property(target, "scale", default_scale * 1.0, animation_time)
	tween.play()
	_active_twists[target] = tween
	await tween.finished
	_active_twists.erase(target)
