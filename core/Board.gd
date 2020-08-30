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
export(float) var showdown_display_duration = 1.0
export(float) var multicard_animation_delay = 0.25

signal on_game_over

var _poker_state = {
	"stage": PokerStages.PREFLOP,
	"descent_count": 0,
	"community_cards": null
}

var _descending_card_tile

func init():
	_poker_state.stage = PokerStages.PREFLOP
	print_debug(_poker_state)
	$Deck.init()

func _process(_delta):
	if $MovementCooldownTimer.is_cool:
		if Input.is_action_pressed("move_left"):
			_move_card_left()
			$MovementCooldownTimer.trigger()
		elif Input.is_action_pressed("move_right"):
			_move_card_right()
			$MovementCooldownTimer.trigger()
		elif Input.is_action_pressed("move_down"):
			_move_card_down()
			$MovementCooldownTimer.trigger()

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
	var winning_hand = _find_scoring_cards()
	for card in winning_hand:
		if $CardGrid.contains_card(card):
			$CardGrid.remove_card(card)
		else:
			$Community.remove_card(card)
		card.set_glow(true)
		$Showdown.add_card(card)

	# Wait 5 seconds, then resume execution.
	yield(get_tree().create_timer(showdown_display_duration), "timeout")

	var last_card
	for card in winning_hand:
		card.animate_exit()
		yield(get_tree().create_timer(multicard_animation_delay), "timeout")
		last_card = card
	
	# wait until the last card is no longer visible
	yield(last_card, "hide")
		
	# return cards to deck
	$Deck.return_cards($Community.clear_cards())
	$Deck.return_cards($Showdown.clear_cards())
	
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

func _find_scoring_cards():
	# find each card and each pair made between neighbours
	var grid_card_combos = []
	for i in range(0, $CardGrid.grid_cols):
		for j in range(0, $CardGrid.grid_rows):
			var card = $CardGrid.get_card_at_xy(i, j)
			if card == null:
				continue
			grid_card_combos.push_back([card])
			# make pairs from card below and card to the right
			var below = $CardGrid.get_card_at_xy(i, j + 1)
			var right = $CardGrid.get_card_at_xy(i + 1, j)
			if below:
				grid_card_combos.push_back([card, below])
			if right:
				grid_card_combos.push_back([card, right])
	var best_hand
	var best_category = PokerUtils.RANK_CATEGORY.HIGH_CARD
	for combo in grid_card_combos:
		var full_hand = [] + $Community.cards + combo
		var str_hand = card_array_to_string_array(full_hand)
		#print("Checking combination: ", str_hand)
		var rank = $HandEval.evaluate(str_hand)
		#print("Category: ", PokerUtils.rank_category_friendly_name(rank.category))
		if rank.category < best_category:	# lower is better
			best_hand = rank
			best_hand.original_hand = full_hand
			best_hand.original_hand_str = str_hand
			best_category = rank.category
	var best_hand_cards = PokerUtils.find_cards_from_category(
		best_hand.original_hand, best_hand.category)
	print("Calculated best hand combination:")
	print(best_hand.original_hand_str)
	print(PokerUtils.rank_category_friendly_name(best_hand.category))
	print(best_hand.hand)
	print("Found corresponding card nodes for winning hand:", 
		card_array_to_string_array(best_hand_cards))
	return best_hand_cards

static func card_array_to_string_array(cards):
	var str_arr = []
	for card in cards:
		str_arr.push_back(card.to_string().replace("10", "T"))
	return str_arr
