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
	_cost = data.cost

func get_data() -> CardData:
	return _data

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
