"""
GDScript port of https://github.com/worldveil/deuces/blob/master/deuces/evaluator.py

Evaluates hand strengths using a variant of Cactus Kev's algorithm:
http://suffe.cool/poker/evaluator.html
"""

const PokerEvalCard = preload("res://core/pokereval/PokerEvalCard.gd")
const PokerEvalLookupTable = preload("res://core/pokereval/PokerEvalLookupTable.gd")
var TENS = [
	PokerEvalCard.from_string("Tc"),
	PokerEvalCard.from_string("Td"),
	PokerEvalCard.from_string("Th"),
	PokerEvalCard.from_string("Ts")
]

var table = {}

func _init():
	table = PokerEvalLookupTable.new()

func evaluate(cards):
	var evaluation
	match cards.size():
		5: evaluation = _evaluate_five(cards)
		_: evaluation = _evaluate_many(cards)

	evaluation.cards.sort()	# ascending

	var result = { "cards": [] }
	result.category = get_rank_class(evaluation.score)
	for card_int in evaluation.cards:
		result.cards.push_back(PokerEvalCard.to_str(card_int))

	if result.category == PokerEvalLookupTable.\
		MAX_TO_RANK_CLASS[PokerEvalLookupTable.MAX_STRAIGHT_FLUSH]:
		if result.cards[0] in TENS:	# lowest card in straight card has value of 10
			result.category = 0  # royal straight flush
	return result

func _evaluate_five(cards):
	"""
	Performs an evalution given cards in integer form, mapping them to
	a rank in the range [1, 7462], with lower ranks being more powerful.
	Variant of Cactus Kev's 5 card evaluator, though I saved a lot of memory
	space using a hash table and condensing some of the calculations. 
	"""
	var result = {
		"cards": cards
	}
	# if flush
	if cards[0] & cards[1] & cards[2] & cards[3] & cards[4] & 0xF000:
		var handOR = (cards[0] | cards[1] | cards[2] | cards[3] | cards[4]) >> 16
		var prime = PokerEvalCard.prime_product_from_rankbits(handOR)
		result.score = table.flush_lookup[prime]
	# otherwise
	else:
		var prime = PokerEvalCard.prime_product_from_hand(cards)
		# for some reason dictionary lookup is broken so I have to
		# do it like this. TODO: submit a bug report to godot
		var idx = table.unsuited_lookup.keys().find(prime)
		result.score = table.unsuited_lookup.values()[idx]

	return result

func _evaluate_many(cards):
	"""
	Performs five_card_eval() on all subsets of 5 cards
	in the specified set to determine the best ranking, 
	and returns this ranking.
	"""
	var minimum = PokerEvalLookupTable.MAX_HIGH_CARD
	var result
	var all5cardcombos = _combinations(cards, 5)
	for combo in all5cardcombos:
		var _result = self._evaluate_five(combo)
		if _result.score < minimum:
			minimum = _result.score
			result = _result
	return result

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

static func _combinations(s, m):
	if m == 1:
		var res = []
		for a in s:
			res.push_back([a])
		return res
	if m == s.size():
		return [s]
	var res = []
	for a in _combinations(s.slice(1, s.size() - 1), m - 1):
		res.push_back(s.slice(0, 0) + a)
	return res + _combinations(s.slice(1, s.size() - 1), m)
