extends Node2D

const CARD_TILE = preload("CardTile.tscn");
const SUIT = preload("CardTile.gd").SUIT
const RANK = preload("CardTile.gd").RANK

onready var card_grid = $"../CardGrid"

var deck = []

# Called when the node enters the scene tree for the first time.
func _ready():
	init();

func init():
	for card in deck:
		card.queue_free();
	deck = [];
	var card_width = _get_max_card_width()
	for suit in SUIT:
		for rank in RANK:
			var card = CARD_TILE.instance()
			card.init(suit, rank, card_width)
			card.visible = false
			add_child(card)
			deck.push_back(card)
	assert(deck.size() == 52)
	deck.shuffle()
	
func get_next_card():
	var card = deck.pop_back()
	if card != null:
		card.visible = true
		card.position = Vector2.ZERO
	return card

func return_cards(cards):
	for card in cards:
		if card.get_parent():
			card.get_parent().remove_child(card)
		add_child(card)
		card.visible = false
		card.position = Vector2.ZERO
		deck.push_back(card)
	assert(deck.size() <= 52)
	deck.shuffle()

func _get_max_card_width():
	return card_grid.get_cell_size().x
