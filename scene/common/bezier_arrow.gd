class_name BezierArrow
extends Node2D

@export var point_texture: Texture
## このコードの描画順序
const Z_INDEX = 10
## 矢印先頭のテクスチャのスケール
const ARROW_TEXTURE_SCALE =  0.15
## 描画するラインの幅
const LINE_WIDTH = 8
## 矢印の色
var ARROW_LINE_COLOR = Globals.TARGET_SELECTION_COLOR

# ベジェ曲線の制御点
var p0 = Vector2(100, 300)  # 始点
var p1 = Vector2(300, 100)  # 中間点
var p2 = Vector2(500, 300)  # 終点

# 曲線の分割数を動的に設定可能
var num_points = 15

func _init() -> void:
	z_index = Z_INDEX
	set_active(false)

func _input(event):
	pass
	#if event is InputEventMouseButton:
	#	var mouse_pos = event.position
	#	p2 = mouse_pos	
	#elif event is InputEventMouseMotion:
	#	var mouse_pos = event.position
	#s	p2 = mouse_pos

func _process(delta: float) -> void:
	queue_redraw()

func _draw():
	# 任意の数の点に分割してベジェ曲線を描画
	var points = get_bezier_points(num_points)
	draw_polyline(points, ARROW_LINE_COLOR, LINE_WIDTH)
	# 点の上にテクスチャを描画する
	for i in range(points.size()):
		var point = points[i]
		#draw_circle(point, 46, Color(0, 0, 1))  # 青色の円を描画
		
		var direction = 0
		var texture_scale = 0.08
				
		# 次のポイントに向かうベクトルを計算
		var next_point = point
		if (i < points.size() - 1):
			next_point = points[i + 1]
			direction = (next_point - point).normalized()
			continue # いったん最後の点以外にはテクスチャをつけないようにしておく
		# 最後のポイントは前回のポイントと同じ向きにする、またスケールも変更する
		else:
			var prev_point = points[i - 1]
			texture_scale = ARROW_TEXTURE_SCALE
			direction = (point - prev_point).normalized()

		# 画像の回転角度を計算（ラジアン）
		var angle = direction.angle() + PI / 2

		# 画像のスケールを設定
		#var texture_size = point_texture.get_size() * texture_scale
		#var texture_center = texture_size / 2

		# 回転のためのTransform2Dを設定
		var transform = Transform2D().rotated(angle).scaled(Vector2(texture_scale, texture_scale)).translated(point)  # その後、画像の位置を指定

		# 新しいTransformを設定
		draw_set_transform_matrix(transform)
		
		# 画像を描画
		draw_texture(point_texture, -point_texture.get_size() / 2, ARROW_LINE_COLOR)
		
		# 元のTransformに戻す
		draw_set_transform_matrix(Transform2D.IDENTITY)

## 矢印の表示を開始する
func start(start_point: Vector2) -> void:
	set_start_start(start_point)
	set_active(true)

## 矢印の始点を設定する
func set_start_start(start_point: Vector2) -> void:
	p0 = start_point
	p1 = Vector2(p0.x, p0.y - 32)

## 矢印の終点を設定する
## 終点はテクスチャサイズを加味した位置に補正する
func set_end_point(end_point: Vector2) -> void:
	var texture_size = point_texture.get_size() * ARROW_TEXTURE_SCALE
	var texture_center = texture_size / 2
	p2 = end_point + texture_center

## このノードのアクティブを切り替える
## 非アクティブの間は、表示も各種イベントや更新も行われなくなる
func set_active(active: bool) -> void:
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

## 任意個数の点にベジェ曲線を分解する関数
func get_bezier_points(num_points: int) -> Array:
	var curve_points = []
	for i in range(num_points):
		var t = float(i) / float(num_points - 1)  # 0から1の範囲で t を分割
		var point = calculate_bezier_point(t, p0, p1, p2)
		curve_points.append(point)
	return curve_points

## 2次ベジェ曲線上の点を計算する関数
func calculate_bezier_point(t: float, p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	var u = 1 - t
	var tt = t * t
	var uu = u * u

	var point = uu * p0   # (1 - t)^2 * p0
	point += 2 * u * t * p1  # 2 * (1 - t) * t * p1
	point += tt * p2   # t^2 * p2
	
	return point
