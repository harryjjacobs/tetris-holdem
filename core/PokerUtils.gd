# Helper functions for poker
# Functions assume cards are sorted in ascending order

enum RANK_CATEGORY {
	ROYAL_FLUSH = 0,
	STRAIGHT_FLUSH = 1,
	FOUR_OF_A_KIND = 2,
	FULL_HOUSE = 3,
	FLUSH = 4,
	STRAIGHT = 5,
	THREE_OF_A_KIND = 6,
	TWO_PAIR = 7,
	ONE_PAIR = 8,
	HIGH_CARD = 9,
}

const RANK_CATEGORY_FRIENDLY_NAME = {
	RANK_CATEGORY.ROYAL_FLUSH: "Royal Flush",
	RANK_CATEGORY.STRAIGHT_FLUSH: "Straight Flush",
	RANK_CATEGORY.FOUR_OF_A_KIND: "Four of a Kind",
	RANK_CATEGORY.FULL_HOUSE: "Full House",
	RANK_CATEGORY.FLUSH: "Flush",
	RANK_CATEGORY.STRAIGHT: "Straight",
	RANK_CATEGORY.THREE_OF_A_KIND: "Three of a Kind",
	RANK_CATEGORY.TWO_PAIR: "Two Pair",
	RANK_CATEGORY.ONE_PAIR: "One Pair",
	RANK_CATEGORY.HIGH_CARD: "High Card",
}

static func rank_category_friendly_name(category):
	return RANK_CATEGORY_FRIENDLY_NAME[category]

# The HandEval library returns the rank category, use this
# to identify which card nodes represent the winning cards
static func find_cards_from_category(cards, category):
	var _cards = [] + cards # local copy
	_cards.sort_custom(CardSorter, "sort_cards_descending")
	match category:
		RANK_CATEGORY.ONE_PAIR:
			return _find_highest_pair(_cards)
		RANK_CATEGORY.TWO_PAIR:
			var first_pair = _find_highest_pair(_cards)
			for card in first_pair:
				_cards.remove(_cards.find(card))
			return first_pair + _find_highest_pair(_cards)
		RANK_CATEGORY.THREE_OF_A_KIND:
			return _find_highest_three_of_kind(_cards)
		RANK_CATEGORY.STRAIGHT:
			return _find_highest_straight(_cards)
		RANK_CATEGORY.FLUSH:
			return _find_highest_flush(_cards)
		RANK_CATEGORY.FULL_HOUSE:
			return _find_highest_full_house(_cards)
		RANK_CATEGORY.FOUR_OF_A_KIND:
			return _find_highest_four_of_kind(_cards)
		RANK_CATEGORY.STRAIGHT_FLUSH:
			return _find_highest_straight(_cards)
		RANK_CATEGORY.ROYAL_FLUSH:
			return _find_royal_flush(_cards)
		_:
			printerr("Invalid category")

static func _find_highest_pair(cards):
	for i in range(1, cards.size()):
		if (cards[i].rank == cards[i - 1].rank):
			return [cards[i - 1], cards[i]]

static func _find_highest_two_pair(cards):
	var pairs = []
	for i in range(1, cards.size()):
		if (cards[i].rank == cards[i - 1].rank):
			pairs.push_back(cards[i - 1])
			pairs.push_back(cards[i])
			if pairs.size() == 4:
				return pairs
			i += 1

static func _find_highest_three_of_kind(cards):
	for i in range(2, cards.size()):
		if (cards[i].rank == cards[i - 1].rank) && \
			(cards[i].rank == cards[i - 2].rank):
			return [cards[i - 2], cards[i - 1], cards[i]]

static func _find_highest_straight(cards):
	for i in range(4, cards.size()):
		if (cards[i].rank - cards[i - 4].rank) == 4:
			return [cards[i - 4], cards[i - 3], 
					cards[i - 2], cards[i - 1], 
					cards[i]]

static func _find_highest_flush(cards):
	var suit_keys = CardTile.SUIT.keys()
	var counts = {
		suit_keys[0]: [],
		suit_keys[1]: [],
		suit_keys[2]: [],
		suit_keys[3]: [],
	}
	for card in cards:
		counts[card.suit].push_back(card)
		if counts[card.suit].size() == 5:
			return counts[card.suit]

static func _find_highest_full_house(cards):
	var highest_three_of_kind = _find_highest_three_of_kind(cards)
	# find highest pair that doesn't include the 3 of a kind
	for i in range(1, cards.size()):
		if (cards[i].rank != highest_three_of_kind[0].rank) && \
		   (cards[i].rank == cards[i - 1].rank):
			return highest_three_of_kind + [cards[i - 1], cards[i]]

static func _find_highest_four_of_kind(cards):
	for i in range(3, cards.size()):
		if (cards[i].rank == cards[i - 1].rank) && \
		   (cards[i].rank == cards[i - 2].rank) && \
		   (cards[i].rank == cards[i - 3].rank):
			return [cards[i - 3], cards[i - 2],
					cards[i - 1], cards[i]]

static func _find_highest_straight_flush(cards):
	var highest_rank = 0
	var straight_flush
	for suit in _separate_by_suit(cards):
		var straight = _find_highest_straight(suit)
		if straight && straight[0].rank > highest_rank:
			straight_flush = straight
			highest_rank = straight[0].rank
	return straight_flush

static func _find_royal_flush(cards):
	var straight_flush = _find_highest_straight_flush(cards)
	if straight_flush[0].rank != 14:
		printerr("Assertion that 'cards' contains a royal flush is incorrect.")
	return straight_flush

static func _separate_by_suit(cards):
	var suit_keys = CardTile.SUIT.keys()
	var hands = {
		suit_keys[0]: [],
		suit_keys[1]: [],
		suit_keys[2]: [],
		suit_keys[3]: [],
	}
	for card in cards:
		hands[card.suit].push_back(card)
	return hands

class CardSorter:
	static func sort_cards_descending(a, b):
		if a.rank > b.rank:
			return true
		return false

	static func sort_cards_ascending(a, b):
		if a.rank < b.rank:
			return true
		return false
