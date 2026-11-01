extends Node2D

func set_battle_background(texture: Texture2D) -> void:
	if texture == null:
		return
	$Sprite2D.texture = texture
	_fit_to_viewport()

func _fit_to_viewport() -> void:
	var sprite := $Sprite2D as Sprite2D
	if sprite.texture == null:
		return
	var viewport_size := get_viewport_rect().size
	var texture_size := sprite.texture.get_size()
	var cover_scale := maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	sprite.position = viewport_size * 0.5
	sprite.scale = Vector2.ONE * cover_scale


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
