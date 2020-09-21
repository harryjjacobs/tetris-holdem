extends Node2D

const CardTile = preload("./CardTile.gd")
const PokerUtils = preload("./PokerUtils.gd")
const PokerEvalEvaluator = preload("pokereval/PokerEvalEvaluator.gd")

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

export(float) var community_deal_pause_duration = 2.0
export(float) var cardgrid_deal_duration = 0.2
export(float) var showdown_display_duration = 2.0
export(float) var multicard_animation_delay = 0.05

signal on_game_over

var _poker_state = {
	"stage": PokerStages.PREFLOP,
	"descent_count": 0,
	"community_cards": null
}

var _game_state = {
	"descending_card_tile": null,
	"executing_showdown": false
}

func init():
	_poker_state.stage = PokerStages.PREFLOP
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
	if _game_state.executing_showdown:
		return
	if _is_poker_stage_finished():
		_poker_state.descent_count = 0
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
	if $DescentStepTimer.do_step:
		if _game_state.descending_card_tile:
			_move_card_down()
		else:
			_begin_descent($Deck.get_next_card())

func _showdown():
	_game_state.executing_showdown = true
	var winning_hand = _find_scoring_cards()
	var empty_grid_spaces = []
	for card in winning_hand.cards:
		if $CardGrid.contains_card(card):
			$CardGrid.remove_card(card)
			empty_grid_spaces.push_back(card.tile_position)
		else:
			$Community.remove_card(card)
		card.set_glow(true)
		$Showdown.add_card(card)
	
	# display showdown
	var PokerUtils = get_node("/root/PokerUtils")
	var category_name = PokerUtils.rank_category_friendly_name(winning_hand.category)
	$Showdown/ShowdownTitle.show_category(category_name)

	# award points
	$Score.increase(winning_hand.rank)

	# wait x seconds, then resume execution
	yield(get_tree().create_timer(showdown_display_duration), "timeout")

	# hide cards from showdown
	var last_card
	for card in winning_hand.cards:
		card.animate_exit()
		card.set_glow(false)
		last_card = card
		yield(get_tree().create_timer(multicard_animation_delay), "timeout")
	
	for card in $Community.cards:
		card.animate_exit()
		last_card = card

	# wait until the last card is no longer visible
	yield(last_card, "hide")

	# return cards to deck
	$Deck.return_cards($Community.clear_cards())
	$Deck.return_cards($Showdown.clear_cards())

	# sink cards in cardgrid down to close gaps
	$CardGrid.sink_cards_to_bottom()
	
	_game_state.executing_showdown = false
	
func _begin_descent(_card_tile):
	_game_state.descending_card_tile = _card_tile
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var start_pos = Vector2(rng.randi_range(0, $CardGrid.grid_cols - 1), 0)
	if !$CardGrid.is_cell_free(start_pos):
		emit_signal("on_game_over", $Score.score)
	else:
		$MovementCooldownTimer.pause(cardgrid_deal_duration)
		$DescentStepTimer.reset()
		$DescentStepTimer.pause(cardgrid_deal_duration)
		$CardGrid.set_card_at(_game_state.descending_card_tile, start_pos, 
			cardgrid_deal_duration)

func _end_descent():
	_game_state.descending_card_tile = null
	_poker_state.descent_count += 1

func _move_card_down():
	if _game_state.descending_card_tile == null:
		return
	if !_translate_card_tile(Vector2(0, 1)):
		_end_descent()

func _move_card_left():
	_translate_card_tile(Vector2(-1, 0))

func _move_card_right():
	_translate_card_tile(Vector2(1, 0))

func _translate_card_tile(pos):
	if _game_state.descending_card_tile == null:
		return false
	var new_pos = _game_state.descending_card_tile.tile_position + pos
	if !$CardGrid.is_cell_free(new_pos):
			return false
	$CardGrid.move_card(_game_state.descending_card_tile, new_pos)
	return true

