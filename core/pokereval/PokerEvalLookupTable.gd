"""
Number of Distinct Hand Values:
Straight Flush   10 
Four of a Kind   156      [(13 choose 2) * (2 choose 1)]
Full Houses      156      [(13 choose 2) * (2 choose 1)]
Flush            1277     [(13 choose 5) - 10 straight flushes]
Straight         10 
Three of a Kind  858      [(13 choose 3) * (3 choose 1)]
Two Pair         858      [(13 choose 3) * (3 choose 2)]
One Pair         2860     [(13 choose 4) * (4 choose 1)]
High Card      + 1277     [(13 choose 5) - 10 straights]
-------------------------
TOTAL            7462
Here we create a lookup table which maps:
	5 card hand's unique prime product => rank in range [1, 7462]
Examples:
* Royal flush (best hand possible)          => 1
* 7-5-4-3-2 unsuited (worst hand possible)  => 7462
"""

const PokerEvalCard = preload("res://core/pokereval/PokerEvalCard.gd")
var PokerEvalEvaluator = load("res://core/pokereval/PokerEvalEvaluator.gd")

const MAX_STRAIGHT_FLUSH  = 10
const MAX_FOUR_OF_A_KIND  = 166
const MAX_FULL_HOUSE      = 322 
const MAX_FLUSH           = 1599
const MAX_STRAIGHT        = 1609
const MAX_THREE_OF_A_KIND = 2467
const MAX_TWO_PAIR        = 3325
const MAX_PAIR            = 6185
const MAX_HIGH_CARD       = 7462

const MAX_TO_RANK_CLASS = {
	MAX_STRAIGHT_FLUSH: 1,
	MAX_FOUR_OF_A_KIND: 2,
	MAX_FULL_HOUSE: 3,
	MAX_FLUSH: 4,
	MAX_STRAIGHT: 5,
	MAX_THREE_OF_A_KIND: 6,
	MAX_TWO_PAIR: 7,
	MAX_PAIR: 8,
	MAX_HIGH_CARD: 9
}

const RANK_CLASS_TO_STRING = {
	0 : "Royal Flush",
	1 : "Straight Flush",
	2 : "Four of a Kind",
	3 : "Full House",
	4 : "Flush",
	5 : "Straight",
	6 : "Three of a Kind",
	7 : "Two Pair",
	8 : "Pair",
	9 : "High Card"
}

var flush_lookup = {}
var unsuited_lookup = {}

func _init():
	# create the lookup table in piecewise fashion
	flushes()  # this will call straights and high cards method,
	# we reuse some of the bit sequences
	multiples()

func flushes():
	"""
	Straight flushes and flushes. 
	Lookup is done on 13 bit integer (2^13 > 7462):
	xxxbbbbb bbbbbbbb => integer hand index
	"""
	# straight flushes in rank order
	var straight_flushes = [
		7936, # int('0b1111100000000', 2), # royal flush
		3968, # int('0b111110000000', 2),
		1984, # int('0b11111000000', 2),
		992, # int('0b1111100000', 2),
		496, # int('0b111110000', 2),
		248, # int('0b11111000', 2),
		124, # int('0b1111100', 2),
		62, # int('0b111110', 2),
		31, # int('0b11111', 2),
		4111 # int('0b1000000001111', 2) # 5 high
	]

	# now we'll dynamically generate all the other
	# flushes (including straight flushes)
	var flushes = []
	var gen = LexicographicBitPermutation.new(0b11111)

	# 1277 = number of high cards
	# 1277 + len(str_flushes) is number of hands with all cards unique rank
	for _i in range(1277 + straight_flushes.size() - 1): # we also iterate over SFs
		# pull the next flush pattern from our generator
		var f = gen.next()

		# if this flush matches perfectly any
		# straight flush, do not add it
		var notSF = true
		for sf in straight_flushes:
			# if f XOR sf == 0, then bit pattern 
			# is same, and we should not add
			if not f ^ sf:
				notSF = false

		if notSF:
			flushes.append(f)

	# we started from the lowest straight pattern, now we want to start ranking from
	# the most powerful hands, so we reverse
	flushes.invert()

	# now add to the lookup map:
	# start with straight flushes and the rank of 1
	# since theyit is the best hand in poker
	# rank 1 = Royal Flush!
	var rank = 1
	for sf in straight_flushes:
		var prime_product = PokerEvalCard.prime_product_from_rankbits(sf)
		flush_lookup[prime_product] = rank
		rank += 1

	# we start the counting for flushes on max full house, which
	# is the worst rank that a full house can have (2,2,2,3,3)
	rank = MAX_FULL_HOUSE + 1
	for f in flushes:
		var prime_product = PokerEvalCard.prime_product_from_rankbits(f)
		flush_lookup[prime_product] = rank
		rank += 1

	# we can reuse these bit sequences for straights
	# and high cards since they are inherently related
	# and differ only by context 
	straight_and_highcards(straight_flushes, flushes)

