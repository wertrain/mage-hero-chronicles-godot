class_name BattlePlayer
extends BattleStatus

var _current_energy: int = 3
var _max_energy: int = 3

signal energy_changed(current_energy, max_energy)

func get_energy() -> int:
	return _current_energy

func get_max_energy() -> int:
	return _max_energy

func try_consume_energy(cost: int) -> bool:
	if _current_energy >= cost:
		_current_energy -= cost
		energy_changed.emit(_current_energy, _max_energy)
		return true
	else:
		return false
