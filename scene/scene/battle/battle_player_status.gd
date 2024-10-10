class_name BattlePlayerStatus
extends BattleStatus

var _current_energy: int = 3
var _default_max_energy: int = 3
var _max_energy: int = _default_max_energy

signal energy_changed(current_energy, max_energy)

func get_energy() -> int:
	return _current_energy

func get_max_energy() -> int:
	return _max_energy

func reset_energy() -> void:
	_current_energy = _max_energy
	energy_changed.emit(_current_energy, _max_energy)

func try_consume_energy(cost: int) -> bool:
	if _current_energy >= cost:
		_current_energy -= cost
		energy_changed.emit(_current_energy, _max_energy)
		return true
	else:
		return false
