class_name BitFlags
extends Object

static func add_flag(value: int, flag: int) -> int:
	return value | flag  # OR演算でフラグを立てる

static func remove_flag(value: int, flag: int) -> int:
	return value & ~flag  # AND演算とNOTでフラグを消す

static func has_flag(value: int, flag: int) -> bool:
	return (value & flag) != 0  # AND演算でフラグをチェック

static func has_any_flags(value: int, flags: int) -> bool:
	return (value & flags) != 0  # 複数のフラグをORで結合してチェック
