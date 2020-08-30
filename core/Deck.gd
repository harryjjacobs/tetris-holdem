extends Node2D

const SUIT = preload("CardTile.gd").SUIT
const RANK = preload("CardTile.gd").RANK

const CARD_TILE = preload("res://core/CardTile.tscn");
const SPRITE_NAME_TEMPLATE = "res://core/sprites/cards/card%s%s.png"

onready var card_grid = $"../CardGrid"

var deck = []

# Called when the node enters the scene tree for the first time.
func _ready():
	init();

func init():
	for card in deck:
		card.queue_free();
	deck = [];
	var sprite_scale = _get_card_sprite_scale()
	for suit in SUIT:
		for rank in RANK:
			var card = CARD_TILE.instance()
			var sprite_name = SPRITE_NAME_TEMPLATE % [SUIT[suit], RANK[rank]]
			card.init(suit, rank, load(sprite_name), sprite_scale)
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
		deck.push_back(card)
	assert(deck.size() <= 52)
	deck.shuffle()

func _get_card_sprite_scale():
	# TODO: possible optimisation with preload and string constant
	var tex = load(SPRITE_NAME_TEMPLATE % ["Clubs", 2])
	var scale = card_grid.get_cell_size().x / tex.get_width()
	return Vector2(scale, scale)
