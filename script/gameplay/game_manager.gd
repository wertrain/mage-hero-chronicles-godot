class_name GameManager

static var games: Array[Game]

static func get_game(index: int = 0) -> Game:
	return games[index]
