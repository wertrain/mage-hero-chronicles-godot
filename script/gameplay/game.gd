class_name Game

enum GameState {
	MENU,
	BATTLE
}

var current_state: GameState = GameState.MENU
var player_score: int = 0
var player_gold: int = 0
var current_level: int = 1
