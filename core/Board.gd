extends Node2D

const CardTile = preload("./CardTile.gd")
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
	var PokerHelper = get_node("/root/PokerHelper")
	_game_state.executing_showdown = true

	# evaluate grid card and community card combinations
	# to find the best hand
	var winning_hand = PokerHelper.find_winning_hand(
		$Community.cards, $CardGrid)

	# add cards to showdown node
	for card in winning_hand.cards:
		if card in $Community.cards:
			$Community.remove_card(card)
		else:
			$CardGrid.remove_card(card)
		card.set_glow(true)
		$Showdown.add_card(card)
	
	# display showdown title
	var category_name = PokerHelper.rank_category_friendly_name(
		winning_hand.category)
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

func _is_poker_stage_finished():
	return _poker_state.descent_count >= _poker_state.stage.DESCEND
