class_name BattlePlayer
extends Node

var _current_energy: int = 3
var _max_energy: int = 3
var _life: int = 100
var _max_life: int = 100

signal energy_changed(current_energy, max_energy)
signal life_changed(life, max_life)

func get_energy() -> int:
	return _current_energy

func get_max_energy() -> int:
	return _max_energy
	
func get_life() -> int:
	return _life

func get_max_life() -> int:
	return _max_life
	
func try_consume_energy(cost: int) -> bool:
	if _current_energy >= cost:
		_current_energy -= cost
		energy_changed.emit(_current_energy, _max_energy)
		return true
	else:
		return false

func damage(damage_value: int) -> bool:
	_life -= damage_value
	if _life <= 0:
		_life -= 0
	life_changed.emit(_life, _max_life)
	return _life > 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
