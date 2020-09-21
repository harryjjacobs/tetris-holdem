extends Node

export(float) var cooldown_duration = 0.1

var is_cool = false setget , _is_cool

var _time = 0.0
var _is_cooled = true

var _is_paused = false
var _indefinite_pause = false
var _paused_timeout = 0.0

func _ready():
	reset()

func _process(delta):
	if _is_paused:
		_handle_pause(delta)
		return
	if !_is_cooled:
		if _time <= 0.0:
			_is_cooled = true
		_time -= delta

# initiate a cooldown period
func trigger():
	_is_cooled = false
	_time = cooldown_duration

func reset():
	_is_cooled = true
	_time = 0.0

# Set to < 0 for indefinite pause
func pause(duration = -1.0):
	_is_paused = true
	_paused_timeout = duration
	_indefinite_pause = duration < 0
	_is_cooled = false
	
func resume():
	_is_paused = false

func is_paused():
	return _is_paused;

func _is_cool():
	return _is_cooled

func _handle_pause(delta):
	if !_indefinite_pause:
		_paused_timeout -= delta
		if _paused_timeout <= 0:
			resume()
