class_name BezierArrow
extends Node2D

@export var point_texture: Texture

@export var start_point: Vector2 = Vector2(100, 300)  # 始点
@export var end_point: Vector2 = Vector2(100, 300) # 終点
# ベジェ曲線の制御点

var middle_point = Vector2(300, 100)  # 中間点

# 曲線の分割数を動的に設定可能
var num_points = 30

func _input(event):
	if event is InputEventMouseMotion:
		var mouse_pos = event.position
		end_point = mouse_pos
		queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

#var _angle = 0
func _draw():
	# 任意の数の点に分割してベジェ曲線を描画
	var points = get_bezier_points(num_points)
	for i in range(points.size()):
		var point = points[i]
		draw_circle(point, 16, Color(1, 0, 0))  # 青色の円を描画
		
		# 次のポイントに向かうベクトルを計算
		var next_point = point
		if (i < points.size() - 1):
			next_point = points[i + 1]
		var direction = (next_point - point).normalized()

		# 画像の回転角度を計算（ラジアン）
		var _angle = direction.angle()
		
		#var rect = Rect2(point - texture_size / 2, texture_size)  # 中心に配置するために位置を調整
		var texture_scale = 0.25
		var texture_size = point_texture.get_size() * texture_scale
		var texture_point = point - texture_size / 2
		
		#var rect = Rect2(-texture_size / 2, texture_size)
		# 回転のためのTransform2Dを設定
		#var transform = Transform2D().translated(texture_point).scaled(Vector2(texture_scale, texture_scale))
		var _transform = Transform2D().translated(texture_point).rotated_local(_angle)
		
		#_angle += 0.01
		#draw_set_transform(texture_point, _angle, Vector2.ONE)
		#draw_set_transform(texture_point, _angle, Vector2(texture_scale, texture_scale))
		#draw_set_transform_matrix(transform)
		#draw_texture(point_texture, -point_texture.get_size() / 2)
		#draw_set_transform_matrix(Transform2D.IDENTITY)
		
	# ベジェ曲線を描画
	#draw_polyline(points, Color(1, 0, 0), 3)

# 任意個数の点にベジェ曲線を分解する関数
func get_bezier_points(num: int) -> Array:
	var curve_points = []
	for i in range(num):
		var t = float(i) / float(num - 1)  # 0から1の範囲で t を分割
		var point = calculate_bezier_point(t, start_point, middle_point, end_point)
		curve_points.append(point)
	return curve_points

# 2次ベジェ曲線上の点を計算する関数
func calculate_bezier_point(t: float, p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	var u = 1 - t
	var tt = t * t
	var uu = u * u

	var point = uu * p0   # (1 - t)^2 * p0
	point += 2 * u * t * p1  # 2 * (1 - t) * t * p1
	point += tt * p2   # t^2 * p2
	
	return point
