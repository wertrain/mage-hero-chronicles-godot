extends Node

# 揺れの強さ
@export var noise_shake_strength: float = 20.0
# 揺れの減衰値
# 小さいほど減衰が少ないので、揺れが長く続く
# 0 にするとずっと揺れる
@export var noise_shake_decay: float = 6.0
# 揺れのスピード
@export var noise_shake_speed: float = 15.0
# 揺れのきめ細かさ
# 小さいほどスムーズに、大きいほどラフになる
@export var noise_frequency: float = 1.0
# シェイクするターゲット
@export var target : Node2D
# ノイズを作成するシード
@export var random_seed: int = "Shake2d".hash()

@onready var rand := RandomNumberGenerator.new()
@onready var noise := FastNoiseLite.new()

var noise_i: float = 0.0
var shake_strength: float = 0.0

func _ready() -> void:
	#rand.randomize()
	#noise.seed = rand.randi()
	noise.seed = random_seed
	noise.frequency = noise_frequency
 
func play_shake() -> void:
	shake_strength = noise_shake_strength
	
func _process(delta: float) -> void:
	shake_strength = lerp(shake_strength, 0.0, noise_shake_decay * delta)
	target.offset = get_noise_offset(delta)

func get_noise_offset(delta: float) -> Vector2:
	noise_i += noise_shake_speed * delta
	return Vector2(
		noise.get_noise_2d(1, noise_i) * shake_strength,
		noise.get_noise_2d(100, noise_i) * shake_strength
	)
