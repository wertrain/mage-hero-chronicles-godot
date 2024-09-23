class_name StateMachine
extends Node

@export var current_state: State
var states: Dictionary = {}

func _ready():
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.transitioned.connect(_on_child_transitioned)
			child.transitioned_with_param.connect(_on_child_transitioned_with_param)
		else:
			push_warning("State machine contains child which is not 'State'")
	print("[FSM] Entering state: ", current_state.name)
	current_state.enter()
	current_state.enter_with_params({})

func _process(delta):
	current_state.update(delta)

func _physics_process(delta):
	current_state.physics_update(delta)

func _child_transitioned(new_state_name: StringName, params: Dictionary = {}):
	var new_state = states.get(new_state_name)
	if new_state != null:
		if new_state != current_state:
			print("[FSM] Exiting state: ", current_state.name)
			current_state.exit()
			print("[FSM] Entering state: ", new_state.name)
			new_state.enter()
			new_state.enter_with_params(params)
			current_state = new_state
	else:
		push_warning("Called transition on a state that does not exist")

func _on_child_transitioned(new_state_name: StringName) -> void:
	_child_transitioned(new_state_name, {})

func _on_child_transitioned_with_param(new_state_name: StringName, params: Dictionary) -> void:
	_child_transitioned(new_state_name, params)

func _input(event) -> void:
	current_state.input(event)

# メソッドがオーバーライドされているかチェックする関数
#func is_method_overridden(instance: Object, method_name: String) -> bool:
#	var base_class = State
#	var base_instance = State.new()	
#	# 子クラスがそのメソッドを持っているか確認
#	if instance.has_method(method_name):
#		# 親クラスのメソッドと比較
#		return base_instance.callv(method_name, []) != instance.callv(method_name, [])
#	return false
