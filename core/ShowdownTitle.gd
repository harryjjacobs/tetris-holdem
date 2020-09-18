extends Node2D

func _ready():
	$Title.visible = false

func show_category(category_name: String):
	$Title.text = category_name
	$AnimationPlayer.play("title_entrance")
	yield($AnimationPlayer, "animation_finished")
	$AnimationPlayer.play("title_exit")
