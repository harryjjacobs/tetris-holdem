extends Node2D
class_name CardTile

enum RANK {
	TWO = 0,
	THREE = 1,
	FOUR = 2,
	FIVE = 3,
	SIX = 4,
	SEVEN = 5,
	EIGHT = 6,
	NINE = 7,
	TEN = 8,
	JACK = 9,
	QUEEN = 10,
	KING = 11,
	ACE = 12
}

enum SUIT {
	SPADES = 1,
	HEARTS = 2,
	DIAMONDS = 3,
	CLUBS = 4
}

const SUIT_TO_STRING = {
	SUIT.CLUBS: "c",
	SUIT.DIAMONDS: "d",
	SUIT.HEARTS: "h",
	SUIT.SPADES: "s"
}

const RANK_TO_STRING = { 
	RANK.TWO: "2",
	RANK.THREE: "3",
	RANK.FOUR: "4",
	RANK.FIVE: "5",
	RANK.SIX: "6",
	RANK.SEVEN: "7",
	RANK.EIGHT: "8",
	RANK.NINE: "9",
	RANK.TEN: "T",
	RANK.JACK: "J",
	RANK.QUEEN: "Q",
	RANK.KING: "K",
	RANK.ACE: "A" 
}

const STRING_TO_RANK = { 
	'2': RANK.TWO,
	'3': RANK.THREE,
	'4': RANK.FOUR,
	'5': RANK.FIVE,
	'6': RANK.SIX,
	'7': RANK.SEVEN,
	'8': RANK.EIGHT,
	'9': RANK.NINE,
	'10': RANK.TEN,
	'T': RANK.TEN,
	't': RANK.TEN,
	'J': RANK.JACK,
	'j': RANK.JACK,
	'Q': RANK.QUEEN,
	'q': RANK.QUEEN,
	'K': RANK.KING,
	'k': RANK.KING,
	'A': RANK.ACE,
	'a': RANK.ACE
}

const STRING_TO_SUIT = {
	's' : SUIT.SPADES, # spades
	'S' : SUIT.SPADES, # spades
	'h' : SUIT.HEARTS, # hearts
	'H' : SUIT.HEARTS, # hearts
	'd' : SUIT.DIAMONDS, # diamonds
	'D' : SUIT.DIAMONDS, # diamonds
	'c' : SUIT.CLUBS, # clubs
	'C' : SUIT.CLUBS, # clubs
}

export(String) var card_sprite_directory = "res://core/sprites/cards"
export(float) var tween_duration_position = 0.7
export(float) var tween_duration_exit = 0.5

var SPRITE_NAME_TEMPLATE = card_sprite_directory + "/card%s%s.png"

var suit = SUIT.CLUBS
var rank = RANK.TWO
var tile_position: Vector2

func init(_suit, _rank, _max_sprite_width = 10):
	suit = _suit;
	rank = _rank;
	print(RANK[rank])
	print(RANK_TO_STRING[RANK[rank]])
	$CardSprite.texture = load(SPRITE_NAME_TEMPLATE %
		[RANK_TO_STRING[RANK[rank]], SUIT_TO_STRING[SUIT[suit]].to_upper()])
	var scale = _max_sprite_width / $CardSprite.texture.get_width()
	$CardSprite.scale = Vector2(scale, scale)
	set_glow(false)

func set_glow(state):
	$CardSprite/Glow.visible = state

func tween_to_position(target_pos: Vector2):
	$CardSprite.position -= target_pos - position
	position = target_pos
	$Tween.interpolate_property($CardSprite, "position", $CardSprite.position,
		Vector2.ZERO, tween_duration_position, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	$Tween.start()

func animate_exit():
	var orig_tf = $CardSprite.transform
	$Tween.interpolate_property($CardSprite, "scale", $CardSprite.scale, Vector2.ZERO,
		tween_duration_exit)
	$Tween.interpolate_property($CardSprite, "rotation_degrees", 
		$CardSprite.rotation_degrees, 360, tween_duration_exit)
	$Tween.interpolate_callback(self, tween_duration_exit,
		"_reset_sprite_after_exit_tween", orig_tf)
	$Tween.start()
	
func get_size():
	return $CardSprite.texture.get_size() * $CardSprite.scale

func equals(card):
	return suit == card.suit && \
		   rank == card.rank

func to_string():
	return RANK_TO_STRING[RANK[rank]] + SUIT_TO_STRING[SUIT[suit]]

func _reset_sprite_after_exit_tween(tf):
	visible = false
	$CardSprite.transform = tf
