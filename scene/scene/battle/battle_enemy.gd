class_name BattleEnemy
extends Node2D

@export var outline_material: Material

var _enemy_data: EnemyData
var _battle_status: BattleStatus
var _action_queue: Array[EnemyBattleAcitonBase] = []
var _sprite_animator: SpriteAnimator
var _name_label: Label

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
	# 敵定義の画像を本体とシーンに残る予備スプライトへ適用し、素材を揃えておく。
	if not data.image_path.is_empty() and ResourceLoader.exists(data.image_path):
		var texture := load(data.image_path) as Texture2D
		$Sprite2D.texture = texture
		$Sprite2D2.texture = texture
	_battle_status.set_health(data.health, data.health)
	$HealthBar.set_health(data.health, data.health)
	_battle_status.set_attack(data.attack)
	_name_label.text = data.name
	_name_label.position.y = -$Sprite2D.get_rect().size.y / 2.0 - 42.0

func promote_to_elite() -> void:
	# HPを1.5倍、攻撃力を2上げて、専用表示で通常敵との違いを示す。
	var elite_max_health := ceili(_enemy_data.health * 1.5)
	_battle_status.set_health(elite_max_health, elite_max_health)
	$HealthBar.set_health(elite_max_health, elite_max_health)
	_battle_status.add_status_effects(BattleStatusEffect.new(BattleStatusEffect.StatusEffectType.OFFENSE, 2))
	_name_label.text = tr("BATTLE_ELITE_ENEMY_NAME") % _enemy_data.name

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

func start_action_animation(type: SpriteAnimator.AnimationType) -> Tween:
	return _sprite_animator.start_animation(type, $Sprite2D)

func start_attack_action(type: SpriteAnimator.AnimationType) -> Tween:
	# 既存の呼び出し元との互換性を残しつつ、敵の全行動演出を同じ入口にまとめる。
	return start_action_animation(type)

func is_dead() -> bool:
	return _battle_status.has_status_effect(BattleStatusEffect.StatusEffectType.DEAD)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# シーンに残っている旧スプライトは重ね描画を防ぐため隠し、本体だけ表示する。
	$Sprite2D2.visible = false
	_battle_status = BattleStatus.new()
	_battle_status.health_changed.connect(_on_health_changed)
	_battle_status.status_effects_changed.connect(_on_status_effects_changed)
	_sprite_animator = SpriteAnimator.new()
	_name_label = Label.new()
	_name_label.size = Vector2(320, 36)
	_name_label.position.x = -160.0
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78))
	_name_label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.06))
	_name_label.add_theme_constant_override("outline_size", 5)
	_name_label.add_theme_font_size_override("font_size", 20)
	add_child(_name_label)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_health_changed(health: int, max_health :int) -> void:
	$HealthBar.set_health(health, max_health)
	
func _on_status_effects_changed(status_effects: Array[BattleStatusEffect]) -> void:
	$HealthBar.set_status_effect_icons(status_effects)
