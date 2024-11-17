class_name BattleEnemy
extends Node2D

@export var outline_material: Material

var _enemy_data: EnemyData
var _battle_status: BattleStatus
var _action_queue: Array[EnemyBattleAcitonBase] = []
var _sprite_animator: SpriteAnimator

func get_sprite() -> Sprite2D:
	return $Sprite2D

func get_sprite_rect() -> Rect2:
	return $Sprite2D.get_rect()

func get_status() -> BattleStatus:
	return _battle_status

func get_data() -> EnemyData:
	return _enemy_data

func get_action_queue() -> Array[EnemyBattleAcitonBase]:
	return _action_queue

func shake() -> void:
	$Shake2D.play_shake()

func damage(damage_value: int) -> bool:
	return _battle_status.apply_damage(damage_value)

func set_data(data: EnemyData) -> void:
	_enemy_data = data
	_battle_status.set_health(data.health, data.health)
	$HealthBar.set_health(data.health, data.health)
	_battle_status.set_attack(data.attack)

func show_warning_icon(icon_type: AttackWarningIcon.Icons, value: int) -> void:
	$AttackWarningIcon.set_icon(icon_type, value)
	$AttackWarningIcon.set_visible(true)

func hidden_warning_icon() -> void:
	$AttackWarningIcon.set_icon(AttackWarningIcon.Icons.ATTACK, 0)
	$AttackWarningIcon.set_visible(false)
	
func set_visible_outline(visible) -> void:
	$Sprite2D.material = null if not visible else outline_material
	if (visible):
		$Sprite2D.material.set_shader_parameter("color", Globals.TARGET_SELECTION_COLOR)

func start_attack_action(type: SpriteAnimator.AnimationType) -> Tween:
	return _sprite_animator.start_animation(type, $Sprite2D)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_battle_status = BattleStatus.new()
	_battle_status.health_changed.connect(_on_health_changed)
	_battle_status.status_effects_changed.connect(_on_status_effects_changed)
	_sprite_animator = SpriteAnimator.new()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_health_changed(health: int, max_health :int) -> void:
	$HealthBar.set_health(health, max_health)
	
func _on_status_effects_changed(status_effects: Array[BattleStatusEffect]) -> void:
	$HealthBar.set_status_effect(status_effects)
