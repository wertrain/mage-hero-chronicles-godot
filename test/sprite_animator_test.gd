extends Node2D

var _animator: SpriteAnimator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_animator = SpriteAnimator.new()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (Input.is_action_just_pressed("ui_accept")):
		_animator.start_animation(SpriteAnimator.AnimationType.DASH_SIDE, $Camera2D/Sprite2D)
