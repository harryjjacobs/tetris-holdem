extends Node2D

enum GameState { PLAYING, PAUSED, OVER, STOPPED }

var _game_state = GameState.STOPPED

const PokerEvalCard = preload("./pokereval/PokerEvalCard.gd")
var PokerEvalEvaluator = preload("./pokereval/PokerEvalEvaluator.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	GameData.write_high_score(10)
	var _err = $Board.connect("on_game_over", self, "_on_game_over")
	_start()

func _process(_delta):
	match _game_state:
		GameState.PLAYING:
			$Board.game_loop()
		GameState.PAUSED:
			pass
			# Show pause screen 
		GameState.OVER:
			pass
			# Show game over screen
		GameState.STOPPED:
			pass
			# Show main menu screen

func _start():
	$Board.init()
	_game_state = GameState.PLAYING

func _on_game_over(score):
	print("GAME OVER")
	_game_state = GameState.OVER
	# do game over things
	# write highscore to file
	GameData.write_high_score(score)
