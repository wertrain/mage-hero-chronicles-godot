class_name CardData
extends RefCounted

## data/card.json の1定義を表す。デッキにはこのオブジェクトをカード1枚ごとに保持する。
var id: int = 0
var guid: String
## 報酬カードを職業ごとに抽選するための識別子。既存データは戦士扱いにする。
var job: String = "warrior"
## 通常カードだけが持つ。強化先のGUIDを空にすると、それ以上強化できないカードになる。
var upgrade_guid: String = ""
var name: String
var description: String
var detail_description: String
## カード中央に表示するイラスト。空文字なら従来どおり背景だけ表示する。
var art_path: String = ""
var cost: int = 0
var actions: Array[BattleAciton] = []
var rarity: int = 0
## 戦闘中のカード連携判定に使うタグ。表示名を条件にせず、翻訳を変えても効果を保つ。
var tags: Array[String] = []
