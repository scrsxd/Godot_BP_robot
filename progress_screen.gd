extends Control

@export var next_scene: PackedScene

@onready var antenna_icon = $HBoxContainer/Control
@onready var jet_icon = $HBoxContainer/JetReference
@onready var engine_icon = $HBoxContainer/EngineReference
@onready var next_button = $NextButton

func _ready():
	antenna_icon.modulate = Color(0, 0, 0, 1)
	jet_icon.modulate = Color(0, 0, 0, 1)
	engine_icon.modulate = Color(0, 0, 0, 1)
	
	if ProgressData.has_antenna:
		antenna_icon.modulate = Color.WHITE
	if ProgressData.has_jet:
		jet_icon.modulate = Color.WHITE
	if ProgressData.has_engine:
		engine_icon.modulate = Color.WHITE
		

	if ProgressData.part_to_animate != "":
		animate_new_part(ProgressData.part_to_animate)
		ProgressData.part_to_animate = "" 
		
	next_button.pressed.connect(_on_next_pressed)

func animate_new_part(part_name: String):
	var icon_to_pop: Control = null
	
	if part_name == "antenna":
		icon_to_pop = antenna_icon
		ProgressData.has_antenna = true
	elif part_name == "jet":
		icon_to_pop = jet_icon
		ProgressData.has_jet = true
	elif part_name == "engine":
		icon_to_pop = engine_icon
		ProgressData.has_engine = true
		
	if icon_to_pop:
		icon_to_pop.rotation_degrees = 0.0
		
		var color_tween = create_tween()
		color_tween.tween_property(icon_to_pop, "modulate", Color.WHITE, 0.3)
		
		var pop_tween = create_tween().set_parallel(true)
		

		pop_tween.tween_property(icon_to_pop, "scale", Vector2(2, 2), 0.4) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_OUT)
			
		pop_tween.tween_property(icon_to_pop, "scale", Vector2(1.0, 1.0), 0.4) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT) \
			.set_delay(0.4)
			
		pop_tween.tween_property(icon_to_pop, "rotation_degrees", 360.0, 0.8) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_IN_OUT)

func _on_next_pressed():
	if ProgressData.next_level:
		get_tree().change_scene_to_packed(ProgressData.next_level)
