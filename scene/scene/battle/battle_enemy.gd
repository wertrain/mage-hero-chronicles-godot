class_name BattleEnemy
extends Node2D

var _enemy_data: EnemyData
var _battle_status: BattleStatus
var _action_queue: Array[EnemyBattleAciton] = []
var _attack_warning_icon: AtlasSprite2D

func get_sprite() -> Sprite2D:
	return $Sprite2D

func get_sprite_rect() -> Rect2:
	return $Sprite2D.get_rect()

func get_status() -> BattleStatus:
	return _battle_status

func get_data() -> EnemyData:
	return _enemy_data

func get_action_queue() -> Array[EnemyBattleAciton]:
	return _action_queue

func shake() -> void:
	$Shake2D.play_shake()

func damage(damage_value: int) -> bool:
	return _battle_status.damage(damage_value)

func set_data(data: EnemyData) -> void:
	_enemy_data = data
	_battle_status.set_health(data.health, data.health)
	$HealthBar.set_health(data.health, data.health)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_battle_status = BattleStatus.new()
	_battle_status.health_changed.connect(_on_health_changed)
	_attack_warning_icon = AtlasSprite2D.new()
	_attack_warning_icon.atlas_texture = load("res://art/icon/atlas_texture_rpg_weapon_tool.tres")
	_attack_warning_icon.scale = Vector2(2.0, 2.0)
	add_child(_attack_warning_icon)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_health_changed(health: int, max_health :int) -> void:
	$HealthBar.set_health(health, max_health)
