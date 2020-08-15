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

var suit = SUIT.CLUBS
var rank = RANK[2]
var tile_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func init(_suit, _rank, sprite):
	suit = _suit;
	rank = _rank;
	texture = sprite

func set_tile_position(pos):
	tile_position = pos

func get_tile_position():
	return tile_position
