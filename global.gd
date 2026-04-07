extends Node
# aby se neopakoval intrp popup pri restartu levelu (failu levelu)
var is_restarting: bool = false

func _input(event):
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		
		# shift
		if event.shift_pressed:
			
			# U=0 I=1 O=2 P=3
			var level_num = -1
			if event.keycode == KEY_U: level_num = 0
			elif event.keycode == KEY_I: level_num = 1
			elif event.keycode == KEY_O: level_num = 2
			elif event.keycode == KEY_P: level_num = 3
			
			if level_num != -1:
				is_restarting = false
				
				# binarni = q
				if Input.is_physical_key_pressed(KEY_Q):
					get_tree().change_scene_to_file("res://levels_binary_code/binary_level_" + str(level_num) + ".tscn")
					
				# souradnice = w
				elif Input.is_physical_key_pressed(KEY_W):
					get_tree().change_scene_to_file("res://levels_table/table_level_" + str(level_num) + "/table_level_" + str(level_num) + ".tscn")
					
				# programovaci = e
				elif Input.is_physical_key_pressed(KEY_E):
					get_tree().change_scene_to_file("res://levels_grid/grid_level_" + str(level_num) + ".tscn")
