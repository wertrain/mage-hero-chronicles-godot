class_name SpriteAnimator
extends RefCounted

enum AnimationType {
	BUMP_SWING,
	JUMP_SLAM,
	DASH_SIDE,
	CHARGE,
	SHAKE,
	FORWARD_SCALE,
	CHARGE_SCALE,
	ROTATE_SCALE,
	SHOCKWAVE_SCALE
}

var speed_multiplier: float = 1.0  # 1.0で通常速度、2.0で2倍速、0.5で半分速

## 再生速度を設定
func set_speed_multiplier(multiplier: float):
	speed_multiplier = multiplier

# 攻撃アクションを受け取って動作を切り替える
func start_animation(type: AnimationType, target: Sprite2D) -> Tween:
	match type:
		AnimationType.BUMP_SWING:
			return _bump_swing(target)
		AnimationType.JUMP_SLAM:
			return _jump_slam(target)
		AnimationType.DASH_SIDE:
			return _dash_side(target)
		AnimationType.CHARGE:
			return _charge(target)
		AnimationType.SHAKE:
			return _shake(target)
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
	var duration = (0.2 / speed_multiplier)
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
	var duration_jump = (0.3 / speed_multiplier)
	var duration_slam = (0.1 / speed_multiplier)
	var duration_return = (0.2 / speed_multiplier)
	var duration_slam_delay = (0.3 / speed_multiplier)
	var duration_return_delay = (0.4 / speed_multiplier)
	var tween = target.get_tree().create_tween()
	# ジャンプ動作
	tween.tween_property(target, "position", jump_position, duration_jump).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# 叩きつける動作
	tween.tween_property(target, "position", slam_position, duration_slam).set_ease(Tween.EASE_IN).set_delay(duration_slam_delay).set_trans(Tween.TRANS_QUAD)
	# 元の位置に戻る
	tween.tween_property(target, "position", original_position, duration_return).set_ease(Tween.EASE_OUT).set_delay(duration_return_delay).set_trans(Tween.TRANS_QUAD)
	return tween

func _dash_side(target: Sprite2D) -> Tween:
	var original_position = target.position
	var dash_position = target.position + Vector2(150, 0)  # 横にダッシュ
	var return_position = target.position  # 元の位置に戻る
	var duration_delay = (0.2 / speed_multiplier)
	var duration_dash = (0.2 / speed_multiplier)
	var duration_return = (0.3 / speed_multiplier)
	var tween = target.get_tree().create_tween()
	# ダッシュ動作
	tween.tween_property(target, "position", dash_position, duration_dash).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# 少し遅れて元の位置に戻る
	tween.tween_property(target, "position", return_position, duration_return).set_ease(Tween.EASE_IN).set_delay(duration_delay).set_trans(Tween.TRANS_QUAD)
	return tween
	