func _add_community_cards(poker_stage):
	for _i in range(0, poker_stage.COMMUNITY):
		$Community.add_card($Deck.get_next_card())
	$DescentStepTimer.pause(community_deal_pause_duration)

func _clear_community_cards():
	var cleared = $Community.clear_cards()
	$Deck.return_cards(cleared)

func _is_poker_stage_finished():
	return _poker_state.descent_count >= _poker_state.stage.DESCEND

# ===== POKER EVALUATION LOGIC ===== 

func _find_scoring_cards():
	# TODO: performance timer
	var PokerUtils = get_node("/root/PokerUtils")
	var grid_card_combos = _find_grid_combos()
	print("Found ", grid_card_combos.size(), " combos in the grid")
	var best_rank = PokerUtils.MAX_RANK
	var best_hand
	for combo in grid_card_combos:
		print("Evaluating combo ",
			PokerUtils.card_array_to_string_array(combo),
			" + community cards ",
			PokerUtils.card_array_to_string_array($Community.cards))
		var result = _evaluate_combo($Community.cards, combo)
		if result.rank <= best_rank:	# lower is better
			best_hand = result
			best_rank = result.rank
	print("Calculated best hand combination:")
	print(PokerUtils.rank_category_friendly_name(best_hand.category))
	print("Hand: ", 
		PokerUtils.card_array_to_string_array(best_hand.cards))
	return best_hand

func _evaluate_combo(community_cards, combo_cards):
	var PokerUtils = get_node("/root/PokerUtils")
	var full_hand = [] + community_cards + combo_cards
	var results = PokerUtils.evaluate_many(full_hand)
	var best_rank = PokerUtils.MAX_RANK	# max rank is worst rank
	var best_result
	for result in results:
		var cards = []
		var grid_cards = []
		for card_str in result.cards:
			var card = PokerUtils.find_card_by_string(full_hand, card_str)
			cards.push_back(card)
			if card in combo_cards:
				grid_cards.push_back(card)
		result.cards = cards
		#print("Comparing result for ", 
		#	PokerUtils.card_array_to_string_array(result.cards), "(",
		#	PokerUtils.rank_category_friendly_name(result.category), ")")
		# check if grid combo cards used for this evaluation
		# combination are connected with no separations,
		# in a group in the grid
		if !_are_grid_cards_in_group(grid_cards):
			continue
		if result.rank <= best_rank:	# lower rank is better
			best_result = result
			best_rank = result.rank
	print("Highest rank: ", best_result.rank, " (", 
		PokerUtils.rank_category_friendly_name(best_result.category), ")")
	return best_result

# checks whether the cards are in one group
# block in the card grid with no separation
func _are_grid_cards_in_group(cards):
	var neighbour_sum = 0;
	var MIN_SUM = cards.size() * 2 - 2
	for combo_card in cards:
		var neighbours = $CardGrid.get_neighbours(combo_card)
		for neighbour in neighbours:
			if neighbour in cards:
				neighbour_sum += 1
	return neighbour_sum >= MIN_SUM

# finds all combinations of connected cards (up to and incl. size 5)
func _find_grid_combos():
	var combos = []
	for card in $CardGrid.get_cards():
		combos += _card_grid_find_all_subsets(card, 5)
	return combos

func _card_grid_find_all_subsets(card: CardTile, max_size: int = 5):
	# performs a variation on Breadth First Search to find all subsets
	# with specified maximum size
	var subsets = [[]]
	var queue = []
	var discovered = {card.to_string(): card}
	queue.push_back(card)
	while !queue.empty():
		var current = queue.pop_front()
		subsets[-1].push_back(current)
		if subsets[-1].size() == max_size:
			subsets.push_back([])
		for neighbour in $CardGrid.get_neighbours(current):
			var card_str = neighbour.to_string()
			if !discovered.has(card_str):
				discovered[card_str] = neighbour
				queue.push_back(neighbour)
	return subsets
