extends Area2D

# timto blokem jsem zacinal a je z toho uplne neco jineho, proto je tento kod chaoticky, normalne bych vse dal do inspektoru levelu grid_level
# netusil jsem, ze tento node uz nikdy nepouziju na dalsi scenu/ulohu, velka chyba, ale uz pozde na predelani (vsechny grid levely jsou hotove a funkcni)
# uz zbytecne predelavat

signal stats_changed(new_energy, new_screws)
signal message_sent(text)

@export_group("UI")
@export var next_scene: PackedScene
@export var popup_ui: Control

@export_group("Popup text")
@export var intro_title: String = ""
@export_multiline var intro_desc: String = ""
@export var intro_btn: String = "Start"
@export var win_title: String = ""
@export_multiline var win_text: String = ""
@export var win_button_text: String = ""
@export var lose_title: String = ""
@export_multiline var lose_text: String = ""
@export var lose_button_text: String = "Zkusit znovu"

@onready var ray = $RayCast2D
@onready var ghost = $Ghost
@onready var trail = $Line2D
@onready var energy_label = $EnergyLabel

var tile_size = 64
var animation_speed = 0.3
var energy = 3
var sebrane_sroubky = 0
var total_screws = 0
var consumed_batteries: Array[Area2D] = []

var step_queue: Array[Vector2] = []
var is_moving = false 
var vyhra_splnena = false

func _ready():
	trail.top_level = true
	trail.global_position = Vector2.ZERO 
	
	position = position.snapped(Vector2(tile_size, tile_size))
	ghost.position = Vector2.ZERO 
	
	trail.clear_points()
	trail.add_point(global_position + get_local_center())
	
	total_screws = get_tree().get_nodes_in_group("screws").size()
	stats_changed.emit(energy, sebrane_sroubky)
	update_energy_display()
	

	if popup_ui.has_signal("peek_started"):
		popup_ui.peek_started.connect(func(): 
			trail.visible = true
			for bat in consumed_batteries:
				bat.visible = true
				bat.modulate.a = 0.35
		)
		popup_ui.peek_ended.connect(func(): 
			trail.visible = false
			for bat in consumed_batteries:
				bat.visible = false
		)
	
	if not Global.is_restarting:
		popup_ui.show_message(intro_title, intro_desc, intro_btn)
		await popup_ui.popup_closed
	else:
		Global.is_restarting = false
	
func _unhandled_input(event):
	if is_moving or (popup_ui and popup_ui.visible):
		return

	if event is InputEventKey and event.is_pressed() and not event.is_echo():
			if event.keycode == KEY_SPACE:
				animation_speed = 0.125
				start_run()
				return
			elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				animation_speed = 0.35
				start_run()
				return
				
	var direction = Vector2.ZERO
	if event.is_action_pressed("ui_right"): 
		direction = Vector2.RIGHT
	elif event.is_action_pressed("ui_left"): 
		direction = Vector2.LEFT
	elif event.is_action_pressed("ui_up"):    
		direction = Vector2.UP
	elif event.is_action_pressed("ui_down"):  
		direction = Vector2.DOWN

	if direction != Vector2.ZERO:
		plan_step(direction)

func plan_step(dir):
	# krok smerem zpet na naplanovanou cestu vymaze posledni krok (backtrack)
	if step_queue.size() > 0:
		var last_move = step_queue[-1]
		if dir == -last_move:
			step_queue.pop_back() 
			ghost.position += dir * tile_size 
			if trail.get_point_count() > 0:
				trail.remove_point(trail.get_point_count() - 1) 
			return 

	step_queue.append(dir)
	ghost.position += dir * tile_size
	
	trail.add_point(global_position + ghost.position + get_local_center())

func get_local_center():
	return Vector2(32, 32)

func start_run():
	if step_queue.size() == 0: 
		return
	
	is_moving = true
	ghost.visible = false 
	
	trail.visible = false 
	
	for move_dir in step_queue:
		var success = attempt_move_robot(move_dir)
		
		if success:
			await get_tree().create_timer(animation_speed).timeout
		else:
			break 
			
	await get_tree().create_timer(1.25).timeout
	
	if not vyhra_splnena:
		popup_ui.show_message(lose_title, lose_text, lose_button_text, true)
		await popup_ui.popup_closed
		Global.is_restarting = true
		get_tree().reload_current_scene()
	
	is_moving = false
	reset_planning()

func attempt_move_robot(dir):
	if energy <= 0: 
		return false

	# raycast na kolize (voda)
	ray.position = Vector2(32, 32) 
	ray.target_position = dir * (tile_size + 10) 
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider.is_in_group("walls"):
			var bump_tween = create_tween()
			bump_tween.tween_property(self, "position", position + (dir * 10), 0.05)
			bump_tween.tween_property(self, "position", position, 0.05)
			return false 
	
	var target_position = position + (dir * tile_size)
	
	var move_tween = create_tween()
	move_tween.tween_property(self, "position", target_position, animation_speed).set_trans(Tween.TRANS_SINE)
	
	energy -= 1
	stats_changed.emit(energy, sebrane_sroubky)
	update_energy_display()
	
	return true

func reset_planning():
	step_queue.clear()
	ghost.visible = true
	ghost.position = Vector2.ZERO 
	
	trail.clear_points()
	trail.add_point(global_position + get_local_center())

func _on_area_entered(area):
	if area.is_in_group("energy"):
		var amount = 5 
		
		if area.has_meta("energy"):
			if (area.get_meta("energy") == 0):
				amount = 5
			else: 
				amount = area.get_meta("energy")
		
		energy += amount
		
		area.visible = false 
		area.remove_from_group("energy")
		consumed_batteries.append(area)
		
		stats_changed.emit(energy, sebrane_sroubky)
		energy_label.text = str(energy)
		message_sent.emit("Energie +" + str(amount))

	if area.is_in_group("screws"):
		sebrane_sroubky += 1
		area.queue_free()
		stats_changed.emit(energy, sebrane_sroubky)
		
		if sebrane_sroubky >= total_screws:
			var exit_door = get_tree().get_first_node_in_group("exit")
			if exit_door:
				exit_door.get_node("ColorRect").modulate = Color("#ffffff00")
				message_sent.emit("Exit Unlocked!")

	if area.is_in_group("exit"):
		if sebrane_sroubky >= total_screws:
			vyhra_splnena = true
			message_sent.emit("PŘÍSTUP SCHVÁLEN!")
			
			popup_ui.show_message(win_title, win_text, win_button_text)
			await popup_ui.popup_closed
			
			if next_scene != null:
				get_tree().change_scene_to_packed(next_scene)
			else:
				print("Další scéna není nastavena v Inspektoru!")

func update_energy_display():
	energy_label.text = str(energy)
	
	if energy <= 0:
		energy_label.modulate = Color.RED
	else:
		energy_label.modulate = Color.YELLOW
