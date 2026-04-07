extends Control

@export var next_scene: PackedScene 
@export_category("Dialogový Systém")
@export var text_delay: float = 1.0 
@export var typewriter_speed: float = 0.05
@export var dialogue_texts: Array[String] = []

@onready var next_button = $NextButton
@onready var story_label = $Label
@onready var ui_bg = $NinePatchRect
@onready var fade_out_rect = $FadeOutRect
@onready var rocket = $RobotRaketa
@onready var engine_fire = $RobotRaketa/AnimatedSprite2D 

var current_text_index: int = 0
var is_typing: bool = false
var type_tween: Tween
var is_transitioning: bool = false
var rocket_start_pos: Vector2

func _ready():
	rocket_start_pos = rocket.position
	rocket.rotation_degrees = 90.0
	
	if engine_fire:
		engine_fire.visible = false
	
	story_label.visible_ratio = 0.0
	ui_bg.modulate.a = 0.0
	next_button.modulate.a = 0.0
	
	fade_out_rect.visible = true
	fade_out_rect.modulate.a = 1.0
	fade_out_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	next_button.pressed.connect(_on_button_pressed)
	
	var intro_tween = create_tween()
	intro_tween.tween_property(fade_out_rect, "modulate:a", 0.0, 1.5)
	
	await get_tree().create_timer(text_delay).timeout
	
	var ui_tween = create_tween().set_parallel(true)
	ui_tween.tween_property(ui_bg, "modulate:a", 0.5, 0.5)
	ui_tween.tween_property(next_button, "modulate:a", 1.0, 0.5)
	await ui_tween.finished
	
	show_next_dialogue()

func _on_button_pressed():
	if is_transitioning: 
		return
	
	if is_typing:
		type_tween.kill()
		story_label.visible_ratio = 1.0
		is_typing = false
	else:
		show_next_dialogue()

func show_next_dialogue():
	if current_text_index >= dialogue_texts.size():
		trigger_takeoff()
		return

	story_label.visible_ratio = 0.0
	story_label.text = dialogue_texts[current_text_index]
	
	is_typing = true
	type_tween = create_tween()
	var time_to_type = story_label.text.length() * typewriter_speed 
	type_tween.tween_property(story_label, "visible_ratio", 1.0, time_to_type)
	type_tween.finished.connect(func(): is_typing = false)
	
	current_text_index += 1

func trigger_takeoff():
	is_transitioning = true
	
	var hide_tween = create_tween().set_parallel(true)
	hide_tween.tween_property(ui_bg, "modulate:a", 0.0, 0.5)
	hide_tween.tween_property(story_label, "modulate:a", 0.0, 0.5)
	hide_tween.tween_property(next_button, "modulate:a", 0.0, 0.5)
	await hide_tween.finished
	
	# vibrace pred odletem (twitch)
	var twitch_tween = create_tween()
	for i in range(15):
		var random_offset = Vector2(randf_range(-6, 6), randf_range(-6, 6))
		twitch_tween.tween_property(rocket, "position", rocket_start_pos + random_offset, 0.05)
	twitch_tween.tween_property(rocket, "position", rocket_start_pos, 0.05)
	await twitch_tween.finished
	
	if engine_fire:
		engine_fire.visible = true
		if engine_fire.has_method("play"):
			engine_fire.play()
	
	# akcelerace pohybu odletu (ease in/out)
	var flight_tween = create_tween().set_parallel(true)
	
	flight_tween.tween_property(rocket, "rotation_degrees", 45.0, 2.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	flight_tween.tween_property(rocket, "position", rocket.position + Vector2(-1500, -1500), 4.0)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	
	flight_tween.set_parallel(false)
	await flight_tween.finished
	
	fade_out_rect.move_to_front()
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_out_rect, "modulate:a", 1.0, 1.0)
	await fade_tween.finished
	await get_tree().create_timer(0.5).timeout
	
	if next_scene:
		get_tree().change_scene_to_packed(next_scene)
