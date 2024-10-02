class_name EffectSpawner
extends Node2D

# エフェクトのシーンをロード
var effect_scene: PackedScene = preload("res://scene/effect/sprite_effect.tscn")

enum EffectType {
	IMPACT_A,
	IMPACT_B,
	DRAW
}

var sprite_frame_list = [
	preload("res://art/effect/frames/sprite_frames_impact_a1.tres"),
	preload("res://art/effect/frames/sprite_frames_impact_a1.tres"),
]

var effect_scale_list = [
	Vector2(5.0, 5.0),
	Vector2(5.0, 5.0),
]

var effect_speed_scale_list = [
	4.0,
	4.0,
]

# エフェクトを生成して再生
func spawn(type: EffectType, index: int, effect_position: Vector2):
	spawn_by_name(type, "%03d" % index, effect_position)
	
func spawn_by_name(type: EffectType, animation_name: String, effect_position: Vector2):
	var effect = effect_scene.instantiate() as SpriteEffect
	effect.sprite_frames = sprite_frame_list[type]
	effect.position = effect_position
	effect.animation_name = animation_name
	effect.speed_scale = effect_speed_scale_list[type]
	effect.scale = effect_scale_list[type]
	add_child(effect)
