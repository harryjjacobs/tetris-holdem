extends Node

export(bool) var do_step = false setget , _get_do_step
export(float) var step_duration = 0.5

var _time = 0.0
var _do_step = true

# Called when the node enters the scene tree for the first time.
func _ready():
	_time = step_duration

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_time -= delta
	if _time <= 0.0:
		_do_step = true
		_time = step_duration

func _get_do_step():
	var do = _do_step
	_do_step = false
	return do
