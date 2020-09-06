"""
GDScript port of https://github.com/worldveil/deuces/blob/master/deuces/evaluator.py

Evaluates hand strengths using a variant of Cactus Kev's algorithm:
http://suffe.cool/poker/evaluator.html
"""

const PokerEvalCard = preload("res://core/pokereval/PokerEvalCard.gd")
const PokerEvalLookupTable = preload("res://core/pokereval/PokerEvalLookupTable.gd")

var table = {}
var hand_size_map = {
	5 : funcref(self, "_evaluate_five"),
	6 : funcref(self, "_evaluate_six"),
	7 : funcref(self, "_evaluate_seven")
}

func _init():
	table = PokerEvalLookupTable.new()

func evaluate(cards):
	return hand_size_map[cards.size()].call_func(cards)

func _evaluate_five(cards):
	"""
	Performs an evalution given cards in integer form, mapping them to
	a rank in the range [1, 7462], with lower ranks being more powerful.
	Variant of Cactus Kev's 5 card evaluator, though I saved a lot of memory
	space using a hash table and condensing some of the calculations. 
	"""
	# if flush
	if cards[0] & cards[1] & cards[2] & cards[3] & cards[4] & 0xF000:
		var handOR = (cards[0] | cards[1] | cards[2] | cards[3] | cards[4]) >> 16
		var prime = PokerEvalCard.prime_product_from_rankbits(handOR)
		return table.flush_lookup[prime]

	# otherwise
	else:
		var prime = PokerEvalCard.prime_product_from_hand(cards)
		return table.unsuited_lookup[prime]

func _evaluate_six(cards):
	"""
	Performs five_card_eval() on all (6 choose 5) = 6 subsets
	of 5 cards in the set of 6 to determine the best ranking, 
	and returns this ranking.
	"""
	var minimum = PokerEvalLookupTable.MAX_HIGH_CARD

	var all5cardcombobs = combinations(cards, 5)
	for combo in all5cardcombobs:
		var score = _evaluate_five(combo)
		if score < minimum:
			minimum = score

	return minimum

func _evaluate_seven(cards):
	"""
	Performs five_card_eval() on all (7 choose 5) = 21 subsets
	of 5 cards in the set of 7 to determine the best ranking, 
	and returns this ranking.
	"""
	var minimum = PokerEvalLookupTable.MAX_HIGH_CARD

	var all5cardcombobs = combinations(cards, 5)
	for combo in all5cardcombobs:
		var score = self._evaluate_five(combo)
		if score < minimum:
			minimum = score

	return minimum

func get_rank_class(hr):
	"""
	Returns the class of hand given the hand hand_rank
	returned from evaluate. 
	"""
	if hr >= 0 and hr <= PokerEvalLookupTable.MAX_STRAIGHT_FLUSH:
		return PokerEvalLookupTable.MAX_TO_RANK_CLASS[PokerEvalLookupTable.MAX_STRAIGHT_FLUSH]
	elif hr <= PokerEvalLookupTable.MAX_FOUR_OF_A_KIND:
		return PokerEvalLookupTable.MAX_TO_RANK_CLASS[PokerEvalLookupTable.MAX_FOUR_OF_A_KIND]
	elif hr <= PokerEvalLookupTable.MAX_FULL_HOUSE:
		return PokerEvalLookupTable.MAX_TO_RANK_CLASS[PokerEvalLookupTable.MAX_FULL_HOUSE]
	elif hr <= PokerEvalLookupTable.MAX_FLUSH:
		return PokerEvalLookupTable.MAX_TO_RANK_CLASS[PokerEvalLookupTable.MAX_FLUSH]
	elif hr <= PokerEvalLookupTable.MAX_STRAIGHT:
		return PokerEvalLookupTable.MAX_TO_RANK_CLASS[PokerEvalLookupTable.MAX_STRAIGHT]
	elif hr <= PokerEvalLookupTable.MAX_THREE_OF_A_KIND:
		return PokerEvalLookupTable.MAX_TO_RANK_CLASS[PokerEvalLookupTable.MAX_THREE_OF_A_KIND]
	elif hr <= PokerEvalLookupTable.MAX_TWO_PAIR:
		return PokerEvalLookupTable.MAX_TO_RANK_CLASS[PokerEvalLookupTable.MAX_TWO_PAIR]
	elif hr <= PokerEvalLookupTable.MAX_PAIR:
		return PokerEvalLookupTable.MAX_TO_RANK_CLASS[PokerEvalLookupTable.MAX_PAIR]
	elif hr <= PokerEvalLookupTable.MAX_HIGH_CARD:
		return PokerEvalLookupTable.MAX_TO_RANK_CLASS[PokerEvalLookupTable.MAX_HIGH_CARD]
	else:
		printerr("Invalid hand rank, cannot return rank class.")

static func combinations(s, m):
	if m == 1:
		var res = []
		for a in s:
			res.push_back([a])
		return res
	if m == s.size():
		return [s]
	var res = []
	for a in combinations(s.slice(1, s.size() - 1), m - 1):
		res.push_back(s.slice(0, 0) + a)
	return res + combinations(s.slice(1, s.size() - 1), m)
