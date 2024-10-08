extends Node2D

var _animator: SpriteAnimator

var _animation_names = {
	SpriteAnimator.AnimationType.BUMP_SWING: "BUMP_SWING",
	SpriteAnimator.AnimationType.JUMP_SLAM: "JUMP_SLAM",
	SpriteAnimator.AnimationType.DASH_SIDE: "DASH_SIDE",
	SpriteAnimator.AnimationType.CHARGE: "CHARGE",
	SpriteAnimator.AnimationType.SHAKE: "SHAKE",
	SpriteAnimator.AnimationType.FORWARD_SCALE: "FORWARD_SCALE",
	SpriteAnimator.AnimationType.CHARGE_SCALE: "CHARGE_SCALE",
	SpriteAnimator.AnimationType.ROTATE_SCALE: "ROTATE_SCALE",
	SpriteAnimator.AnimationType.SHOCKWAVE_SCALE: "SHOCKWAVE_SCALE"
}
var _animation_index = 0
var _is_animation: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Control/Label.text = ""
	_animator = SpriteAnimator.new()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (Input.is_action_just_pressed("ui_accept") and not _is_animation):
		var key = _animation_names.keys()[_animation_index]
		var name = _animation_names.get(key)
		$Control/Label.text = name
		_is_animation = true
		await _animator.start_animation(key, $Control/Sprite2D).finished
		_is_animation = false
		_animation_index = _animation_index + 1
		if _animation_names.keys().size() <= _animation_index:
			_animation_index = 0
