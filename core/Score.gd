extends Node2D

const SCORE_LABEL_SUFFIX = " pts"
const HIGHSCORE_LABEL_PREFIX = "highscore: "

export(float) var score_increase_animation_duration = 1.5

var score = 0

func _ready():
	reset()

func reset():
	score = 0
	_set_score_label(score)
	_read_highscore_from_gamedata()

func set_highscore(value):
	_set_highscore_label(value)

func set_score(value):
	score = value
	_set_score_label(score)

func increase(amount):
	animate_increase(score, amount)
	score += amount
	
func animate_increase(from, increase):
	$Tween.interpolate_method(self, "_set_score_label", from,
		from + increase, score_increase_animation_duration) 
	$Tween.start()

func _read_highscore_from_gamedata():
	var scores = GameData.read_high_scores()
	if !scores.empty():
		set_highscore(scores.back())

func _set_score_label(_score: int):
	$ScoreLabel.text = str(_score) + SCORE_LABEL_SUFFIX
	
func _set_highscore_label(_score: int):
	$HighScoreLabel.text = HIGHSCORE_LABEL_PREFIX + str(_score)
