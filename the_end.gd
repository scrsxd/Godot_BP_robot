extends Control

@onready var restart_button = $VBoxContainer/Button

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed():
	# reset pameti pro pripad dalsiho runu
	Global.is_restarting = false
	
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
