class_name SpriteEffect
extends Node2D

@export var animation_name: String = "000" # 再生するアニメーションの名前
@export var autoplay: bool = true # 自動再生するかどうか
@export var sprite_frames: SpriteFrames = preload("res://art/effect/frames/sprite_frames_impact_a1.tres")
@export var speed_scale: float = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 子ノードの AnimatedSprite2D を取得
	var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.speed_scale = speed_scale
	if (autoplay):
		play_effect()

# エフェクトを再生する関数
func play_effect():
	var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
	if animated_sprite and animation_name != "":
		animated_sprite.play(animation_name)
		
func _on_animation_finished() -> void:
	queue_free()
