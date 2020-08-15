extends Node2D

const SUIT = preload("CardTile.gd").SUIT
const RANK = preload("CardTile.gd").RANK

const CARD_TILE = preload("res://CardTile.tscn");
const SPRITE_NAME_TEMPLATE = "res://sprites/cards/card%s%s.png"

var deck = []

# Called when the node enters the scene tree for the first time.
func _ready():
	init();

func init():
	for card in deck:
		card.queue_free();
	deck = [];
	for suit in SUIT:
		for rank in RANK:
			var card = CARD_TILE.instance()
			var sprite_name = SPRITE_NAME_TEMPLATE % [SUIT[suit], RANK[rank]]
			card.init(suit, rank, load(sprite_name))
			card.visible = false
			deck.push_back(card)
	assert(deck.size() == 52)
	deck.shuffle()
	
func get_next_card():
	var card = deck.pop_back()
	if card != null:
		card.visible = true
	print_debug(card)
	return card

func return_cards(cards):
	for card in cards:
		deck.push_back(card)
	assert(deck.size() <= 52)
	deck.shuffle()
