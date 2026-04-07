extends Control

@export_group("Difficulty Settings")
@export var show_number_labels: bool = true
@export var show_current_sum: bool = true
@export var turn_limit: int = 0
@export var fixed_target_number: int = 0
@export var bottom_target_number: int = 0
@export var top_target_number: int = 0
@export var randomize_on_loss: bool = false

@export_group("Level Linking")
@export var next_level_scene: PackedScene 
@export var popup_ui: Control

@export_group("Popup text")
@export var intro_title: String = ""
@export_multiline var intro_desc: String = ""
@export var intro_btn: String = "Start"
@export var win_title: String = "Výborně!"
@export_multiline var win_text: String = ""
@export var win_button_text: String = ""
@export var lose_title: String = ""
@export_multiline var lose_text: String = ""
@export var lose_button_text: String = "Zkusit znovu"

@onready var target_label = %TargetLabel
@onready var current_label = %CurrentLabel
@onready var button_row = %ButtonRow
@onready var number_labels_row = %NumberLabelsRow
@onready var submit_button = %SubmitButton

var target_number: int = 0
var current_sum: int = 0
var zbyvajici_tahy: int = 0

func _ready():
	randomize()
	
	if not show_number_labels:
		number_labels_row.visible = false
		
	if not show_current_sum:
		current_label.visible = false
	
	generate_puzzle()
	
	for button in button_row.get_children():
		if button is Button:
			button.toggled.connect(_on_button_toggled)
			
	submit_button.pressed.connect(_on_submit_pressed)
			
	popup_ui.show_message(intro_title, intro_desc, intro_btn)
	await popup_ui.popup_closed
	
func generate_puzzle(keep_current_number: bool = false):
	if not keep_current_number:
		if fixed_target_number > 0:
			target_number = fixed_target_number
		else:
			target_number = randi_range(bottom_target_number, top_target_number)
	
	target_label.text = "Kód: " + str(target_number)
	target_label.modulate = Color.WHITE
	
	zbyvajici_tahy = turn_limit
	update_ui_texts()
	
	submit_button.disabled = false
	
	for button in button_row.get_children():
		if button is Button:
			button.set_pressed_no_signal(false) 
			button.disabled = false
			
	calculate_sum()

func _on_button_toggled(_is_pressed: bool):
	calculate_sum()

func calculate_sum():
	current_sum = 0
	var all_buttons = button_row.get_children()
	
	for i in range(all_buttons.size()):
		var btn = all_buttons[i]
		if btn is Button and btn.button_pressed:
			current_sum += int(pow(2, i))
	
	update_ui_texts()
	
	if current_sum > target_number:
		current_label.modulate = Color.RED 
	else:
		current_label.modulate = Color.WHITE

func _on_submit_pressed():
	if current_sum == target_number:
		win_game()
	else:
		if turn_limit > 0:
			zbyvajici_tahy -= 1
			update_ui_texts()
			
			if zbyvajici_tahy <= 0:
				game_over()
			else:
				popup_ui.show_message("Chyba", "Špatný kód! Zbývá pokusů: " + str(zbyvajici_tahy), "Pokračovat")
		else:
			game_over()

func update_ui_texts():
	if show_current_sum:
		current_label.text = "Zmáčknuto: " + str(current_sum)
	else:
		current_label.text = "Zmáčknuto: ???"

	if turn_limit > 0:
		target_label.text = "Kód: " + str(target_number) + "\n(Zbývá pokusů: " + str(zbyvajici_tahy) + ")"
	else:
		target_label.text = "Kód: " + str(target_number)


func win_game():
	target_label.text = "Přístup schválen."
	target_label.modulate = Color.GREEN
	submit_button.disabled = true
	
	for button in button_row.get_children():
		if button is Button:
			button.disabled = true
			
	popup_ui.show_message(win_title, win_text, win_button_text)
	await popup_ui.popup_closed
	
	if next_level_scene != null:
		get_tree().change_scene_to_packed(next_level_scene)

func game_over():
	submit_button.disabled = true
	for button in button_row.get_children():
		if button is Button:
			button.disabled = true
			
	popup_ui.show_message(lose_title, lose_text, lose_button_text, true)
	await popup_ui.popup_closed

	if randomize_on_loss:
		generate_puzzle(false)
	else:
		generate_puzzle(true)
