tool
extends Node2D

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
	for pos in _grid:
		cards.push_back(_grid[pos])
		_grid = {}
	return cards

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
	return _grid[_lookup(x, y)]

func set_card_at(card: CardTile, tile_pos: Vector2):
	var pos = tile_pos.floor()
	set_card_at_xy(card, pos.x, pos.y)

func set_card_at_xy(card: CardTile, x: int, y: int):
	_grid[_lookup(x, y)] = card
	add_child(card)
	var pos = Vector2(x, y)
	card.tile_position = pos
	# TODO: tween
	card.position = cell2pos(pos) + \
		(card.texture.get_size() * card.scale) / 2 + \
		Vector2(line_width / 2, line_width / 2)

func move_card(card: CardTile, new_pos: Vector2):
	var old_pos = card.tile_position.floor()
	_grid[_lookup(old_pos.x, old_pos.y)] = null
	remove_child(card)	# TODO: check this
	set_card_at(card, new_pos)

func get_cell_size():
	return Vector2(size.x / grid_cols, size.y / grid_rows)

func _lookup(x: int, y: int):
	return "%d,%d" % [x, y]