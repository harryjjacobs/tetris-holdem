extends Node2D
class_name CardTile

const SUIT = {
	"CLUBS": "Clubs",
	"DIAMONDS": "Diamonds",
	"HEARTS": "Hearts",
	"SPADES": "Spades"
}

const RANK = { 
	2: "2", 3: "3",
	4: "4", 5: "5",
	6: "6", 7: "7",
	8: "8", 9: "9",
	10: "10", 11: "J",
	12: "Q", 13: "K",
	14: "A" 
}

export(float) var tween_duration_position = 0.7
export(float) var tween_duration_exit = 0.5

var suit = "CLUBS"
var rank = 2
var tile_position: Vector2

func init(_suit, _rank, _texture, _sprite_scale = Vector2.ZERO):
	suit = _suit;
	rank = _rank;
	$CardSprite.texture = _texture
	$CardSprite.scale = _sprite_scale
	set_glow(false)

func set_glow(state):
	$CardSprite/Glow.visible = state

func tween_to_position(target_pos: Vector2):
	$CardSprite.position -= target_pos - position
	position = target_pos
	$Tween.interpolate_property($CardSprite, "position", $CardSprite.position,
		Vector2.ZERO, tween_duration_position, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	$Tween.start()

func animate_exit():
	print("EXIT ANIM")
	var orig_tf = $CardSprite.transform
	$Tween.interpolate_property($CardSprite, "scale", $CardSprite.scale, Vector2.ZERO,
		tween_duration_exit)
	$Tween.interpolate_property($CardSprite, "rotation_degrees", 
		$CardSprite.rotation_degrees, 360, tween_duration_exit)
	$Tween.interpolate_callback(self, tween_duration_exit,
		"_reset_sprite_after_exit_tween", orig_tf)
	$Tween.start()
	
func get_size():
	return $CardSprite.texture.get_size() * $CardSprite.scale

func equals(card):
	return suit == card.suit && \
		   rank == card.rank

func to_string():
	return RANK[rank] + SUIT[suit][0]

func _reset_sprite_after_exit_tween(tf):
	visible = false
	$CardSprite.transform = tf
