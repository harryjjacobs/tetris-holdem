extends Node2D

const TreeUtils = preload("TreeUtils.gd")
export(float) var card_spacing = 85.0
export(int) var max_cards = 5

var cards = []

func clear_cards():
	var cleared = []
	for card in cards:
		remove_card(card)
		cleared.push_back(card)
	cards = []
	return cleared

func add_card(card: CardTile):
	cards.push_back(card)
	TreeUtils.change_parent_preserve_global_position(card, self)
	var new_pos = Vector2(card_spacing * (cards.size() - 1) - ((max_cards - 1) * card_spacing) / 2.0, 0)
	card.tween_to_position(new_pos)

func remove_card(card: CardTile):
	cards.remove(cards.find(card))
	TreeUtils.change_parent_preserve_global_position(card, get_tree().get_root())
