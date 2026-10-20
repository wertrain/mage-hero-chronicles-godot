class_name RelicData
extends RefCounted

## レリックはラン中ずっと所持し、装備中の数値効果を各システムから参照する。
var id: int = 0
var guid: String = ""
var name: String = ""
var description: String = ""
var detail_description: String = ""
var battle_start_shield: int = 0
var battle_victory_gold: int = 0
var treasure_choice_bonus: int = 0
## 発動タイミングと効果をデータで持ち、新しいレリックの追加で戦闘コードを増やしすぎない。
var hook_effects: Array[Dictionary] = []
