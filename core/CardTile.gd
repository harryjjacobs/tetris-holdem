extends Sprite
class_name CardTile

const SUIT = {
	"CLUBS": "Clubs",
	"DIAMONDS": "Diamonds",
	"HEARTS": "Hearts",
	"SPADES": "Spades"
}

const RANK = { 
	2: "2", 3: "3",
	4: "4", 5: "5",
	6: "6", 7: "7",
	8: "8", 9: "9",
	10: "10", 11: "J",
	12: "Q", 13: "K",
	14: "A" 
}

var suit = "CLUBS"
var rank = 2
var tile_position: Vector2

func init(_suit, _rank, sprite):
	suit = _suit;
	rank = _rank;
	texture = sprite

func equals(card):
	return suit == card.suit && \
		   rank == card.rank
