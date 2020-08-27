extends Node2D

const CARD_SPACING = 85
const MAX_CARDS = 5

var cards = []

func clear_cards():
	var cleared = []
	for card in cards:
		cleared.push_back(card)
		remove_child(card)
	cards = []
	return cleared

func add_card(card: CardTile):
	cards.push_back(card)
	add_child(card)
	card.set_position(Vector2(CARD_SPACING * (cards.size() - 1) - ((MAX_CARDS - 1) * CARD_SPACING) / 2.0, 0))
