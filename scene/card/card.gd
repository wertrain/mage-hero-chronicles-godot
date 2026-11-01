class_name Card
extends Node2D

var _id: int
var _cost: int
var _data: CardData

func set_data(data: CardData) -> void:
	_id = data.id
	$Label_CardName.text = data.name
	$Label_Description.text = data.description
	$Label_Cost.text = str(data.cost)
	$Sprite2D_Card/Control.tooltip_text = data.detail_description
	var illustration := $Sprite2D_Illustration as Sprite2D
	if not data.art_path.is_empty() and ResourceLoader.exists(data.art_path):
		illustration.texture = load(data.art_path) as Texture2D
		illustration.visible = illustration.texture != null
	else:
		illustration.texture = null
		illustration.visible = false
	_cost = data.cost
	_data = data

func get_data() -> CardData:
	return _data
	
func get_cost() -> int:
	return _cost

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func get_rect() -> Rect2:
	# Sprite ノードを取得
	var sprite = $Sprite2D_Background
	# スケールを考慮したサイズを計算
	var rect_size = sprite.texture.get_size() * sprite.scale * scale
	# スケールを考慮した矩形領域を作成
	var rect_position = (position) - (rect_size / 2) # オフセットを調整
	return Rect2(rect_position, rect_size)

func get_visual_rect_in_viewport() -> Rect2:
	# カード画像の実際の描画範囲をビューポート座標で返す。
	# 一覧のセル全体ではなく、この矩形内だけをカードのホバー対象にする。
	var sprite := $Sprite2D_Card as Sprite2D
	return sprite.get_global_transform_with_canvas() * sprite.get_rect()
