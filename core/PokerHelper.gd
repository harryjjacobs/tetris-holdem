# singleton class for managing poker gameplay

extends Node

const PokerEvalCard = preload("./pokereval/PokerEvalCard.gd")
const PokerEvalLookupTable = preload("./pokereval/PokerEvalLookupTable.gd")
const PokerEvalEvaluator = preload("./pokereval/PokerEvalEvaluator.gd")

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
	if !_read_tables_from_userdata():
		print("Failed to read poker lookup tables from userdata. Generating tables.")
		var table = PokerEvalLookupTable.new()
		_write_tables_to_userdata(table)
		_read_tables_from_userdata()

func find_winning_hand(community_cards, card_grid):
	# TODO: performance timer
	var grid_card_combos = _find_grid_combos(card_grid)
	print("Found ", grid_card_combos.size(), " combos in the grid")
	var best_rank = MAX_RANK
	var best_hand
	for combo in grid_card_combos:
		print("Evaluating combo ",
			card_array_to_string_array(combo),
			" + community cards ",
			card_array_to_string_array(community_cards))
		var result = _evaluate_combo(card_grid, community_cards, combo)
		if result.rank <= best_rank:	# lower is better
			best_hand = result
			best_rank = result.rank
	print("Calculated best hand combination:")
	print(rank_category_friendly_name(best_hand.category))
	print("Hand: ", 
		card_array_to_string_array(best_hand.cards))
	return best_hand

func _evaluate_combo(card_grid, community_cards, combo_cards):
	var full_hand = [] + community_cards + combo_cards
	var results = _evaluate_many(full_hand)
	var best_rank = MAX_RANK	# max rank is worst rank
	var best_result
	for result in results:
		var cards = []
		var grid_cards = []
		for card_str in result.cards:
			var card = find_card_by_string(full_hand, card_str)
			cards.push_back(card)
			if card in combo_cards:
				grid_cards.push_back(card)
		result.cards = cards
		# check if grid combo cards used for this evaluation
		# combination are connected with no separations,
		# in a group in the grid
		if !_are_grid_cards_in_group(card_grid, grid_cards):
			continue
		if result.rank <= best_rank:	# lower rank is better
			best_result = result
			best_rank = result.rank
	print("Highest rank: ", best_result.rank, " (", 
		rank_category_friendly_name(best_result.category), ")")
	return best_result

# checks whether the cards are in one group
# block in the card grid with no separation
func _are_grid_cards_in_group(card_grid, cards):
	var neighbour_sum = 0;
	var MIN_SUM = cards.size() * 2 - 2
	for combo_card in cards:
		var neighbours = card_grid.get_neighbours(combo_card)
		for neighbour in neighbours:
			if neighbour in cards:
				neighbour_sum += 1
	return neighbour_sum >= MIN_SUM

# finds all combinations of connected cards (up to and incl. size 5)
func _find_grid_combos(card_grid):
	var combos = []
	for card in card_grid.get_cards():
		combos += _card_grid_find_all_subsets(card_grid, card, 5)
	return combos

func _card_grid_find_all_subsets(card_grid, card: CardTile, max_size: int = 5):
	# performs a variation on Breadth First Search to find all subsets
	# with specified maximum size
	var subsets = [[]]
	var queue = []
	var discovered = {card.to_string(): card}
	queue.push_back(card)
	while !queue.empty():
		var current = queue.pop_front()
		subsets[-1].push_back(current)
		if subsets[-1].size() == max_size:
			subsets.push_back([])
		for neighbour in card_grid.get_neighbours(current):
			var card_str = neighbour.to_string()
			if !discovered.has(card_str):
				discovered[card_str] = neighbour
				queue.push_back(neighbour)
	return subsets

func _evaluate(cards: Array):
	var pokereval_cards = cardtile_array_to_pokereval_array(cards)
	return evaluator.evaluate(pokereval_cards)

# returns evaluations for all combinations of cards choose 5
func _evaluate_many(cards: Array):
	var pokereval_cards = cardtile_array_to_pokereval_array(cards)
	return evaluator.evaluate_many(pokereval_cards)

func _write_tables_to_userdata(table: PokerEvalLookupTable):
	GameData.write_lookup_tables(table.unsuited_lookup, table.flush_lookup)

	print("Poker table lookup files written to user data.")

func _read_tables_from_userdata():
	var tables = GameData.read_lookup_tables()

	if !tables:
		return false

	if tables.flush_lookup.size() != 1287 || \
		tables.unsuited_lookup.size() != 6175:
		return false

	print("Poker table lookup files read from user data.")

	var table = PokerEvalLookupTable.new(tables.flush_lookup, tables.unsuited_lookup)
	evaluator = PokerEvalEvaluator.new(table)

	return true

# ========== static helper functions ==========

static func rank_category_friendly_name(category):
	return RANK_CATEGORY_FRIENDLY_NAME[category]

static func card_array_to_string_array(cards: Array):
	var card_strs = []
	for card in cards:
		card_strs.push_back(card.to_string())
	return card_strs

static func cardtile_array_to_pokereval_array(cards: Array):
	var pokereval_hand = []
	for card in cards:
		pokereval_hand.push_back(PokerEvalCard.from_string(card.to_string()))
	return pokereval_hand

# find card in array of cards by string representation
static func find_card_by_string(cards, card_str):
	for card in cards:
		if card.to_string().to_lower() == card_str.to_lower():
			return card
