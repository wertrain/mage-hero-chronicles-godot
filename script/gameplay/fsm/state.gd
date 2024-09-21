class_name State
extends Node

signal transitioned(new_state_name: StringName)

func enter() -> void:
	pass
	
func exit() -> void:
	pass
	
func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func transition(new_state_name: StringName = "") -> void:
	transitioned.emit(new_state_name)

func input(event) -> void:
	pass