func _charge(target: Sprite2D) -> Tween:
	var original_position = target.position
	var charge_position = target.position + Vector2(30, 0)  # 少し前進してチャージ
	var attack_position = target.position + Vector2(100, 0)  # 一気に攻撃
	var duration_charge = (0.2 / speed_multiplier)
	var duration_attack = (0.2 / speed_multiplier)
	var duration_return = (0.3 / speed_multiplier)
	var duration_attack_delay = (0.4 / speed_multiplier)
	var duration_return_delay = (0.5 / speed_multiplier)
	var tween = target.get_tree().create_tween()
	# チャージ動作（ゆっくり前進）
	tween.tween_property(target, "position", charge_position, duration_charge).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# 一気に攻撃（速く前進）
	tween.tween_property(target, "position", attack_position, duration_attack).set_delay(duration_attack_delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# 元の位置に戻る
	tween.tween_property(target, "position", original_position, duration_return).set_delay(duration_return_delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	return tween

func _shake(target: Sprite2D) -> Tween:
	var original_position = target.position
	var shake_position_left = target.position + Vector2(-20, 0)  # 左に少し揺れる
	var shake_position_right = target.position + Vector2(20, 0)  # 右に少し揺れる
	var duration_shake = (0.05 / speed_multiplier)
	var duration_first_delay = (0.05 / speed_multiplier)
	var duration_second_delay = (0.1 / speed_multiplier)
	var duration_return_delay = (0.15 / speed_multiplier)
	var tween = target.get_tree().create_tween()
	# 左右に震動
	tween.tween_property(target, "position", shake_position_left, duration_shake).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "position", shake_position_right, duration_shake).set_delay(duration_first_delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "position", shake_position_left, duration_shake).set_delay(duration_second_delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "position", original_position, duration_shake).set_delay(duration_return_delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	return tween

# 前方に迫る攻撃
func _forward_scale(target: Sprite2D) -> Tween:
	var original_scale = target.scale
	var enlarged_scale = target.scale * Vector2(1.2, 1.2)
	var duration = (0.2 / speed_multiplier)
	var duration_delay = (0.2 / speed_multiplier)
	var tween = target.get_tree().create_tween()
	tween.tween_property(target, "scale", enlarged_scale, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "scale", original_scale, duration).set_ease(Tween.EASE_IN).set_delay(duration_delay).set_trans(Tween.TRANS_QUAD)
	return tween

# チャージして攻撃
func _charge_scale(target: Sprite2D) -> Tween:
	var original_scale = target.scale
	var shrink_scale = target.scale * Vector2(0.8, 0.8)
	var enlarged_scale = target.scale * Vector2(1.3, 1.3)
	var duration_shrink_scale = (0.3 / speed_multiplier)
	var duration_enlarged_scale = (0.2 / speed_multiplier)
	var duration_return_scale = (0.2 / speed_multiplier)
	var duration_enlarged_delay = (0.3 / speed_multiplier)
	var duration_return_delay = (0.5 / speed_multiplier)
	var tween = target.get_tree().create_tween()
	tween.tween_property(target, "scale", shrink_scale, duration_shrink_scale).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "scale", enlarged_scale, duration_enlarged_scale).set_ease(Tween.EASE_IN).set_delay(duration_enlarged_delay).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "scale", original_scale, duration_return_scale).set_ease(Tween.EASE_OUT).set_delay(duration_return_delay).set_trans(Tween.TRANS_QUAD)
	return tween

# スケールと回転を組み合わせた攻撃
func _rotate_scale(target: Sprite2D) -> Tween:
	var original_scale = target.scale
	var enlarged_scale = target.scale * Vector2(1.2, 1.2)
	var original_rotation = target.rotation_degrees
	var attack_rotation = target.rotation_degrees + 15
	var duration = (0.2 / speed_multiplier)
	var duration_delay = (0.2 / speed_multiplier)
	var tween = target.get_tree().create_tween()
	tween.tween_property(target, "scale", enlarged_scale, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "rotation_degrees", attack_rotation, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "scale", original_scale, duration).set_ease(Tween.EASE_IN).set_delay(duration_delay).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "rotation_degrees", original_rotation, duration).set_ease(Tween.EASE_IN).set_delay(duration_delay).set_trans(Tween.TRANS_QUAD)
	return tween

# 衝撃波を伴う攻撃
func _shockwave_scale(target: Sprite2D) -> Tween:
	var original_scale = target.scale
	var enlarged_scale = target.scale * Vector2(1.2, 1.2)
	var reduced_scale = target.scale * Vector2(0.9, 0.9)
	var duration_enlarged_scale = (0.2 / speed_multiplier)
	var duration_reduced_scale = (0.1 / speed_multiplier)
	var duration_return_scale = (0.2 / speed_multiplier)
	var duration_reduced_delay = (0.2 / speed_multiplier)
	var duration_return_delay = (0.3 / speed_multiplier)
	var tween = target.get_tree().create_tween()
	tween.tween_property(target, "scale", enlarged_scale, duration_enlarged_scale).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "scale", reduced_scale, duration_reduced_scale).set_delay(duration_reduced_delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "scale", original_scale, duration_return_scale).set_delay(duration_return_delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	return tween
