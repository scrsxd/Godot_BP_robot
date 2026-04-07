extends Control

@export var next_scene: PackedScene
@export var level_after_progress: PackedScene
@export var scroll_speed: float = 100.0
@export var new_installed_part: String

@export_category("Dialogový Systém")
@export var text_delay: float = 1.0 
@export var typewriter_speed: float = 0.02
@export var dialogue_texts: Array[String] = []

@export_category("Příběhová Animace")
@export var use_cutscene_animation: bool = false 
@export var trigger_animation_after_index: int = 1 
@export var animation_name: String = "rocket"

@onready var next_button = $NextButton
@onready var story_label = $Label
@onready var ui_bg = $NinePatchRect2
@onready var fade_out_rect = $FadeOutRect
@onready var parallax_bg = $ParallaxBackground

var current_text_index: int = 0
var is_typing: bool = false
var type_tween: Tween
var is_transitioning: bool = false
var bezi_animace: bool = false 

func _ready():
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
	ui_tween.tween_property(ui_bg, "modulate:a", 0.9, 0.5)
	ui_tween.tween_property(next_button, "modulate:a", 1.0, 0.5)
	await ui_tween.finished
	
	show_next_dialogue()

func _on_button_pressed():
	if is_transitioning or bezi_animace: 
		return
	
	if is_typing:
		type_tween.kill()
		story_label.visible_ratio = 1.0
		is_typing = false
	else:
		if use_cutscene_animation and current_text_index == trigger_animation_after_index:
			play_cutscene_animation()
		else:
			show_next_dialogue()

func play_cutscene_animation():
	bezi_animace = true
	
	var hide_tween = create_tween().set_parallel(true)
	hide_tween.tween_property(ui_bg, "modulate:a", 0.0, 0.3)
	hide_tween.tween_property(story_label, "modulate:a", 0.0, 0.3)
	hide_tween.tween_property(next_button, "modulate:a", 0.0, 0.3)
	await hide_tween.finished
	
	%RobotRaketa.play(animation_name)
	
	var anim_duration: float = 1.0 
	var frames = %RobotRaketa.sprite_frames
	
	if frames and frames.has_animation(animation_name):
		var frame_count = frames.get_frame_count(animation_name)
		var fps = frames.get_animation_speed(animation_name)
		if fps > 0:
			anim_duration = float(frame_count) / float(fps)
			
	await get_tree().create_timer(anim_duration).timeout
	
	%RobotRaketa.stop()
	if frames and frames.has_animation(animation_name):
		%RobotRaketa.frame = frames.get_frame_count(animation_name) - 1
	
	var show_tween = create_tween().set_parallel(true)
	show_tween.tween_property(ui_bg, "modulate:a", 0.5, 0.3)
	show_tween.tween_property(story_label, "modulate:a", 1.0, 0.3)
	show_tween.tween_property(next_button, "modulate:a", 1.0, 0.3)
	
	show_next_dialogue()
	await show_tween.finished
	
	bezi_animace = false

func show_next_dialogue():
	if new_installed_part != "":
			ProgressData.part_to_animate = new_installed_part
			
	if level_after_progress:
			ProgressData.next_level = level_after_progress

		
	if current_text_index >= dialogue_texts.size():
		is_transitioning = true
		fade_out_rect.move_to_front()
		
		var fade_tween = create_tween()
		fade_tween.tween_property(fade_out_rect, "modulate:a", 1.0, 1.5)
		await fade_tween.finished
		await get_tree().create_timer(0.5).timeout
		
		if new_installed_part != "":
			ProgressData.part_to_animate = new_installed_part
		
		
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

func _process(delta):
	parallax_bg.scroll_base_offset.x -= scroll_speed * delta
