class_name Random
extends Node
static var _instance: Random = null
var _rng: RandomNumberGenerator

# シングルトンインスタンスを作成 (必要に応じて)
static func get_instance() -> Random:
	if Random._instance == null:
		Random._instance = Random.new()
		var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
		var root: Window = scene_tree.root
		root.add_child.call_deferred(Random._instance)
		Random._instance._init_rng()
	return Random._instance
	
# コンストラクタの代わりに初期化関数
func _init_rng():
	_rng = RandomNumberGenerator.new()

# 固定シードを設定
func set_seed(seed: int) -> void:
	_rng.seed = seed

# 現在のシードを取得
func get_seed() -> int:
	return _rng.seed

# 新しいランダムシードを設定
func randomize() -> void:
	_rng.randomize()

# 配列のシャッフル
func shuffle_array(arr: Array) -> void:
	# Fisher-Yatesアルゴリズム
	for i in range(arr.size() - 1, 0, -1):
		# ランダムにインデックスを取得
		var j = _rng.randi_range(0, i)
		# i 番目と j 番目の要素を交換
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp

# ランダム範囲の整数を取得
func randi_range(min: int, max: int) -> int:
	return _rng.randi_range(min, max)

# ランダム範囲の浮動小数点数を取得
func randf_range(min: float, max: float) -> float:
	return _rng.randf_range(min, max)
