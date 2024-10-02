# Json で定義される敵の行動パターンの格納先
class_name EnemyBattleAciton
extends EnemyBattleAcitonBase

# 複数ターンにわたる攻撃
var _steps: Array[EnemyBattleAcitonStep] = []
# アクションの発生確率
var _frequency: float
# アクションの発生条件
var _conditions: Array[EnemyBattleAcitonCondition] = []
# アクションの発動回数上限
var _limit: int
