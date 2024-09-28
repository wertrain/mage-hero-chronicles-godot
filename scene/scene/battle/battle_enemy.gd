class_name BattleEnemy
extends Node2D

var _enemy_data: EnemyData
var _battle_status: BattleStatus
var _action_queue: Array = Array()

func get_sprite() -> Sprite2D:
	return $Sprite2D

func get_sprite_rect():
	return $Sprite2D.get_rect()

func get_status():
	return _battle_status
	
func shake():
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_health_changed(health: int, max_health :int):
	$HealthBar.set_health(health, max_health)
