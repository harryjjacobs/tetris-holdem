extends Node2D

const LABEL_SUFFIX = " pts"

export(float) var score_increase_animation_duration = 1.5

var score = 0

func reset():
	score = 0
	_set_score_label(score)

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
	
func _set_score_label(_score: int):
	$Label.text = str(_score) + LABEL_SUFFIX
