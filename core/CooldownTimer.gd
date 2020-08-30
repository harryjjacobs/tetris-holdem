extends Node

export(float) var cooldown_duration = 0.1

var is_cool = false setget , _is_cool

var _time = 0.0
var _is_cooled = true

# Called when the node enters the scene tree for the first time.
func _ready():
	reset()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !_is_cooled:
		if _time <= 0.0:
			_is_cooled = true
		_time -= delta

func trigger():
	_is_cooled = false
	_time = cooldown_duration

func reset():
	_is_cooled = true
	_time = 0.0

func _is_cool():
	return _is_cooled
