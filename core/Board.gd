extends Node2D

const PokerStages = { 
	"PREFLOP": {
		"DESCEND": 2,
		"COMMUNITY": 0,
	},
	"FLOP": {
		"DESCEND": 1,
		"COMMUNITY": 3,
	},
	"TURN": {
		"DESCEND": 1,
		"COMMUNITY": 1,
	},
	"RIVER": {
		"DESCEND": 1,
		"COMMUNITY": 1,
	}
}

export(float) var community_deal_duration = 2.0

signal on_game_over

var _poker_state = {
	"stage": PokerStages.PREFLOP,
	"descent_count": 0,
	"community_cards": null
}

var _community_cards
var _descending_card_tile

func init():
	_poker_state.stage = PokerStages.PREFLOP
	print_debug(_poker_state)
	$Deck.init()

func _process(_delta):
	if $MovementStepTimer.do_step:
		if Input.is_action_pressed("move_left"):
			_move_card_left()
		elif Input.is_action_pressed("move_right"):
			_move_card_right()
		elif Input.is_action_pressed("move_down"):
			_move_card_down()

func game_loop():
	if _is_poker_stage_finished():
		match _poker_state.stage:
			PokerStages.PREFLOP:
				_poker_state.stage = PokerStages.FLOP
				_add_community_cards(PokerStages.FLOP)
			PokerStages.FLOP:
				_poker_state.stage = PokerStages.TURN
				_add_community_cards(PokerStages.TURN)
			PokerStages.TURN:
				_poker_state.stage = PokerStages.RIVER
				_add_community_cards(PokerStages.RIVER)
			PokerStages.RIVER:
				_poker_state.stage = PokerStages.PREFLOP
				_showdown()
		_poker_state.descent_count = 0
		$DescentStepTimer.pause(community_deal_duration)
	if $DescentStepTimer.do_step:
		if _descending_card_tile:
			_move_card_down()
		else:
			_begin_descent($Deck.get_next_card())

func _showdown():
	# TODO: showdown
	var scoring_pairs = _find_scoring_pairs()

	$Deck.return_cards($Community.clear_cards())

func _begin_descent(_card_tile):
	_descending_card_tile = _card_tile
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var start_pos = Vector2(rng.randi_range(0, $CardGrid.grid_cols - 1), 0)
	if !$CardGrid.is_cell_free(start_pos):
		emit_signal("on_game_over")
	else:
		$CardGrid.set_card_at(_descending_card_tile, start_pos)

func _end_descent():
	$CardGrid.set_card_at(_descending_card_tile, _descending_card_tile.tile_position)
	_descending_card_tile = null
	_poker_state.descent_count += 1

func _move_card_down():
	if _descending_card_tile == null:
		return
	if !_translate_card_tile(Vector2(0, 1)):
		_end_descent()

func _move_card_left():
	_translate_card_tile(Vector2(-1, 0))

func _move_card_right():
	_translate_card_tile(Vector2(1, 0))

func _translate_card_tile(pos):
	if _descending_card_tile == null:
		return false
	var new_pos = _descending_card_tile.tile_position + pos
	if !$CardGrid.is_cell_free(new_pos):
			return false
	$CardGrid.move_card(_descending_card_tile, new_pos)
	print_debug(_descending_card_tile.position)
	return true

func _add_community_cards(poker_stage):
	for _i in range(0, poker_stage.COMMUNITY):
		$Community.add_card($Deck.get_next_card())

func _clear_community_cards():
	var cleared = $Community.clear_cards()
	$Deck.return_cards(cleared)

func _is_poker_stage_finished():
	return _poker_state.descent_count >= _poker_state.stage.DESCEND

const SUIT = preload("CardTile.gd").SUIT
const RANK = preload("CardTile.gd").RANK
const PokerUtils = preload("PokerUtils.gd")
enum HandType {
	NONE, HIGH_CARD, PAIR, TWO_PAIR,
	THREE_OF_KIND, STRAIGHT,
	FLUSH, FULL_HOUSE, FOUR_OF_KIND,
	STRAIGHT_FLUSH, ROYAL_FLUSH,
}

func _find_scoring_cards():
	# find each card and each pair made between neighbours
	var grid_card_combos = []
	for i in range(0, $CardGrid.grid_cols):
		for j in range(0, $CardGrid.grid_rows):
			var card = $CardGrid.get_card_at_xy(i, j)
			grid_card_combos.push_back([card])
			# make pairs from card below and card to the right
			var below = $CardGrid.get_card_at_xy(i, j + 1)
			var right = $CardGrid.get_card_at_xy(i + 1, j)
			if below:
				grid_card_combos.push_back([card, below])
			if right:
				grid_card_combos.push_back([card, right])
	var best_hands = []
	var used_combo_cards = []
	for combo in grid_card_combos:
		var full_hand = [] + $Community.cards + combo
		var hand = _get_best_hand_type(full_hands)
		if hand != HandType.NONE:
			for c in combo:
				used_combo_cards.push_back(c)
				hand.push_back()

func _get_best_hand_type(cards):
	if cards.size() < 5:
		return 
	cards.sort_custom(self, "sort_cards_ascending")
	var result = []
	if PokerUtils.contains_royal_flush(cards, result):
		return HandType.ROYAL_FLUSH
	if PokerUtils.contains_straight_flush(cards, result):
		return HandType.STRAIGHT_FLUSH
	if PokerUtils.contains_four_of_kind(cards, result):
		return HandType.FOUR_OF_KIND
	if PokerUtils.contains_full_house(cards, result):
		return HandType.FULL_HOUSE
	if PokerUtils.contains_flush(cards, result):
		return HandType.FLUSH
	if PokerUtils.contains_straight(cards, result):
		return HandType.STRAIGHT
	if PokerUtils.contains_3_of_kind(cards, result):
		return HandType.THREE_OF_KIND
	if PokerUtils.contains_2_pair(cards, result):
		return HandType.TWO_PAIR
	if PokerUtils.contains_pair(cards, result):
		return HandType.PAIR

static func sort_cards_ascending(a, b):
	if a.rank < b.rank:
		return true
	return false
