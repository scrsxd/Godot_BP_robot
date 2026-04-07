extends Control

@export var next_scene: PackedScene 
@export var scroll_speed: float = 100.0
@export var float_speed: float = 2.0
@export var float_distance: float = 20.0

@onready var next_button = $NextButton
@onready var parallax_bg = $ParallaxBackground
@onready var rocket = $RobotRaketa
@onready var rocket_animation = $RobotRaketa/AnimatedSprite2D
@onready var ui = $NinePatchRect2
@onready var label = $NinePatchRect2/Label
@onready var fade_out_rect = $FadeOutRect 

var time_passed: float = 0.0
var rocket_start_position: Vector2
var is_transitioning: bool = false 

func _ready():
	rocket_start_position = rocket.position
	
	if rocket_animation:
		rocket_animation.play("default") 
		
	if fade_out_rect:
		fade_out_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	next_button.pressed.connect(_on_button_pressed)


func _process(delta):
	parallax_bg.scroll_base_offset.x -= scroll_speed * delta
	# float effect (sinusoida)
	time_passed += delta
	var offset_y = sin(time_passed * float_speed) * float_distance
	var offset_x = cos(time_passed * float_speed * 0.5) * (float_distance * 0.5)
	
	rocket.position = rocket_start_position + Vector2(offset_x, offset_y)

# animace, hide ui, pohyb, fade

func _on_button_pressed():
	if is_transitioning: 
		return
	is_transitioning = true
	
	var tween = create_tween()
	
	tween.set_parallel(true)
	tween.tween_property(ui, "modulate:a", 0.0, 0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_property(next_button, "modulate:a", 0.0, 0.5)
	tween.set_parallel(false)
	
	tween.tween_interval(0.2)
	
	tween.tween_property(self, "rocket_start_position:x", rocket_start_position.x - 1500, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	await tween.finished
	
	fade_out_rect.visible = true 
	fade_out_rect.move_to_front() 
	
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_out_rect, "modulate:a", 1.0, 0.5)
	
	await fade_tween.finished
	await get_tree().create_timer(0.35).timeout
	
	if next_scene:
		get_tree().change_scene_to_packed(next_scene)
