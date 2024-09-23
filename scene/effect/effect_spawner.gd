class_name EffectSpawner
extends Node2D

# エフェクトのシーンをロード
var effect_scene: PackedScene = preload("res://scene/effect/sprite_effect.tscn")

# エフェクトを生成して再生
func spawn(animation_name: String, effect_position: Vector2):
	var effect = effect_scene.instantiate() as SpriteEffect
	effect.position = effect_position
	effect.animation_name = animation_name
	effect.scale = Vector2(5.0, 5.0)
	add_child(effect)
