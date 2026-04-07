extends Control

@export var next_scene: PackedScene 
@export var scroll_speed: float = 100.0
@export var float_speed: float = 2.0
@export var float_distance: float = 20.0

@export_category("Dialogový Systém")
@export var text_delay: float = 2.0 
@export var typewriter_speed: float = 0.02
@export var dialogue_texts: Array[String] = [] 
@export var error_trigger_index: int = 1 

@onready var next_button = $NextButton
@onready var parallax_bg = $ParallaxBackground
@onready var rocket = $RobotRaketa
@onready var rocket_animation = $RobotRaketa/AnimatedSprite2D
@onready var ui_bg = $NinePatchRect
@onready var story_label = $Label
@onready var fade_out_rect = $FadeOutRect
@onready var error_label = $ErrorLabel 
@onready var part1 = $Part1
@onready var part2 = $Part2
@onready var part3 = $Part3

@onready var error_base_pos: Vector2 = error_label.position

enum StavSceny { INTRO, DIALOGUE, CRASHING, POST_CRASH, ENDING }

var time_passed: float = 0.0
var rocket_base_position: Vector2
var current_state = StavSceny.INTRO
var current_text_index: int = 0
var is_typing: bool = false
var type_tween: Tween

func _ready():
	if rocket_animation:
		rocket_animation.play("default")
		
	story_label.visible_ratio = 0.0
	ui_bg.modulate.a = 0.0
	next_button.modulate.a = 0.0
	error_label.visible = false
	
	fade_out_rect.visible = true
	fade_out_rect.modulate.a = 1.0
	fade_out_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	next_button.pressed.connect(_on_button_pressed)
	
	var target_position = rocket.position 
	rocket_base_position = target_position + Vector2(1200, 0) 
	
	var intro_tween = create_tween()
	intro_tween.set_parallel(true)
	intro_tween.tween_property(fade_out_rect, "modulate:a", 0.0, 1.5)
	intro_tween.tween_property(self, "rocket_base_position", target_position, 2.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	intro_tween.set_parallel(false)
	
	await get_tree().create_timer(text_delay).timeout
	
	var ui_tween = create_tween()
	ui_tween.set_parallel(true)
	ui_tween.tween_property(ui_bg, "modulate:a", 0.9, 0.5)
	ui_tween.tween_property(next_button, "modulate:a", 1.0, 0.5)
	await ui_tween.finished
	
	current_state = StavSceny.DIALOGUE
	show_next_dialogue()

func _process(delta):
	# levitace lodi (sinusoida)
	if current_state == StavSceny.INTRO or current_state == StavSceny.DIALOGUE:
		parallax_bg.scroll_base_offset.x -= scroll_speed * delta
		
		time_passed += delta
		var offset_y = sin(time_passed * float_speed) * float_distance
		var offset_x = cos(time_passed * float_speed * 0.5) * (float_distance * 0.5)
		rocket.position = rocket_base_position + Vector2(offset_x, offset_y)
	
	# cerveny napis twitch
	if error_label.visible and current_state == StavSceny.DIALOGUE:
		error_label.position = error_base_pos + Vector2(randf_range(-2.5, 2.5), randf_range(-2.5, 2.5))

func _on_button_pressed():
	match current_state:
		StavSceny.DIALOGUE:
			if is_typing:
				type_tween.kill()
				story_label.visible_ratio = 1.0
				is_typing = false
			else:
				show_next_dialogue()
				
		StavSceny.POST_CRASH:
			current_state = StavSceny.ENDING
			fade_out_rect.move_to_front()
			var fade_tween = create_tween()
			fade_tween.tween_property(fade_out_rect, "modulate:a", 1.0, 1.5)
			await fade_tween.finished
			await get_tree().create_timer(0.5).timeout
			if next_scene:
				get_tree().change_scene_to_packed(next_scene)

func show_next_dialogue():
	if current_text_index >= dialogue_texts.size():
		trigger_crash()
		return

	if current_text_index == error_trigger_index:
		error_label.visible = true
		error_label.modulate = Color(1, 0, 0, 1)

	story_label.visible_ratio = 0.0
	story_label.text = dialogue_texts[current_text_index]
	
	is_typing = true
	type_tween = create_tween()
	var time_to_type = story_label.text.length() * typewriter_speed 
	type_tween.tween_property(story_label, "visible_ratio", 1.0, time_to_type)
	type_tween.finished.connect(func(): is_typing = false)
	
	current_text_index += 1

func trigger_crash():
	current_state = StavSceny.CRASHING
	
	if rocket_animation:
		rocket_animation.visible = false
	
	var hide_tween = create_tween().set_parallel(true)
	hide_tween.tween_property(ui_bg, "modulate:a", 0.0, 0.5)
	hide_tween.tween_property(story_label, "modulate:a", 0.0, 0.5)
	hide_tween.tween_property(next_button, "modulate:a", 0.0, 0.5)
	hide_tween.tween_property(error_label, "modulate:a", 0.0, 0.5)
	
	# animace padu
	var fall_tween = create_tween().set_parallel(true)
	fall_tween.tween_property(rocket, "position:x", rocket.position.x - 400, 2.0)\
		.set_trans(Tween.TRANS_LINEAR)
	fall_tween.tween_property(rocket, "position:y", rocket.position.y + 1200, 2.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall_tween.tween_property(rocket, "rotation_degrees", -60.0, 2.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await fall_tween.finished
	
	fade_out_rect.color = Color(1, 1, 1, 1) 
	fade_out_rect.modulate.a = 1.0 
	fade_out_rect.move_to_front()
	
	var flash_tween = create_tween()
	flash_tween.tween_property(fade_out_rect, "modulate:a", 0.0, 0.5) 
	flash_tween.tween_callback(func(): fade_out_rect.color = Color(0, 0, 0, 1))
	
	var base_y = parallax_bg.scroll_base_offset.y
	var shake_tween = create_tween()
	shake_tween.tween_property(parallax_bg, "scroll_base_offset:y", base_y + 60, 0.1)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	shake_tween.tween_property(parallax_bg, "scroll_base_offset:y", base_y, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	
	# pozice animace soucastek
	var parts = [part1, part2, part3]
	var directions = [
		Vector2(-400, -1200),
		Vector2(100, -1400), 
		Vector2(600, -1200) 
	]
	
	for i in range(3):
		parts[i].visible = true
		parts[i].position = rocket.position 
		
		var p_tween = create_tween()
		p_tween.tween_property(parts[i], "position", rocket.position + directions[i], 1)\
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		p_tween.tween_property(parts[i], "position:y", rocket.position.y + 2000, 2.5)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			
		var rot_tween = create_tween()
		rot_tween.tween_property(parts[i], "rotation_degrees", randf_range(-1080.0, 1080.0), 3.7)
	
	await get_tree().create_timer(4.0).timeout
	
	current_state = StavSceny.POST_CRASH
	var final_tween = create_tween()
	final_tween.tween_property(next_button, "modulate:a", 1.0, 0.5)
