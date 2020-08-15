extends Control

const CARD_SPACING = 0.2

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
	print_debug(card)
	card.set_position(Vector2(CARD_SPACING * cards.size(), 0))