func straight_and_highcards(straights, highcards):
	"""
	Unique five card sets. Straights and highcards. 
	Reuses bit sequences from flush calculations.
	"""
	var rank = MAX_FLUSH + 1
	for s in straights:
		var prime_product = PokerEvalCard.prime_product_from_rankbits(s)
		unsuited_lookup[prime_product] = rank
		rank += 1

	rank = MAX_PAIR + 1
	for h in highcards:
		var prime_product = PokerEvalCard.prime_product_from_rankbits(h)
		unsuited_lookup[prime_product] = rank
		rank += 1

func multiples():
	"""
	Pair, Two Pair, Three of a Kind, Full House, and 4 of a Kind.
	"""
	var backwards_ranks = []
	
	for i in range(PokerEvalCard.INT_RANKS - 1, -1, -1):
		backwards_ranks.push_back(i)

	# 1) Four of a Kind
	var rank = MAX_STRAIGHT_FLUSH + 1

	# for each choice of a set of four rank
	for i in backwards_ranks:
		# and for each possible kicker rank
		var kickers = [] + backwards_ranks
		kickers.remove(kickers.find(i))
		for k in kickers:
			var product = pow(PokerEvalCard.PRIMES[i], 4) * PokerEvalCard.PRIMES[k]
			unsuited_lookup[product] = rank
			rank += 1
	
	# 2) Full House
	rank = MAX_FOUR_OF_A_KIND + 1

	# for each three of a kind
	for i in backwards_ranks:
		# and for each choice of pair rank
		var pairranks = [] + backwards_ranks
		pairranks.remove(pairranks.find(i))
		for pr in pairranks:
			var product = pow(PokerEvalCard.PRIMES[i], 3) * pow(PokerEvalCard.PRIMES[pr], 2)
			unsuited_lookup[product] = rank
			rank += 1

	# 3) Three of a Kind
	rank = MAX_STRAIGHT + 1

	# pick three of one rank
	for r in backwards_ranks:
		var kickers = [] + backwards_ranks
		kickers.remove(kickers.find(r))
		var gen = PokerEvalEvaluator._combinations(kickers, 2)
		for kckrs in gen:
			var c1 = kckrs[0]
			var c2 = kckrs[1]
			var product = pow(PokerEvalCard.PRIMES[r], 3) * PokerEvalCard.PRIMES[c1] * PokerEvalCard.PRIMES[c2]
			unsuited_lookup[product] = rank
			rank += 1

	# 4) Two Pair
	rank = MAX_THREE_OF_A_KIND + 1

	var tpgen = PokerEvalEvaluator._combinations(backwards_ranks, 2)
	for tp in tpgen:
		var pair1 = tp[0]
		var pair2 = tp[1]
		var kickers = [] + backwards_ranks
		kickers.remove(kickers.find(pair1))
		kickers.remove(kickers.find(pair2))
		for kicker in kickers:
			var product = pow(PokerEvalCard.PRIMES[pair1], 2) * \
				pow(PokerEvalCard.PRIMES[pair2], 2) * \
				PokerEvalCard.PRIMES[kicker]
			unsuited_lookup[product] = rank
			rank += 1

	# 5) Pair
	rank = MAX_TWO_PAIR + 1

	# choose a pair
	for pairrank in backwards_ranks:
		var kickers = [] + backwards_ranks
		kickers.remove(kickers.find(pairrank))
		var kgen = PokerEvalEvaluator._combinations(kickers, 3)
		for kckrs in kgen:
			var k1 = kckrs[0]
			var k2 = kckrs[1]
			var k3 = kckrs[2]
			var product = pow(PokerEvalCard.PRIMES[pairrank], 2) * \
				PokerEvalCard.PRIMES[k1] * PokerEvalCard.PRIMES[k2] * \
				PokerEvalCard.PRIMES[k3]
			unsuited_lookup[product] = rank
			rank += 1

#func write_table_to_disk(self, table, filepath):
#	"""
#	Writes lookup table to disk
#	"""
#	with open(filepath, 'w') as f:
#		for prime_prod, rank in table.iteritems():
#			f.write(str(prime_prod) +","+ str(rank) + '\n')

class LexicographicBitPermutation:
	var v: int

	func _init(n: int):
		v = n

	func reset(n: int):
		v = n

	func next():
		var t = (v | (v - 1)) + 1
		v = t | ((((t & -t) / (v & -v)) >> 1) - 1)
		return v
