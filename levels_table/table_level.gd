extends Control

@export_group("Popup text")
@export var intro_title: String = ""
@export_multiline var intro_desc: String = ""
@export var intro_btn: String = "Start"
@export var win_title: String = ""
@export_multiline var win_text: String = ""
@export var win_button_text: String = ""
@export var lose_title: String = "Špatný výběr"
@export_multiline var lose_text: String = ""
@export var lose_button_text: String = "Zkusit znovu"

@export_group("Difficulty Settings")
@export var allow_row_swap: bool = false
@export var allow_rotation_90: bool = false
@export var allow_rotation_180: bool = false

@export_group("Level Progression")
@export var next_scene: PackedScene 
@export var popup_ui: Control 

@export_group("Puzzle Pieces")
@export var correct_top: PackedScene
@export var fake_tops: Array[PackedScene]
@export var correct_left: PackedScene
@export var fake_lefts: Array[PackedScene]

@onready var puzzle_grid = %PuzzleGrid

var winning_col: int = -1
var winning_row: int = -1

# nahodne prohazovani arrays, jak mezi sebou v jednom radku/sloupci, tak prohazovani radku i sloupcu

func _ready():
	setup_board()
	
	if not Global.is_restarting:
		popup_ui.show_message(intro_title, intro_desc, intro_btn)
		await popup_ui.popup_closed
	else:
		Global.is_restarting = false 

func setup_board():
	var group_top: Array[PackedScene] = [correct_top]
	group_top.append_array(fake_tops)
	
	var group_left: Array[PackedScene] = [correct_left]
	group_left.append_array(fake_lefts)
	
	var final_top_pool: Array[PackedScene]
	var final_left_pool: Array[PackedScene]
	
	if allow_row_swap and randf() > 0.5:
		final_top_pool = group_left
		final_left_pool = group_top
	else:
		final_top_pool = group_top
		final_left_pool = group_left
	
	final_top_pool.shuffle()
	final_left_pool.shuffle()
	
	# hledani vyherneho pole v mrizce
	var pos_top = final_top_pool.find(correct_top)
	var pos_left = final_left_pool.find(correct_left)
	
	if pos_top != -1 and pos_left != -1:
		winning_col = pos_top
		winning_row = pos_left
	else:
		winning_col = final_top_pool.find(correct_left)
		winning_row = final_left_pool.find(correct_top)

	var possible_rotations: Array[int] = [0] 
	if allow_rotation_90:
		possible_rotations.append(90)
		possible_rotations.append(-90)
	if allow_rotation_180:
		possible_rotations.append(180)

	var grid_cells = puzzle_grid.get_children()
	
	for i in range(4):
		var piece_inst = final_top_pool[i].instantiate()
		piece_inst.get_node("Rotator").rotation_degrees = possible_rotations.pick_random()
		grid_cells[i + 1].add_child(piece_inst)
		
	for row in range(4):
		var left_slot_index = 5 + (row * 5)
		var piece_inst = final_left_pool[row].instantiate()
		piece_inst.get_node("Rotator").rotation_degrees = possible_rotations.pick_random()
		grid_cells[left_slot_index].add_child(piece_inst)
		
		# z tabulka tlacitkek
		for col in range(4):
			var button_index = left_slot_index + 1 + col
			var button = grid_cells[button_index]
			if button is Button:
				for conn in button.pressed.get_connections():
					button.pressed.disconnect(conn.callable)
				button.pressed.connect(func(): _on_grid_button_pressed(row, col, button))

func _on_grid_button_pressed(clicked_row: int, clicked_col: int, clicked_btn: Button):
	var hover_style = clicked_btn.get_theme_stylebox("hover", "Button")
	clicked_btn.add_theme_stylebox_override("disabled", hover_style)
	
	clicked_btn.modulate = Color(1.2, 1.2, 1.2)


	for child in puzzle_grid.get_children():
		if child is Button:
			child.disabled = true

	if clicked_row == winning_row and clicked_col == winning_col:
		popup_ui.show_message(win_title, win_text, win_button_text)
		await popup_ui.popup_closed
		
		if next_scene != null:
			get_tree().change_scene_to_packed(next_scene)
	else:
		popup_ui.show_message(lose_title, lose_text, lose_button_text, true)
		await popup_ui.popup_closed
		Global.is_restarting = true 
		get_tree().reload_current_scene()
