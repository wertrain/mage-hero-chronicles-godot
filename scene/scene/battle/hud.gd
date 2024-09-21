class_name HUD
extends CanvasLayer

func update_energy(energy: int, max_energy: int) ->void:
	$Node2D_Energy/Label_EnergyValue.text = "%d/%d" % [energy, max_energy]

func _ready() -> void:
	update_energy(3,3)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		ScreenEffect.play_pulse($Node2D_Energy)
	pass
