tool
extends Node2D

export(int) var grid_rows = 7
export(int) var grid_cols = 4
export(Vector2) var size

func _process(_delta):
	update()

func _draw():
	var vp = get_viewport().get_visible_rect()
	var center_pos = position + Vector2(vp.size.x / 2 - size.x / 2,
		vp.size.y / 2 - size.y / 2)
	for i in range(0, grid_rows + 1):
		var yOffs = i * (size.y / grid_rows)
		draw_line(center_pos + Vector2(0, yOffs), center_pos + Vector2(size.x, yOffs), Color(0, 0, 0), 1)
	for j in range(0, grid_cols + 1):
		var xOffs = j * (size.x / grid_cols)
		draw_line(center_pos + Vector2(xOffs, 0), center_pos + Vector2(xOffs, size.y), Color(0, 0, 0), 1)
