class_name AtlasSprite2D
extends Sprite2D

## アトラステクスチャのユーティリティ

## 画像一つ当たりのサイズ
@export var tile_size: Vector2 = Vector2(32, 32)	
## アトラステクスチャ
@export var atlas_texture: AtlasTexture

# 元の位置を保持するための変数
var original_position: Vector2

func _ready() -> void:
	texture = atlas_texture
	set_atlas_region(0)
	# 元の位置を保持
	original_position = position


func _process(_delta: float) -> void:
	pass

func start_floating():
	var float_distance = 5  # 小さな上下動き
	var duration = 1.0  # アニメーションの速さ
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", original_position + Vector2(0, -float_distance), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", original_position + Vector2(0, +float_distance), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.set_loops(0)

# 特定の画像を設定する関数
func set_atlas_region(index: int):
	# アトラス内の行と列を計算
	var cols = atlas_texture.atlas.get_width() / tile_size.x
	var row = index / int(cols)
	var col = index % int(cols)
	# テクスチャの範囲を設定
	atlas_texture.region = Rect2(col * tile_size.x, row * tile_size.y, tile_size.x, tile_size.y)
