# Singleton class containing helper functions for poker evaluation and card utilities

extends Node

const PokerEvalCard = preload("./pokereval/PokerEvalCard.gd")
const PokerEvalLookupTable = preload("./pokereval/PokerEvalLookupTable.gd")
const PokerEvalEvaluator = preload("./pokereval/PokerEvalEvaluator.gd")

const UNSUITED_LOOKUP_FILE = "user://unsuited_lookup.csv"
const FLUSH_LOOKUP_FILE = "user://flush_lookup.csv"

const MAX_RANK = PokerEvalLookupTable.MAX_HIGH_CARD

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

var evaluator

func _init():
	if !read_tables_from_userdata():
		var table = PokerEvalLookupTable.new()
		evaluator = PokerEvalEvaluator.new(table)
		write_tables_to_userdata(table)

func rank_category_friendly_name(category):
	return RANK_CATEGORY_FRIENDLY_NAME[category]

func evaluate(cards: Array):
	var pokereval_cards = cardtile_array_to_pokereval_array(cards)
	return evaluator.evaluate(pokereval_cards)

# returns evaluations for all combinations of cards choose 5
func evaluate_many(cards: Array):
	var pokereval_cards = cardtile_array_to_pokereval_array(cards)
	return evaluator.evaluate_many(pokereval_cards)

func card_array_to_string_array(cards: Array):
	var card_strs = []
	for card in cards:
		card_strs.push_back(card.to_string())
	return card_strs

func cardtile_array_to_pokereval_array(cards: Array):
	var pokereval_hand = []
	for card in cards:
		pokereval_hand.push_back(PokerEvalCard.from_string(card.to_string()))
	return pokereval_hand

# find card in array of cards by string representation
func find_card_by_string(cards, card_str):
	for card in cards:
		if card.to_string().to_lower() == card_str.to_lower():
			return card

func write_tables_to_userdata(table: PokerEvalLookupTable):
	var file = File.new()

	file.open(UNSUITED_LOOKUP_FILE, File.WRITE)
	for key in table.unsuited_lookup:
		file.store_csv_line([str(key), str(table.unsuited_lookup[key])])
	file.close()

	file.open(FLUSH_LOOKUP_FILE, File.WRITE)
	for key in table.flush_lookup:
		file.store_csv_line([str(key), str(table.flush_lookup[key])])
	file.close()
	
	print("Table lookup files written to user data")

func read_tables_from_userdata():
	var file = File.new()
	var unsuited_lookup = {}
	var flush_lookup = {}

	if !file.file_exists(UNSUITED_LOOKUP_FILE):
		return false

	file.open(UNSUITED_LOOKUP_FILE, File.READ)
	while !file.eof_reached():
		var values = file.get_csv_line()
		if values.size() == 2:
			unsuited_lookup[int(values[0])] = int(values[1])
	file.close()

	if !file.file_exists(FLUSH_LOOKUP_FILE):
		return false

	file.open(FLUSH_LOOKUP_FILE, File.READ)
	while !file.eof_reached():
		var values = file.get_csv_line()
		if values.size() == 2:
			flush_lookup[int(values[0])] = int(values[1])
	file.close()

	print("Table lookup files written to user data")
	var table = PokerEvalLookupTable.new(flush_lookup, unsuited_lookup)
	evaluator = PokerEvalEvaluator.new(table)

	print(flush_lookup.size())

	return flush_lookup.size() == 1287 && \
			unsuited_lookup.size() == 6175

class CardSorter:
	static func sort_cards_descending(a, b):
		if a.rank > b.rank:
			return true
		return false

	static func sort_cards_ascending(a, b):
		if a.rank < b.rank:
			return true
		return false
