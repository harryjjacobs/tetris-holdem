extends Control

enum GameState { PLAYING, PAUSED, OVER, STOPPED }
const PokerStages = { 
	"PREFLOP": {
		"DESCEND": 2,
		"COMMUNITY": 0,
		"NEXT": "FLOP"
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

var _game_state = GameState.STOPPED
var _poker_state = {
	"stage": PokerStages.PREFLOP,
	"descent_count": 0,
	"community_cards": null
}

var _community_cards
var _descending_card_tile

# Called when the node enters the scene tree for the first time.
func _ready():
	print_debug("Ready")
	start()

func start():
	_game_state = GameState.PLAYING
	_poker_state.stage = PokerStages.PREFLOP
	print_debug(_poker_state)
	$Deck.init()

func _process(_delta):
	if $StepTimer.do_step:
		print_debug(_poker_state)
		if _descending_card_tile:
			_drop_card_tile()
		else:
			_begin_descent($Deck.get_next_card())
		if _poker_state.descent_count >= _poker_state.stage.DESCEND:
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
					# TODO: do showdown
			_poker_state.descent_count = 0

func _begin_descent(_card_tile):
	_descending_card_tile = _card_tile
	_descending_card_tile.set_tile_position(5, 0)

func _end_descent():
	#$CardGrid.
	#set_cellv(_descending_card_tile.get_tile_position(), 1)
	_descending_card_tile = null
	_poker_state.descent_count += 1

func _drop_card_tile():
	if !_translate_card_tile(Vector2(0, 1)):
		_end_descent()

func _translate_card_tile(pos):
	var new_pos = _descending_card_tile.get_tile_position() + pos
	#if self.get_cellv(new_pos) == INVALID_CELL:
	#		return false
	_descending_card_tile.set_tile_position(new_pos)
	return true

func _add_community_cards(poker_stage):
	for _i in range(0, poker_stage.COMMUNITY):
		$Community.add_card($Deck.get_next_card())

func _clear_community_cards():
	var cleared = $Community.clear_cards()
	$Deck.return_cards(cleared)
