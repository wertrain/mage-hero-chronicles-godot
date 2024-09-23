class_name State
extends Node

signal transitioned(new_state_name: StringName)
signal transitioned_with_param(new_state_name: StringName, params: Dictionary)

# normal enter process
func enter() -> void:
	pass

# enter with parameter
# Implement whichever is necessary
func enter_with_params(_params: Dictionary) -> void:
	pass

func exit() -> void:
	pass
	
func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func input(_event) -> void:
	pass

func transition(_new_state_name: StringName) -> void:
	transitioned.emit(_new_state_name)

func transition_with_param(_new_state_name: StringName, params: Dictionary) -> void:
	transitioned_with_param.emit(_new_state_name, params)
