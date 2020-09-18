tool
extends Node2D

const TreeUtils = preload("TreeUtils.gd")

export(int) var grid_rows = 7
export(int) var grid_cols = 4
export(Vector2) var size
export(Color) var line_color = Color(0, 0, 0)
export(float) var line_width = 3

var _grid = {}

func _process(_delta):
	update()

func _draw():
	_draw_grid_lines()

func _draw_grid_lines():
	if line_width == 0:
		return
	for i in range(0, grid_rows + 1):
		var yOffs = i * (size.y / grid_rows) + line_width / 2
		draw_line(Vector2(0, yOffs), Vector2(size.x + line_width, yOffs), line_color, line_width)
	for j in range(0, grid_cols + 1):
		var xOffs = j * (size.x / grid_cols) + line_width / 2
		draw_line(Vector2(xOffs, 0), Vector2(xOffs, size.y + line_width), line_color, line_width)

func _get_grid_origin():
	var vp = get_viewport().get_visible_rect()
	return position + Vector2(vp.size.x / 2 - size.x / 2,
		vp.size.y / 2 - size.y / 2)

func cell2pos(position: Vector2):
	position = position.floor()
	return Vector2(position.x * (size.x / grid_cols),
				   position.y * (size.y / grid_rows))

func clear_cards():
	var cards = []
	var to_remove = [] + _grid.values()
	for card in to_remove:
		cards.push_back(card)
		remove_card(card)
	_grid = {}
	return cards

func get_cards():
	return _grid.values()

func is_cell_free(cell_pos: Vector2):
	var pos = cell_pos.floor()
	return is_cell_free_xy(pos.x, pos.y)

func is_cell_free_xy(x: int, y: int):
	if x < 0 || y < 0 || x >= grid_cols || y >= grid_rows:
		return false
	return _grid.get(_lookup(x, y)) == null

func get_card_at(tile_pos: Vector2):
	var pos = tile_pos.floor()
	return get_card_at_xy(pos.x, pos.y)

func get_card_at_xy(x: int, y: int):
	if _grid.has(_lookup(x,y)):
		return _grid[_lookup(x, y)]
	else:
		return null

func contains_card(card: CardTile):
	return _grid.values().has(card)

func remove_card(card: CardTile):
	return remove_card_at(card.tile_position)

func remove_card_at(tile_pos: Vector2):
	var pos = tile_pos.floor()
	return remove_card_at_xy(pos.x, pos.y)

func remove_card_at_xy(x: int, y: int):
	var card = _grid[_lookup(x, y)]
	_grid.erase(_lookup(x, y))
	TreeUtils.change_parent_preserve_global_position(card, get_tree().get_root())
	return card

func set_card_at(card: CardTile, tile_pos: Vector2):
	var pos = tile_pos.floor()
	set_card_at_xy(card, pos.x, pos.y)

func set_card_at_xy(card: CardTile, x: int, y: int):
	_grid[_lookup(x, y)] = card
	if card.get_parent():
		card.get_parent().remove_child(card)
	add_child(card)
	var pos = Vector2(x, y)
	card.tile_position = pos
	# TODO: tween
	card.position = cell2pos(pos) + \
		(card.get_size() / 2) + \
		Vector2(line_width / 2, line_width / 2)

func move_card(card: CardTile, new_pos: Vector2):
	var old_pos = card.tile_position.floor()
	_grid.erase(_lookup(old_pos.x, old_pos.y))
	remove_child(card)
	set_card_at(card, new_pos)

func get_cell_size():
	return Vector2(size.x / grid_cols, size.y / grid_rows)

func sink_cards_to_bottom():
	var sorted_cards = [] + _grid.values()
	# sort so bottom-most cards are first. sink down from the bottom up
	sorted_cards.sort_custom(CardTileSorter, "sort_cards_by_row_descending")
	print("Sinking cards down")
	for card in sorted_cards:
		var lowest = false
		while !lowest:
			var pos_below = Vector2(card.tile_position.x, card.tile_position.y + 1)
			var below = get_card_at(pos_below)
			if below || pos_below.y >= grid_rows:
				lowest = true
			else:
				move_card(card, pos_below)

func get_neighbours(card: CardTile):
	var x = card.tile_position.x
	var y = card.tile_position.y
	var neighbours = []
	var above = get_card_at_xy(x, y - 1)
	var below = get_card_at_xy(x, y + 1)
	var left = get_card_at_xy(x - 1, y)
	var right = get_card_at_xy(x + 1, y)
	if above:
		neighbours.push_back(above)
	if below:
		neighbours.push_back(below)
	if left:
		neighbours.push_back(left)
	if right:
		neighbours.push_back(right)
	return neighbours
	
func _lookup(x: int, y: int):
	return "%d,%d" % [x, y]

class CardTileSorter:
	static func sort_cards_by_row_descending(a, b):
		if a.tile_position.y > b.tile_position.y:
			return true
		return false

	static func sort_cards_by_row_ascending(a, b):
		if a.tile_position.y < b.tile_position.y:
			return true
		return false
