extends Node2D

const PokerUtils = preload("PokerUtils.gd")

func _ready():
	$Title.visible = false

func show_category(category):
	$Title.text = PokerUtils.rank_category_friendly_name(category)
	$AnimationPlayer.play("title_entrance")
	yield($AnimationPlayer, "animation_finished")
	$AnimationPlayer.play("title_exit")
