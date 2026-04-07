@tool
extends Node2D

@export var cell_size: int = 64 
@export var grid_color: Color = Color(0, 0, 0, 0.3)
@export var line_width: float = 1.4 # cokoliv nad 2 je moc vysoke, ale s 1 jsem mel take problemy, nekdy to preskakovalo linky pri nizsich res
@export var map_size: int = 50 

func _draw():
	# grid mrizka pro grid programovaciho levelu
	for x in range(map_size + 1):
		var start_pos = Vector2(x * cell_size, 0)
		var end_pos = Vector2(x * cell_size, map_size * cell_size)
		draw_line(start_pos, end_pos, grid_color, line_width)

	for y in range(map_size + 1):
		var start_pos = Vector2(0, y * cell_size)
		var end_pos = Vector2(map_size * cell_size, y * cell_size)
		draw_line(start_pos, end_pos, grid_color, line_width)
