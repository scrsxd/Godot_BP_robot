extends Area2D

var finalni_energie: int = 10

func _ready():
	# nastaveni energie metadaty
	if has_meta("energy"):
		finalni_energie = get_meta("energy")
	
	# smazani labelu pokud tam uz je
	if has_node("Label"):
		get_node("Label").queue_free()
		await get_tree().process_frame 
	
	var text_label = Label.new()
	text_label.name = "Label"
	add_child(text_label)
	
	text_label.custom_minimum_size = Vector2(64, 64)
	text_label.position = Vector2.ZERO
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var label_style = LabelSettings.new()
	label_style.font_size = 35
	label_style.outline_size = 13
	label_style.outline_color = Color.BLACK
	text_label.label_settings = label_style
	
	text_label.text = str(finalni_energie)
