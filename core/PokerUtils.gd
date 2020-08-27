# Helper functions for poker
# Functions assume cards are sorted in ascending order

static func contains_royal_flush(cards, hand_out):
    pass

static func contains_straight(cards, hand_out):
    var cnt = 0
    var prev_rank = null
    for card in cards:
        if prev_rank == null:
            prev_rank = card.rank
        else:
            if card.rank != prev_rank:
                cnt = 0
                hand_out.clear()
                continue
        hand_out.push_back(card)
        cnt += 1
        if cnt == 5:
            return true
    return false

static func contains_flush(cards):
	return cards[0].suit == cards[1].suit == cards[2].suit == \
			cards[3].suit == cards[4].suit

static func is_straight(cards):
	return cards[4] - cards[0] == 1

static func is_four_of_kind(cards):
	return (cards[0].rank == cards[1].rank == cards[2].rank == cards[3].rank) || \
			(cards[1].rank == cards[2].rank == cards[3].rank == cards[4].rank)

static func contains_3_of_kind(cards):
    return (cards[0].rank == cards[1].rank == cards[2].rank) || \
            (cards[1].rank == cards[2].rank == cards[3].rank) || \
            (cards[2].rank == cards[3].rank == cards[4].rank)

static func contains_2_pair(cards):
    return ((cards[0].rank == cards[1].rank) && \
            (cards[2].rank == cards[3].rank)) || \
            ((cards[0].rank == cards[1].rank) && \
            (cards[3].rank == cards[4].rank)) || \
            ((cards[1].rank == cards[2].rank) && \
            (cards[3].rank == cards[4].rank))

static func contains_pair(cards):
    return (cards[0].rank == cards[1].rank) || \
           (cards[1].rank == cards[2].rank) || \
           (cards[2].rank == cards[3].rank) || \
           (cards[3].rank == cards[4].rank)