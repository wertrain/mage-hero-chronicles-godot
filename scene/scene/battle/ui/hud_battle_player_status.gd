class_name HudBattlePlayerStatus
extends Node2D

var _life: int = 0
var _max_life: int = 0

func _update_life_text() -> void:
	var life_label: Label = $ReferenceRect/MarginContainer/ColorRect_Inner/Label_Life
	life_label.text = "%d/%d" % [_life, _max_life]
	var bar: TextureProgressBar = $ReferenceRect/MarginContainer/ColorRect_Inner/TextureProgressBar_Life
	bar.max_value = _max_life;
	bar.value = _life
	
func setup(battle_player: BattlePlayer):
	battle_player.life_changed.connect(_on_life_changed)
	_life = battle_player.get_life()
	_max_life = battle_player.get_max_life()
	_update_life_text()


func _on_life_changed(life: int, max_life: int):
	_life = life
	_max_life = max_life
	_update_life_text()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
