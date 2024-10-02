class_name AtlasSprite2D
extends Sprite2D

## アトラステクスチャのユーティリティ

## 画像一つ当たりのサイズ
@export var tile_size: Vector2 = Vector2(32, 32)	
## アトラステクスチャ
@export var atlas_texture: AtlasTexture

func _ready() -> void:
	texture = atlas_texture
	set_atlas_region(1)

func _process(_delta: float) -> void:
	pass

# 特定の画像を設定する関数
func set_atlas_region(index: int):
	# アトラス内の行と列を計算
	var cols = atlas_texture.atlas.get_width() / tile_size.x
	var row = index / cols
	var col = index % int(cols)
	# テクスチャの範囲を設定
	atlas_texture.region = Rect2(col * tile_size.x, row * tile_size.y, tile_size.x, tile_size.y)
