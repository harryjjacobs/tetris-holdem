extends Node

export(float) var step_duration = 0.5

var do_step = false setget , _get_do_step

var _time = 0.0
var _do_step = true
var _paused = false
var _indefinite_pause = false
var _paused_timeout = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	_time = step_duration

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _paused:
		_handle_pause(delta)
		return
	if _time <= 0.0:
		_do_step = true
		_time = step_duration
	_time -= delta

func _get_do_step():
	var do = _do_step
	_do_step = false
	return do

func _handle_pause(delta):
	if !_indefinite_pause:
		_paused_timeout -= delta
		if _paused_timeout <= 0:
			resume()

func reset():
	_time = step_duration

# Set to < 0 for indefinite pause
func pause(duration = -1.0):
	_paused = true
	_paused_timeout = duration
	_indefinite_pause = duration < 0
	_do_step = false
	
func resume():
	_paused = false

func is_paused():
	return _paused;
