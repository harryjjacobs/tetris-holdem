"""
Static class that handles cards. We represent cards as 32-bit integers, so 
there is no object instantiation - they are just ints. Most of the bits are 
used, and have a specific meaning. See below: 
								Card:
					  bitrank     suit rank   prime
				+--------+--------+--------+--------+
				|xxxbbbbb|bbbbbbbb|cdhsrrrr|xxpppppp|
				+--------+--------+--------+--------+
	1) p = prime number of rank (deuce=2,trey=3,four=5,...,ace=41)
	2) r = rank of card (deuce=0,trey=1,four=2,five=3,...,ace=12)
	3) cdhs = suit of card (bit turned on based on suit of card)
	4) b = bit turned on depending on rank of card
	5) x = unused
This representation will allow us to do very important things like:
- Make a unique prime prodcut for each hand
- Detect flushes
- Detect straights
and is also quite performant.
"""

# the basics
const STR_RANKS = '23456789TJQKA'
const INT_RANKS = 13
const PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41]
# conversion from string => int
const CHAR_RANK_TO_INT_RANK = { 
	'2': 0, '3': 1,
	'4': 2, '5': 3,
	'6': 4, '7': 5,
	'8': 6, '9': 7,
	'10': 8,'T': 8, 't': 8,
	'J': 9,'j': 9,
	'Q': 10,'q': 10,
	'K': 11,'k': 11,
	'A': 12,'a': 12
}
const CHAR_SUIT_TO_INT_SUIT = {
	's' : 1, # spades
	'S' : 1, # spades
	'h' : 2, # hearts
	'H' : 2, # hearts
	'd' : 4, # diamonds
	'D' : 4, # diamonds
	'c' : 8, # clubs
	'C' : 8, # clubs
}
const INT_SUIT_TO_CHAR_SUIT = 'xshxdxxxc'

static func from_string(card_string: String):
	"""
	# card_string: string representation of a card: e.g. 2c, as, 8d, kh
	# returns binary integer representation of card.
	See http://www.suffecool.net/poker/evaluator.html
	"""
	var rank_char = card_string[0]
	var suit_char = card_string[1]
	var rank_int = CHAR_RANK_TO_INT_RANK[rank_char]
	var suit_int = CHAR_SUIT_TO_INT_SUIT[suit_char]
	var rank_prime = PRIMES[rank_int]

	var bitrank = 1 << rank_int << 16
	var suit = suit_int << 12
	var rank = rank_int << 8

	return bitrank | suit | rank | rank_prime

static func to_str(card: int):
	var rank_int = get_rank_int(card)
	var suit_int = get_suit_int(card)
	return STR_RANKS[rank_int] + INT_SUIT_TO_CHAR_SUIT[suit_int]

static func get_rank_int(card: int):
	return (card >> 8) & 0xF

static func get_suit_int(card: int):
	return (card >> 12) & 0xF

static func get_bitrank_int(card: int):
	return (card >> 16) & 0x1FFF

static func get_prime(card: int):
	return card & 0x3F

static func prime_product_from_rankbits(rankbits):
	"""
	Returns the prime product using the bitrank (b)
	bits of the hand. Each 1 in the sequence is converted
	to the correct prime and multiplied in.
	Params:
		rankbits = a single 32-bit (only 13-bits set) integer representing 
				the ranks of 5 differently ranked cards 
				(5 of 13 bits are set)
	Primarily used for evaulating flushes and straights, 
	two occasions where we know the ranks are *ALL* different.
	Assumes that the input is in form (set bits):
							rankbits     
					+--------+--------+
					|xxxbbbbb|bbbbbbbb|
					+--------+--------+
	"""
	var product = 1
	for i in INT_RANKS:
		# if the ith bit is set
		if rankbits & (1 << i):
			product *= PRIMES[i]
	return product

static func prime_product_from_hand(card_ints):
	"""
	Expects a list of cards in integer form. 
	"""
	var product = 1
	for c in card_ints:
		product *= (c & 0xFF)
	return product
