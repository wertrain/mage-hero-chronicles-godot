class_name BattleEnemy
extends Node2D

var _enemy_data: EnemyData

func get_sprite() -> Sprite2D:
	return $Sprite2D
	
func damage(damage_value: int) -> bool:
	var health = $HealthBar.get_health()
	health -= damage_value
	if (health <= 0):
		health = 0;
	$HealthBar.set_health(health, _enemy_data.health)
	return health > 0

func get_sprite_rect():
	return $Sprite2D.get_rect()
	
func shake():
	$Shake2D.play_shake()

func set_data(data: EnemyData) -> void:
	_enemy_data = data
	$HealthBar.set_health(data.health, data.health)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
