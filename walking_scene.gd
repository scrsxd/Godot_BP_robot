extends Control

@export var scroll_speed: float = 100.0
@export var next_scene: PackedScene

@onready var parallax_bg = $ParallaxBackground
@onready var fade_rect = $ColorRect 
@onready var story_label = $Label

func _ready():
	var tween_robot = create_tween()
	tween_robot.tween_property(%Robot, "position", Vector2(1000, 664), 20.0)
	
	var tween_rect = create_tween()
	tween_rect.tween_property(fade_rect, "modulate:a", 0.0, 3.0)
	
	story_label.visible_ratio = 0.0
	start_typewriter()
	
	await get_tree().create_timer(5.0).timeout
	go_to_next_scene()

func start_typewriter():
	var tween = create_tween()
	var time_to_type = story_label.text.length() * 0.035 
	tween.tween_property(story_label, "visible_ratio", 1.0, time_to_type)

func _process(delta):
	parallax_bg.scroll_base_offset.x -= scroll_speed * delta

func go_to_next_scene():
	var tween = create_tween()
	
	tween.tween_property(fade_rect, "modulate:a", 1.0, 3.0)
	tween.parallel().tween_property($Label, "modulate:a", 0.0, 3.0)
	
	await tween.finished
	await get_tree().create_timer(0.35).timeout
	get_tree().change_scene_to_packed(next_scene)
