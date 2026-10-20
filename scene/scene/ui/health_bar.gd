class_name HealthBar
extends Node2D

var current_shield: int = 0
var shield_bar_texture = preload("res://art/ui/bar/bar_blue.png")
var normal_bar_texture = preload("res://art/ui/bar/bar_red.png")
var status_effect_icon_scene = preload("res://scene/scene/battle/ui/battle_status_effect_icon.tscn")

func set_health(health: int, max_health: int) -> void:
	$TextureProgressBar.max_value = max_health
	$TextureProgressBar.value = health
	$TextureProgressBar/Label.text = "%d/%d" % [health, max_health]
	$Sprite2D_Shield.visible = current_shield > 0
	$Sprite2D_Shield/Label_Shield.text = "%d" % current_shield
	
func set_shield(shield: int) -> void:
	current_shield = shield
	$Sprite2D_Shield/Label_Shield.text  = "%d" % current_shield
	$Sprite2D_Shield.visible = current_shield > 0
	if $Sprite2D_Shield.visible:
		$TextureProgressBar.texture_progress = shield_bar_texture
	else:
		$TextureProgressBar.texture_progress = normal_bar_texture

func set_status_effect_icons(effects: Array[BattleStatusEffect]) -> void:
	for child in $Node2D_StatusIcons.get_children():
		child.queue_free()
	var visible_index := 0
	for effect: BattleStatusEffect in effects:
		if BattleStatusEffectIcon.get_icon_type(effect.get_type(), effect.get_value()) == BattleStatusEffectIcon.Icons.None:
			continue
		var node: BattleStatusEffectIcon = status_effect_icon_scene.instantiate()
		node.position = Vector2(44 * visible_index, 0)
		node.scale = Vector2(0.8, 0.8)
		$Node2D_StatusIcons.add_child(node)
		# 子スプライトの_ready()でアトラスを初期化してから表示内容を設定する。
		var remaining_turns := effect.get_remaining_turns() if effect.get_duration_type() == BattleStatusEffect.EffectDurationType.TURN_BASED else 0
		node.add_icon(effect.get_type(), effect.get_value(), remaining_turns)
		visible_index += 1

func get_health() -> int:
	return $TextureProgressBar.value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
