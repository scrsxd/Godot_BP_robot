extends Control

@export var next_scene: PackedScene 
@export var scroll_speed: float = 100.0
@export var float_speed: float = 2.0
@export var float_distance: float = 20.0

@export_category("Dialogový Systém")
@export var text_delay: float = 1.0 
@export var typewriter_speed: float = 0.05
@export var dialogue_texts: Array[String] = [] 

@onready var next_button = $NextButton
@onready var parallax_bg = $ParallaxBackground
@onready var rocket = $RobotRaketa
@onready var ui_bg = $NinePatchRect
@onready var story_label = $Label
@onready var fade_out_rect = $FadeOutRect

enum StavSceny { INTRO, DIALOGUE, ENDING }

var time_passed: float = 0.0
var rocket_base_position: Vector2
var current_state = StavSceny.INTRO
var current_text_index: int = 0
var is_typing: bool = false
var type_tween: Tween

func _ready():
	story_label.visible_ratio = 0.0
	ui_bg.modulate.a = 0.0
	next_button.modulate.a = 0.0
	
	fade_out_rect.visible = true
	fade_out_rect.modulate.a = 1.0
	fade_out_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	next_button.pressed.connect(_on_button_pressed)
	
	var target_position = rocket.position 
	rocket_base_position = target_position + Vector2(1500, 1000) 
	
	rocket.rotation_degrees = 45.0
	
	var intro_tween = create_tween().set_parallel(true)
	intro_tween.tween_property(fade_out_rect, "modulate:a", 0.0, 1.5)
	
	intro_tween.tween_property(self, "rocket_base_position", target_position, 3.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	intro_tween.tween_property(rocket, "rotation_degrees", 0.0, 3.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	intro_tween.set_parallel(false)
	
	await intro_tween.finished
	await get_tree().create_timer(text_delay).timeout
	
	var ui_tween = create_tween().set_parallel(true)
	ui_tween.tween_property(ui_bg, "modulate:a", 0.5, 0.5)
	ui_tween.tween_property(next_button, "modulate:a", 1.0, 0.5)
	await ui_tween.finished
	
	current_state = StavSceny.DIALOGUE
	show_next_dialogue()

func _process(delta):
	parallax_bg.scroll_base_offset.x += scroll_speed * delta
	
	time_passed += delta
	var offset_y = sin(time_passed * float_speed) * float_distance
	var offset_x = cos(time_passed * float_speed * 0.5) * (float_distance * 0.5)
	rocket.position = rocket_base_position + Vector2(offset_x, offset_y)

func _on_button_pressed():
	if current_state != StavSceny.DIALOGUE: 
		return
	
	if is_typing:
		type_tween.kill()
		story_label.visible_ratio = 1.0
		is_typing = false
	else:
		show_next_dialogue()

func show_next_dialogue():
	if current_text_index >= dialogue_texts.size():
		current_state = StavSceny.ENDING
		
		# ui fade
		var hide_ui_tween = create_tween().set_parallel(true)
		hide_ui_tween.tween_property(ui_bg, "modulate:a", 0.0, 1.5)
		hide_ui_tween.tween_property(story_label, "modulate:a", 0.0, 1.5)
		hide_ui_tween.tween_property(next_button, "modulate:a", 0.0, 1.5)
		hide_ui_tween.set_parallel(false)
		
		await hide_ui_tween.finished
		
		# 10s fade
		fade_out_rect.visible = true
		fade_out_rect.move_to_front()
		
		var fade_tween = create_tween()
		fade_tween.tween_property(fade_out_rect, "modulate:a", 1.0, 5.0)
		
		await fade_tween.finished
		await get_tree().create_timer(0.5).timeout
		
		if next_scene:
			get_tree().change_scene_to_packed(next_scene)
		return

	story_label.visible_ratio = 0.0
	story_label.text = dialogue_texts[current_text_index]
	
	is_typing = true
	type_tween = create_tween()
	var time_to_type = story_label.text.length() * typewriter_speed 
	type_tween.tween_property(story_label, "visible_ratio", 1.0, time_to_type)
	type_tween.finished.connect(func(): is_typing = false)
	
	current_text_index += 1
