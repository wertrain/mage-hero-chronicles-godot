class_name SpriteAnimator
extends RefCounted

enum AnimationType {
	BUMP_SWING,
	JUMP_SLAM,
	DASH_SIDE,
	CHARGE,
	FORWARD_SCALE,
	CHARGE_SCALE,
	ROTATE_SCALE,
	SHOCKWAVE_SCALE
}

# 攻撃アクションを受け取って動作を切り替える
func start_animation(type: AnimationType, target: Sprite2D) -> Tween:
	match type:
		AnimationType.BUMP_SWING:
			return _bump_swing(target)
		AnimationType.JUMP_SLAM:
			return _jump_slam(target)
		AnimationType.FORWARD_SCALE:
			return _forward_scale(target)
		AnimationType.CHARGE_SCALE:
			return _charge_scale(target)
		AnimationType.ROTATE_SCALE:
			return _rotate_scale(target)
		AnimationType.SHOCKWAVE_SCALE:
			return _shockwave_scale(target)
	push_warning("undefined animation type.")
	return null

func _bump_swing(target: Sprite2D) -> Tween:
	# スプライトを元の位置から前方に移動させる
	var original_position = target.position
	var attack_position = target.position + Vector2(50, 0)  # 右方向に50ピクセル移動
	var duration = 0.2
	# 移動とその後の元の位置への戻り
	var tween = target.get_tree().create_tween()
	tween.tween_property(target, "position", attack_position, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "position", original_position, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# スプライトを少し回転させる（振る動作を表現）
	tween.tween_property(target, "rotation_degrees", 20, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "rotation_degrees",  0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	return tween

# ジャンプして叩きつける
func _jump_slam(target: Sprite2D) -> Tween:
	var original_position = target.position
	var jump_position = target.position + Vector2(0, -100)  # 上にジャンプ
	var slam_position = target.position + Vector2(0, 50)    # 地面に叩きつける
	var duration_jump = 0.3
	var duration_slam = 0.1
	var duration_return = 0.2
	var tween = target.get_tree().create_tween()
	# ジャンプ動作
	tween.interpolate_property(target, "position", jump_position, duration_jump).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# 叩きつける動作
	tween.interpolate_property(target, "position", slam_position, duration_slam).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# 元の位置に戻る
	tween.interpolate_property(target, "position", original_position, duration_return).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	return tween
	
# 前方に迫る攻撃
func _forward_scale(target: Sprite2D) -> Tween:
	var original_scale = target.scale
	var enlarged_scale = target.scale * Vector2(1.2, 1.2)
	var duration = 0.2
	var tween = target.get_tree().create_tween()
	tween.tween_property(target, "scale", enlarged_scale, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "scale", original_scale, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	return tween

# チャージして攻撃
func _charge_scale(target: Sprite2D) -> Tween:
	var original_scale = target.scale
	var shrink_scale = target.scale * Vector2(0.8, 0.8)
	var enlarged_scale = target.scale * Vector2(1.3, 1.3)
	var duration_shrink_scale = 0.3
	var duration_enlarged_scale = 0.2
	var tween = target.get_tree().create_tween()
	tween.tween_property(target, "scale", shrink_scale, duration_shrink_scale).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "scale", enlarged_scale, duration_enlarged_scale).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "scale", original_scale, duration_enlarged_scale).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	return tween

# スケールと回転を組み合わせた攻撃
func _rotate_scale(target: Sprite2D) -> Tween:
	var original_scale = target.scale
	var enlarged_scale = target.scale * Vector2(1.2, 1.2)
	var original_rotation = target.rotation_degrees
	var attack_rotation = target.rotation_degrees + 15
	var duration = 0.2
	var tween = target.get_tree().create_tween()
	tween.tween_property(target, "scale", enlarged_scale, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "rotation_degrees", attack_rotation, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "scale", original_scale, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "rotation_degrees", original_rotation, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	return tween

# 衝撃波を伴う攻撃
func _shockwave_scale(target: Sprite2D) -> Tween:
	var original_scale = target.scale
	var enlarged_scale = target.scale * Vector2(1.2, 1.2)
	var reduced_scale = target.scale * Vector2(0.9, 0.9)
	var duration_enlarged_scale = 0.2
	var duration_reduced_scale = 0.1
	var tween = target.get_tree().create_tween()
	tween.interpolate_property(target, "scale", enlarged_scale, duration_enlarged_scale).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.interpolate_property(target, "scale", reduced_scale, duration_reduced_scale).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.interpolate_property(target, "scale", original_scale, duration_enlarged_scale).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	return tween
