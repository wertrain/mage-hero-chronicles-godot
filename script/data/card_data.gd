class_name CardData
extends RefCounted

## data/card.json の1定義を表す。デッキにはこのオブジェクトをカード1枚ごとに保持する。
var id: int = 0
var guid: String
## 通常カードだけが持つ。強化先のGUIDを空にすると、それ以上強化できないカードになる。
var upgrade_guid: String = ""
var name: String
var description: String
var detail_description: String
var cost: int = 0
var actions: Array[BattleAciton] = []
var rarity: int = 0
